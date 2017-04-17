#include "CameraSessionManager.h"

@implementation CameraSessionManager

- (CameraSessionManager *)init {
  if (self = [super init]) {
    // Create the AVCaptureSession
    self.session = [[AVCaptureSession alloc] init];
    self.sessionQueue = dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL);
    if ([self.session canSetSessionPreset:AVCaptureSessionPresetPhoto]) {
      [self.session setSessionPreset:AVCaptureSessionPresetPhoto];
    }
    self.filterLock = [[NSLock alloc] init];
  }
  return self;
}

- (NSArray *) getDeviceFormats {
  AVCaptureDevice * videoDevice = [self cameraWithPosition: self.defaultCamera];

  return videoDevice.formats;
}

- (AVCaptureVideoOrientation) getCurrentOrientation {
  return [self getCurrentOrientation: [[UIApplication sharedApplication] statusBarOrientation]];
}

- (AVCaptureVideoOrientation) getCurrentOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
  AVCaptureVideoOrientation orientation;
  switch (toInterfaceOrientation) {
    case UIInterfaceOrientationPortraitUpsideDown:
      orientation = AVCaptureVideoOrientationPortraitUpsideDown;
      break;
    case UIInterfaceOrientationLandscapeRight:
      orientation = AVCaptureVideoOrientationLandscapeRight;
      break;
    case UIInterfaceOrientationLandscapeLeft:
      orientation = AVCaptureVideoOrientationLandscapeLeft;
      break;
    default:
        case UIInterfaceOrientationPortrait:
      orientation = AVCaptureVideoOrientationPortrait;
  }
  return orientation;
}

- (void) setupSession:(NSString *)defaultCamera {
  // If this fails, video input will just stream blank frames and the user will be notified. User only has to accept once.
  [self checkDeviceAuthorizationStatus];

  dispatch_async(self.sessionQueue, ^{
      NSError *error = nil;

      NSLog(@"defaultCamera: %@", defaultCamera);
      if ([defaultCamera isEqual: @"front"]) {
        self.defaultCamera = AVCaptureDevicePositionFront;
      } else {
        self.defaultCamera = AVCaptureDevicePositionBack;
      }

      AVCaptureDevice * videoDevice = [self cameraWithPosition: self.defaultCamera];

      if ([videoDevice hasFlash] && [videoDevice isFlashModeSupported:AVCaptureFlashModeAuto]) {
        if ([videoDevice lockForConfiguration:&error]) {
          [videoDevice setFlashMode:AVCaptureFlashModeAuto];
          [videoDevice unlockForConfiguration];
        } else {
          NSLog(@"%@", error);
        }
      }

      AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];

      if (error) {
        NSLog(@"%@", error);
      }

      if ([self.session canAddInput:videoDeviceInput]) {
        [self.session addInput:videoDeviceInput];
        self.videoDeviceInput = videoDeviceInput;
      }

      AVCaptureStillImageOutput *stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
      if ([self.session canAddOutput:stillImageOutput]) {
        [self.session addOutput:stillImageOutput];
        [stillImageOutput setOutputSettings:@{AVVideoCodecKey : AVVideoCodecJPEG}];
        self.stillImageOutput = stillImageOutput;
      }

      AVCaptureVideoDataOutput *dataOutput = [[AVCaptureVideoDataOutput alloc] init];
      if ([self.session canAddOutput:dataOutput]) {
        self.dataOutput = dataOutput;
        [dataOutput setAlwaysDiscardsLateVideoFrames:YES];
        [dataOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];

        [dataOutput setSampleBufferDelegate:self.delegate queue:self.sessionQueue];

        [self.session addOutput:dataOutput];
      }

      [self updateOrientation:[self getCurrentOrientation]];
      self.device = videoDevice;
  });
}

