#include "CameraSessionManager.h"

@implementation CameraSessionManager

- (CameraSessionManager *)init
{
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
- (AVCaptureVideoOrientation) getCurrentOrientation/*:(UIInterfaceOrientation)toInterfaceOrientation*/
{
  return [self getCurrentOrientation: [[UIApplication sharedApplication] statusBarOrientation]];
}
- (AVCaptureVideoOrientation) getCurrentOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
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
- (void) setupSession:(NSString *)defaultCamera
{
  // If this fails, video input will just stream blank frames
  // and the user will be notified. User only has to accep once.
  [self checkDeviceAuthorizationStatus];

  dispatch_async(self.sessionQueue, ^{
      NSError *error = nil;

      NSLog(@"defaultCamera: %@", defaultCamera);
      if ([defaultCamera isEqual: @"front"]) {
      self.defaultCamera = AVCaptureDevicePositionFront;
      } else {
      self.defaultCamera = AVCaptureDevicePositionBack;
      }

      self.defaultFlashMode = AVCaptureFlashModeAuto;

      self.device = [self cameraWithPosition:self.defaultCamera];

      if ([self.device hasFlash] && [self.device isFlashModeSupported:self.defaultFlashMode]) {
                                if ([self.device lockForConfiguration:&error]) {
                                            [self.device setFlashMode:self.defaultFlashMode];
                                            [self.device unlockForConfiguration];
                                            } else {
                                            NSLog(@"%@", error);
                                            }
      }

      AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:&error];

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
  });
}

- (void) updateOrientation:(AVCaptureVideoOrientation)orientation
{
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

- (void) switchCamera
{
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

- (void)setFlashMode:(NSInteger)flashMode
{

  NSString *errMsg;

  // check session is started
  if (self.session)
  {
    if ([self.device hasFlash])
    {
      [self.device lockForConfiguration:nil];
      if (flashMode == AVCaptureFlashModeOn)
      {
        self.defaultFlashMode = AVCaptureFlashModeOn;
      }
      else if (flashMode == AVCaptureFlashModeOff)
      {
        self.defaultFlashMode = AVCaptureFlashModeOff;
      }
      else if (flashMode == AVCaptureFlashModeAuto)
      {
        self.defaultFlashMode = AVCaptureFlashModeAuto;
      }
      [self.device setFlashMode:self.defaultFlashMode];
      [self.device unlockForConfiguration];
      NSLog(@"%zd hey", self.defaultFlashMode);
    }
    else
    {
      errMsg = @"This device has no flash or torch";
    }
  }
  else
  {
    errMsg = @"Session is not started";
  }

  if (errMsg) {
    NSLog(@"%@", errMsg);
  }
}

- (void)checkDeviceAuthorizationStatus
{
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
- (AVCaptureDevice *) cameraWithPosition:(AVCaptureDevicePosition) position
{
  NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
  for (AVCaptureDevice *device in devices)
  {
    if ([device position] == position)
      return device;
  }
  return nil;
}

@end