- (void) updateOrientation:(AVCaptureVideoOrientation)orientation {
  AVCaptureConnection *captureConnection;
  if (self.stillImageOutput != nil) {
    captureConnection = [self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
    if ([captureConnection isVideoOrientationSupported]) {
      [captureConnection setVideoOrientation:orientation];
    }
  }
  if (self.dataOutput != nil) {
    captureConnection = [self.dataOutput connectionWithMediaType:AVMediaTypeVideo];
    if ([captureConnection isVideoOrientationSupported]) {
      [captureConnection setVideoOrientation:orientation];
    }
  }
}

- (void) switchCamera {
  if (self.defaultCamera == AVCaptureDevicePositionFront) {
    self.defaultCamera = AVCaptureDevicePositionBack;
  } else {
    self.defaultCamera = AVCaptureDevicePositionFront;
  }

  dispatch_async([self sessionQueue], ^{
      NSError *error = nil;

      [self.session beginConfiguration];

      if (self.videoDeviceInput != nil) {
        [self.session removeInput:[self videoDeviceInput]];
        [self setVideoDeviceInput:nil];
      }

      AVCaptureDevice *videoDevice = nil;

      videoDevice = [self cameraWithPosition:self.defaultCamera];

      if ([videoDevice hasFlash] && [videoDevice isFlashModeSupported:self.defaultFlashMode]) {
        if ([videoDevice lockForConfiguration:&error]) {
          [videoDevice setFlashMode:self.defaultFlashMode];
          [videoDevice unlockForConfiguration];
        } else {
          NSLog(@"%@", error);
        }
      }

      AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];

      if (error) {
        NSLog(@"%@", error);
      }

      if ([self.session canAddInput:videoDeviceInput]) {
        [self.session addInput:videoDeviceInput];
        [self setVideoDeviceInput:videoDeviceInput];
      }

      [self updateOrientation:[self getCurrentOrientation]];
      [self.session commitConfiguration];
      self.device = videoDevice;
  });
}

- (NSArray *)getFlashModes {

  NSString *errMsg;

  // check session is started
  if (self.session) {
  //  AVCaptureDevice * videoDevice = [self cameraWithPosition: self.defaultCamera];
    if ([self.device hasFlash]) {
      NSMutableArray * flashModes = [[NSMutableArray alloc] init];
      if ([self.device isFlashModeSupported:0]) {
        [flashModes addObject:@"off"];
      };
      if ([self.device isFlashModeSupported:1]) {
        [flashModes addObject:@"on"];
      };
      if ([self.device isFlashModeSupported:2]) {
        [flashModes addObject:@"auto"];
      };
      if ([self.device hasTorch]) {
        [flashModes addObject:@"torch"];
      };
      return (NSArray *) flashModes;
    } else {
      errMsg = @"Flash not supported";
    }
  } else {
    errMsg = @"Session is not started";
  }

  if (errMsg) {
    NSLog(@"%@", errMsg);
  }
}

- (void)setFlashMode:(NSInteger)flashMode {
  NSError *error = nil;
  NSString *errMsg;

  // check session is started
  if (self.session) {
    // Let's save the setting even if we can't set it up on this camera.
    self.defaultFlashMode = flashMode;

    if ([self.device hasFlash] && [self.device isFlashModeSupported:self.defaultFlashMode]) {

      if ([self.device lockForConfiguration:&error]) {
        if ([self.device hasTorch] && [self.device isTorchAvailable]) {
          self.device.torchMode=0;
        }
        [self.device setFlashMode:self.defaultFlashMode];
        [self.device unlockForConfiguration];

      } else {
          NSLog(@"%@", error);
      }
    } else {
      errMsg = @"Camera has no flash or flash mode not supported";
    }
  } else {
    errMsg = @"Session is not started";
  }

  if (errMsg) {
    NSLog(@"%@", errMsg);
  }
}

- (void)setTorchMode {
  NSError *error = nil;
  NSString *errMsg;

  // check session is started
  if (self.session) {
    // Let's save the setting even if we can't set it up on this camera.
    //self.defaultFlashMode = flashMode;

    if ([self.device hasTorch] && [self.device isTorchAvailable]) {

      if ([self.device lockForConfiguration:&error]) {

        if ([self.device isTorchModeSupported:1]) {
          self.device.torchMode=1;  
        } else if ([self.device isTorchModeSupported:2]) {
          self.device.torchMode=2;
        } else {
          self.device.torchMode=0;
        }
        [self.device unlockForConfiguration];
      } else {
          NSLog(@"%@", error);
      }
    } else {
      errMsg = @"Camera has no flash or flash mode not supported";
    }
  } else {
    errMsg = @"Session is not started";
  }

  if (errMsg) {
    NSLog(@"%@", errMsg);
  }
}

- (void)setZoom:(CGFloat)desiredZoomFactor {

  NSString *errMsg;

  // check session is started
  if (self.session) {
    [self.device lockForConfiguration:nil];
    self.videoZoomFactor = MAX(1.0, MIN(desiredZoomFactor, self.device.activeFormat.videoMaxZoomFactor));

    [self.device setVideoZoomFactor:self.videoZoomFactor];
    [self.device unlockForConfiguration];
    NSLog(@"%zd zoom factor set", self.videoZoomFactor);
  } else {
    errMsg = @"Session is not started";
  }

  if (errMsg) {
    NSLog(@"%@", errMsg);
  }
}

- (CGFloat)getZoom {

  NSString *errMsg;

  // check session is started
    
  if (self.session) {
    AVCaptureDevice * videoDevice = [self cameraWithPosition: self.defaultCamera];
    return videoDevice.videoZoomFactor;
  } else {
    errMsg = @"Session is not started";
  }

  if (errMsg) {
    NSLog(@"%@", errMsg);
    return 0;
  }
}

- (CGFloat)getMaxZoom {

  NSString *errMsg;

  // check session is started

  if (self.session) {
    AVCaptureDevice * videoDevice = [self cameraWithPosition: self.defaultCamera];
    return videoDevice.activeFormat.videoMaxZoomFactor;
  } else {
    errMsg = @"Session is not started";
  }

  if (errMsg) {
    NSLog(@"%@", errMsg);
    return 0;
  }
}

- (NSArray *)getExposureModes {

  NSString *errMsg;

  // check session is started
  if (self.session) {
    AVCaptureDevice * videoDevice = [self cameraWithPosition: self.defaultCamera];
    NSMutableArray *exposureModes = [[NSMutableArray alloc] init];
    if ([videoDevice isExposureModeSupported:0]) {
      [exposureModes addObject:@"lock"];
    };
    if ([videoDevice isExposureModeSupported:1]) {
      [exposureModes addObject:@"auto"];
    };
    if ([videoDevice isExposureModeSupported:2]) {
      [exposureModes addObject:@"cotinuous"];
    };
    if ([videoDevice isExposureModeSupported:3]) {
      [exposureModes addObject:@"custom"];
    };
    NSLog(@"%@", exposureModes);
    return (NSArray *) exposureModes;
  } else {
    errMsg = @"Session is not started";
  }

  if (errMsg) {
    NSLog(@"%@", errMsg);
  }
}

- (NSString *) getExposureMode {

  NSString *errMsg;
  NSString *exposureMode;

  // check session is started 
  if (self.session) {
    AVCaptureDevice * videoDevice = [self cameraWithPosition: self.defaultCamera];
    switch (videoDevice.exposureMode) {
      case 0:
          exposureMode = @"lock";
        break;
      case 1:
        exposureMode = @"auto";
        break;
      case 2:
        exposureMode = @"continuous";
        break;  
      case 3:
        exposureMode = @"custom";
        break;
      default:
        exposureMode = @"unsupported";
        errMsg = @"Mode not supported";
    }
    return exposureMode;
  } else {
    errMsg = @"Session is not started";
  }
  if (errMsg) {
    NSLog(@"%@", errMsg);
  }
}

- (NSString *) setExposureMode:(NSString *)exposureMode {

  NSString *errMsg;

  // check session is started
  if (self.session) {
    AVCaptureDevice * videoDevice = [self cameraWithPosition: self.defaultCamera];
    [self.device lockForConfiguration:nil];
    if ([exposureMode isEqual:@"lock"]) {
      if ([videoDevice isExposureModeSupported:0]) {
        videoDevice.exposureMode = 0;
        return exposureMode;
      } else {
        errMsg = @"Exposure mode not supported";
        return @"ERR01";
      };
    } else if ([exposureMode isEqual:@"auto"]) {
      if ([videoDevice isExposureModeSupported:1]) {
        videoDevice.exposureMode = 1;
        return exposureMode;
    } else {
        errMsg = @"Exposure mode not supported";
        return @"ERR01";
      };
    } else if ([exposureMode isEqual:@"continuous"]) {
      if ([videoDevice isExposureModeSupported:2]) {
        videoDevice.exposureMode = 2;
        return exposureMode;
      } else {
        errMsg = @"Exposure mode not supported";
        return @"ERR01";
      };  
    } else if ([exposureMode isEqual:@"custom"]) {
      if ([videoDevice isExposureModeSupported:3]) {
        videoDevice.exposureMode = 3;
        return exposureMode;
      } else {
        errMsg = @"Exposure mode not supported";
        return @"ERR01";
      };
    } else {
        errMsg = @"Exposure mode not supported";
        return @"ERR01";
    } 
    [self.device unlockForConfiguration];
  } else {
    errMsg = @"Session is not started";
    return @"ERR02";
  }
  if (errMsg) {
    NSLog(@"%@", errMsg);
  }
}

- (NSArray *)getExposureCompensationRange {

  NSString *errMsg;

  // check session is started
    
  if (self.session) {
    AVCaptureDevice * videoDevice = [self cameraWithPosition: self.defaultCamera];
    CGFloat maxExposureCompensation = videoDevice.maxExposureTargetBias;
    CGFloat minExposureCompensation = videoDevice.minExposureTargetBias;
    NSArray * exposureCompensationRange = [[NSArray alloc] initWithObjects: [NSNumber numberWithFloat:minExposureCompensation], [NSNumber numberWithFloat:maxExposureCompensation], nil];
    return exposureCompensationRange;
  } else {
    errMsg = @"Session is not started";
  }

  if (errMsg) {
    NSLog(@"%@", errMsg);
    return 0;
  }
}

- (CGFloat)getExposureCompensation {

  NSString *errMsg;

  // check session is started

  if (self.session) {
    AVCaptureDevice * videoDevice = [self cameraWithPosition: self.defaultCamera];
    NSLog(@"getExposureCompensation: %zd", videoDevice.exposureTargetBias);
    return videoDevice.exposureTargetBias;
  } else {
    errMsg = @"Session is not started";
  }

  if (errMsg) {
    NSLog(@"%@", errMsg);
    return 0;
  }
}

- (void)setExposureCompensation:(CGFloat)exposureCompensation {
  NSError *error = nil;
  NSString *errMsg;

  // check session is started

  if (self.session) {
    if ([self.device lockForConfiguration:&error]) {
      CGFloat exposureTargetBias = MAX(self.device.minExposureTargetBias, MIN(exposureCompensation, self.device.maxExposureTargetBias));
      [self.device setExposureTargetBias:exposureTargetBias completionHandler:nil];
      [self.device unlockForConfiguration];
    } else {
          NSLog(@"%@", error);
    }  
  } else {
    errMsg = @"Session is not started";
  }

  if (errMsg) {
    NSLog(@"%@", errMsg);
  }
}

- (void) tapToFocus:(CGFloat)xPoint yPoint:(CGFloat)yPoint {

  NSString *errMsg;

  // check session is started
  if (self.session) {
    [self.device lockForConfiguration:nil];

    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    CGFloat screenHeight = screenRect.size.height;
    CGFloat focus_x = xPoint/screenWidth;
    CGFloat focus_y = yPoint/screenHeight;

    if ([self.device isFocusModeSupported:AVCaptureFocusModeAutoFocus]){
      [self.device setFocusPointOfInterest:CGPointMake(focus_x,focus_y)];
      [self.device setFocusMode:AVCaptureFocusModeAutoFocus];
    }
    if ([self.device isExposureModeSupported:AVCaptureExposureModeAutoExpose]){
      [self.device setExposurePointOfInterest:CGPointMake(focus_x,focus_y)];
      [self.device setExposureMode:AVCaptureExposureModeAutoExpose];
    }

    [self.device unlockForConfiguration];
  } else {
    errMsg = @"Session is not started";
  }

  if (errMsg) {
    NSLog(@"%@", errMsg);
  }
}

- (void)checkDeviceAuthorizationStatus {
  NSString *mediaType = AVMediaTypeVideo;

  [AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL granted) {
    if (!granted) {
      //Not granted access to mediaType
      dispatch_async(dispatch_get_main_queue(), ^{
          [[[UIAlertView alloc] initWithTitle:@"Error"
                                      message:@"Camera permission not found. Please, check your privacy settings."
                                     delegate:self
                            cancelButtonTitle:@"OK"
                            otherButtonTitles:nil] show];
      });
    }
  }];
}

// Find a camera with the specified AVCaptureDevicePosition, returning nil if one is not found
- (AVCaptureDevice *) cameraWithPosition:(AVCaptureDevicePosition) position {
  NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
  for (AVCaptureDevice *device in devices){
    if ([device position] == position)
      return device;
  }
  return nil;
}

@end
