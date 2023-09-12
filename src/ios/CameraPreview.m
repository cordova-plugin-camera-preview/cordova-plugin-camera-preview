#import <Cordova/CDV.h>
#import <Cordova/CDVPlugin.h>
#import <Cordova/CDVInvokedUrlCommand.h>
#import <GLKit/GLKit.h>
#import "CameraPreview.h"

#define TMP_IMAGE_PREFIX @"cpcp_capture_"

@implementation CameraPreview

-(void) pluginInitialize{
  // start as transparent
  self.webView.opaque = NO;
  self.webView.backgroundColor = [UIColor clearColor];
}

- (void) startCamera:(CDVInvokedUrlCommand*)command {

  CDVPluginResult *pluginResult;
  self.startCameraInProgress = true;

  if (self.sessionManager != nil) {
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Camera already started!"];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    return;
  }

  if (command.arguments.count > 3) {
    CGFloat x = (CGFloat)[command.arguments[0] floatValue] + self.webView.frame.origin.x;
    CGFloat y = (CGFloat)[command.arguments[1] floatValue] + self.webView.frame.origin.y;
    CGFloat width = (CGFloat)[command.arguments[2] floatValue];
    CGFloat height = (CGFloat)[command.arguments[3] floatValue];
    NSString *defaultCamera = command.arguments[4];
    BOOL tapToTakePicture = (BOOL)[command.arguments[5] boolValue];
    BOOL dragEnabled = (BOOL)[command.arguments[6] boolValue];
    BOOL toBack = (BOOL)[command.arguments[7] boolValue];
    CGFloat alpha = (CGFloat)[command.arguments[8] floatValue];
    BOOL tapToFocus = (BOOL)[command.arguments[9] boolValue];
    BOOL disableExifHeaderStripping = (BOOL)[command.arguments[10] boolValue]; // ignore Android only
    self.storeToFile = (BOOL)[command.arguments[11] boolValue];
    self.storageDirectory = command.arguments[12];

    // Create the session manager
    self.sessionManager = [[CameraSessionManager alloc] init];

    // render controller setup
    self.cameraRenderController = [[CameraRenderController alloc] init];
    self.cameraRenderController.dragEnabled = dragEnabled;
    self.cameraRenderController.tapToTakePicture = tapToTakePicture;
    self.cameraRenderController.tapToFocus = tapToFocus;
    self.cameraRenderController.disableExifHeaderStripping = disableExifHeaderStripping;
    self.cameraRenderController.sessionManager = self.sessionManager;
    self.cameraRenderController.view.frame = CGRectMake(x, y, width, height);
    self.cameraRenderController.delegate = self;

    [self.viewController addChildViewController:self.cameraRenderController];

    if (toBack) {
      // display the camera below the webview

      // make transparent
      self.webView.opaque = NO;
      self.webView.backgroundColor = [UIColor clearColor];

      [self.webView.superview addSubview:self.cameraRenderController.view];
      [self.webView.superview bringSubviewToFront:self.webView];
    } else {
      self.cameraRenderController.view.alpha = alpha;
      [self.webView.superview insertSubview:self.cameraRenderController.view aboveSubview:self.webView];
    }

    // Setup session
    self.sessionManager.delegate = self.cameraRenderController;

    [self.sessionManager setupSession:defaultCamera completion:^(BOOL started) {
        
        self.startCameraInProgress = false;
      [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];

    }];

  } else {
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Invalid number of parameters"];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
  }
}

- (void) stopCamera:(CDVInvokedUrlCommand*)command {
    NSLog(@"stopCamera");
    CDVPluginResult *pluginResult;

    if(self.sessionManager != nil) {
        [self.cameraRenderController.view removeFromSuperview];
        [self.cameraRenderController removeFromParentViewController];

        self.cameraRenderController = nil;
        self.sessionManager = nil;
        
        if(self.startCameraInProgress == false) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"startCamera in progress"];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            return;
        }

        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    }
    else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Camera not started"];
    }

    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) hideCamera:(CDVInvokedUrlCommand*)command {
  NSLog(@"hideCamera");
  CDVPluginResult *pluginResult;

  if (self.cameraRenderController != nil) {
    [self.cameraRenderController.view setHidden:YES];
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
  } else {
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Camera not started"];
  }

  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) showCamera:(CDVInvokedUrlCommand*)command {
  NSLog(@"showCamera");
  CDVPluginResult *pluginResult;

  if (self.cameraRenderController != nil) {
    [self.cameraRenderController.view setHidden:NO];
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
  } else {
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Camera not started"];
  }

  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) switchCamera:(CDVInvokedUrlCommand*)command {
  NSLog(@"switchCamera");
  CDVPluginResult *pluginResult;

  if (self.sessionManager != nil) {
    [self.sessionManager switchCamera:^(BOOL switched) {

      [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];

    }];

  } else {

    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Session not started"];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
  }
}

- (void) getSupportedFocusModes:(CDVInvokedUrlCommand*)command {
  CDVPluginResult *pluginResult;

  if (self.sessionManager != nil) {
    NSArray * focusModes = [self.sessionManager getFocusModes];
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:focusModes];
  } else {
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Session not started"];
  }

  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) getFocusMode:(CDVInvokedUrlCommand*)command {
  CDVPluginResult *pluginResult;

  if (self.sessionManager != nil) {
    NSString * focusMode = [self.sessionManager getFocusMode];
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:focusMode];
  } else {
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Session not started"];
  }

  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) setFocusMode:(CDVInvokedUrlCommand*)command {
  CDVPluginResult *pluginResult;

  NSString * focusMode = [command.arguments objectAtIndex:0];
  if (self.sessionManager != nil) {
    [self.sessionManager setFocusMode:focusMode];
    NSString * focusMode = [self.sessionManager getFocusMode];
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:focusMode ];
  } else {
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Session not started"];
  }
  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) getSupportedFlashModes:(CDVInvokedUrlCommand*)command {
  CDVPluginResult *pluginResult;

  if (self.sessionManager != nil) {
    NSArray * flashModes = [self.sessionManager getFlashModes];
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:flashModes];
  } else {
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Session not started"];
  }

  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) getFlashMode:(CDVInvokedUrlCommand*)command {

  CDVPluginResult *pluginResult;

  if (self.sessionManager != nil) {
    BOOL isTorchActive = [self.sessionManager isTorchActive];
    NSInteger flashMode = [self.sessionManager getFlashMode];
    NSString * sFlashMode;
    if (isTorchActive) {
      sFlashMode = @"torch";
    } else {
      if (flashMode == 0) {
        sFlashMode = @"off";
      } else if (flashMode == 1) {
        sFlashMode = @"on";
      } else if (flashMode == 2) {
        sFlashMode = @"auto";
      } else {
        sFlashMode = @"unsupported";
      }
    }
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:sFlashMode ];
  } else {
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Session not started"];
  }

  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) setFlashMode:(CDVInvokedUrlCommand*)command {
  NSLog(@"Flash Mode");
  NSString *errMsg;
  CDVPluginResult *pluginResult;

  NSString *flashMode = [command.arguments objectAtIndex:0];

  if (self.sessionManager != nil) {
    if ([flashMode isEqual: @"off"]) {
      [self.sessionManager setFlashMode:AVCaptureFlashModeOff];
    } else if ([flashMode isEqual: @"on"]) {
      [self.sessionManager setFlashMode:AVCaptureFlashModeOn];
    } else if ([flashMode isEqual: @"auto"]) {
      [self.sessionManager setFlashMode:AVCaptureFlashModeAuto];
    } else if ([flashMode isEqual: @"torch"]) {
      [self.sessionManager setTorchMode];
    } else {
      errMsg = @"Flash Mode not supported";
    }
  } else {
    errMsg = @"Session not started";
  }

  if (errMsg) {
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:errMsg];
  } else {
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
  }

  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) setZoom:(CDVInvokedUrlCommand*)command {
  NSLog(@"Zoom");
  CDVPluginResult *pluginResult;

  CGFloat desiredZoomFactor = [[command.arguments objectAtIndex:0] floatValue];

  if (self.sessionManager != nil) {
    [self.sessionManager setZoom:desiredZoomFactor];
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
  } else {
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Session not started"];
  }

  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) getZoom:(CDVInvokedUrlCommand*)command {

  CDVPluginResult *pluginResult;

  if (self.sessionManager != nil) {
    CGFloat zoom = [self.sessionManager getZoom];
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDouble:zoom ];
  } else {
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Session not started"];
  }

  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) getHorizontalFOV:(CDVInvokedUrlCommand*)command {

  CDVPluginResult *pluginResult;

  if (self.sessionManager != nil) {
    float fov = [self.sessionManager getHorizontalFOV];
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDouble:fov ];
  } else {
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Session not started"];
  }

  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) getMaxZoom:(CDVInvokedUrlCommand*)command {
  CDVPluginResult *pluginResult;

  if (self.sessionManager != nil) {
    CGFloat maxZoom = [self.sessionManager getMaxZoom];
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDouble:maxZoom ];
  } else {
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Session not started"];
  }

  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) getExposureModes:(CDVInvokedUrlCommand*)command {
  CDVPluginResult *pluginResult;

  if (self.sessionManager != nil) {
    NSArray * exposureModes = [self.sessionManager getExposureModes];
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:exposureModes];
  } else {
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Session not started"];
  }

  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) getExposureMode:(CDVInvokedUrlCommand*)command {
  CDVPluginResult *pluginResult;

  if (self.sessionManager != nil) {
    NSString * exposureMode = [self.sessionManager getExposureMode];
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:exposureMode ];
  } else {
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Session not started"];
  }

  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) setExposureMode:(CDVInvokedUrlCommand*)command {
  CDVPluginResult *pluginResult;

  NSString * exposureMode = [command.arguments objectAtIndex:0];
  if (self.sessionManager != nil) {
    [self.sessionManager setExposureMode:exposureMode];
    NSString * exposureMode = [self.sessionManager getExposureMode];
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:exposureMode ];
  } else {
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Session not started"];
  }
  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) getSupportedWhiteBalanceModes:(CDVInvokedUrlCommand*)command {
  CDVPluginResult *pluginResult;

  if (self.sessionManager != nil) {
    NSArray * whiteBalanceModes = [self.sessionManager getSupportedWhiteBalanceModes];
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:whiteBalanceModes ];
  } else {
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Session not started"];
  }

  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) getWhiteBalanceMode:(CDVInvokedUrlCommand*)command {
  CDVPluginResult *pluginResult;

  if (self.sessionManager != nil) {
    NSString * whiteBalanceMode = [self.sessionManager getWhiteBalanceMode];
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:whiteBalanceMode ];
  } else {
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Session not started"];
  }

  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) setWhiteBalanceMode:(CDVInvokedUrlCommand*)command {
  CDVPluginResult *pluginResult;

  NSString * whiteBalanceMode = [command.arguments objectAtIndex:0];
  if (self.sessionManager != nil) {
    [self.sessionManager setWhiteBalanceMode:whiteBalanceMode];
    NSString * wbMode = [self.sessionManager getWhiteBalanceMode];
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:wbMode ];
  } else {
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Session not started"];
  }
  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) getExposureCompensationRange:(CDVInvokedUrlCommand*)command {
  CDVPluginResult *pluginResult;

  if (self.sessionManager != nil) {
    NSArray * exposureRange = [self.sessionManager getExposureCompensationRange];
    NSMutableDictionary *dimensions = [[NSMutableDictionary alloc] init];
    [dimensions setValue:exposureRange[0] forKey:@"min"];
    [dimensions setValue:exposureRange[1] forKey:@"max"];
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dimensions];
  } else {
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Session not started"];
  }
  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) getExposureCompensation:(CDVInvokedUrlCommand*)command {
  CDVPluginResult *pluginResult;

  if (self.sessionManager != nil) {
    CGFloat exposureCompensation = [self.sessionManager getExposureCompensation];
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDouble:exposureCompensation ];
  } else {
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Session not started"];
  }

  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) setExposureCompensation:(CDVInvokedUrlCommand*)command {
  NSLog(@"Zoom");
  CDVPluginResult *pluginResult;

  CGFloat exposureCompensation = [[command.arguments objectAtIndex:0] floatValue];

  if (self.sessionManager != nil) {
    [self.sessionManager setExposureCompensation:exposureCompensation];
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDouble:exposureCompensation];
  } else {
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Session not started"];
  }

  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) takePicture:(CDVInvokedUrlCommand*)command {
  NSLog(@"takePicture");
  CDVPluginResult *pluginResult;

  if (self.cameraRenderController != NULL) {
    self.onPictureTakenHandlerId = command.callbackId;

    CGFloat width = (CGFloat)[command.arguments[0] floatValue];
    CGFloat height = (CGFloat)[command.arguments[1] floatValue];
    CGFloat quality = (CGFloat)[command.arguments[2] floatValue] / 100.0f;
    CGFloat latitude = (CGFloat)[command.arguments[3] floatValue];
    CGFloat longitude = (CGFloat)[command.arguments[4] floatValue];
    CGFloat altitude = (CGFloat)[command.arguments[5] floatValue];
    NSTimeInterval timestamp = [command.arguments[6] doubleValue];
    CGFloat trueHeading = (CGFloat)[command.arguments[7] floatValue];
    CGFloat magneticHeading = (CGFloat)[command.arguments[8] floatValue];
    NSString *software = command.arguments[9];
      
    self.exifInfos = [NSMutableDictionary new];
      
    if(latitude){
      self.exifInfos[@"latitude"] = [NSNumber numberWithDouble:latitude];
    }
    if(longitude){
      self.exifInfos[@"longitude"] = [NSNumber numberWithDouble:longitude];
    }
    if(altitude){
      self.exifInfos[@"altitude"] = [NSNumber numberWithDouble:altitude];
    }
    if(timestamp){
      self.exifInfos[@"timestamp"] = [NSNumber numberWithDouble:timestamp];
    }
    if(trueHeading){
      self.exifInfos[@"trueHeading"] = [NSNumber numberWithDouble:trueHeading];
    }
    if(magneticHeading){
      self.exifInfos[@"magneticHeading"] = [NSNumber numberWithDouble:magneticHeading];
    }
    if(software){
      self.exifInfos[@"software"] = software;
    }
      
    [self invokeTakePicture:width withHeight:height withQuality:quality];
  } else {
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Camera not started"];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
  }
}

- (void) takeSnapshot:(CDVInvokedUrlCommand*)command {
    NSLog(@"takeSnapshot");
    CDVPluginResult *pluginResult;
    if (self.cameraRenderController != NULL && self.cameraRenderController.view != NULL) {
        CGFloat quality = (CGFloat)[command.arguments[0] floatValue] / 100.0f;
        dispatch_async(self.sessionManager.sessionQueue, ^{
            UIImage *image = ((GLKView*)self.cameraRenderController.view).snapshot;
            NSString *base64Image = [self getBase64Image:image.CGImage withQuality:quality];
            NSMutableArray *params = [[NSMutableArray alloc] init];
            [params addObject:base64Image];
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:params];
            [pluginResult setKeepCallbackAsBool:false];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        });
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Camera not started"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}


-(void) setColorEffect:(CDVInvokedUrlCommand*)command {
  NSLog(@"setColorEffect");
  CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
  NSString *filterName = command.arguments[0];

  if(self.sessionManager != nil){
    if ([filterName isEqual: @"none"]) {
      dispatch_async(self.sessionManager.sessionQueue, ^{
          [self.sessionManager setCiFilter:nil];
          });
    } else if ([filterName isEqual: @"mono"]) {
      dispatch_async(self.sessionManager.sessionQueue, ^{
          CIFilter *filter = [CIFilter filterWithName:@"CIColorMonochrome"];
          [filter setDefaults];
          [self.sessionManager setCiFilter:filter];
          });
    } else if ([filterName isEqual: @"negative"]) {
      dispatch_async(self.sessionManager.sessionQueue, ^{
          CIFilter *filter = [CIFilter filterWithName:@"CIColorInvert"];
          [filter setDefaults];
          [self.sessionManager setCiFilter:filter];
          });
    } else if ([filterName isEqual: @"posterize"]) {
      dispatch_async(self.sessionManager.sessionQueue, ^{
          CIFilter *filter = [CIFilter filterWithName:@"CIColorPosterize"];
          [filter setDefaults];
          [self.sessionManager setCiFilter:filter];
          });
    } else if ([filterName isEqual: @"sepia"]) {
      dispatch_async(self.sessionManager.sessionQueue, ^{
          CIFilter *filter = [CIFilter filterWithName:@"CISepiaTone"];
          [filter setDefaults];
          [self.sessionManager setCiFilter:filter];
          });
    } else {
      pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Filter not found"];
    }
  } else {
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Session not started"];
  }

  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) setPreviewSize: (CDVInvokedUrlCommand*)command {

    CDVPluginResult *pluginResult;

    if (self.sessionManager == nil) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Session not started"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        return;
    }

    if (command.arguments.count > 1) {
        CGFloat width = (CGFloat)[command.arguments[0] floatValue];
        CGFloat height = (CGFloat)[command.arguments[1] floatValue];

        self.cameraRenderController.view.frame = CGRectMake(0, 0, width, height);

        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Invalid number of parameters"];
    }

    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) getSupportedPictureSizes:(CDVInvokedUrlCommand*)command {
  NSLog(@"getSupportedPictureSizes");
  CDVPluginResult *pluginResult;

  if(self.sessionManager != nil){
    NSArray *formats = self.sessionManager.getDeviceFormats;
    NSMutableArray *jsonFormats = [NSMutableArray new];
    int lastWidth = 0;
    int lastHeight = 0;
    for (AVCaptureDeviceFormat *format in formats) {
      CMVideoDimensions dim = format.highResolutionStillImageDimensions;
      if (dim.width!=lastWidth && dim.height != lastHeight) {
        NSMutableDictionary *dimensions = [[NSMutableDictionary alloc] init];
        NSNumber *width = [NSNumber numberWithInt:dim.width];
        NSNumber *height = [NSNumber numberWithInt:dim.height];
        [dimensions setValue:width forKey:@"width"];
        [dimensions setValue:height forKey:@"height"];
        [jsonFormats addObject:dimensions];
        lastWidth = dim.width;
        lastHeight = dim.height;
      }
    }
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:jsonFormats];

  } else {
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Session not started"];
  }

  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (NSString *)getBase64Image:(CGImageRef)imageRef withQuality:(CGFloat) quality {
  NSString *base64Image = nil;

  @try {
    UIImage *image = [UIImage imageWithCGImage:imageRef];
    NSData *imageData = UIImageJPEGRepresentation(image, quality);
    base64Image = [imageData base64EncodedStringWithOptions:0];
  }
  @catch (NSException *exception) {
    NSLog(@"error while get base64Image: %@", [exception reason]);
  }

  return base64Image;
}

- (void) tapToFocus:(CDVInvokedUrlCommand*)command {
  NSLog(@"tapToFocus");
  CDVPluginResult *pluginResult;

  CGFloat xPoint = [[command.arguments objectAtIndex:0] floatValue];
  CGFloat yPoint = [[command.arguments objectAtIndex:1] floatValue];

  if (self.sessionManager != nil) {
    [self.sessionManager tapToFocus:xPoint yPoint:yPoint];
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
  } else {
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Session not started"];
  }

  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (double)radiansFromUIImageOrientation:(UIImageOrientation)orientation {
  double radians;

  switch ([[UIApplication sharedApplication] statusBarOrientation]) {
    case UIDeviceOrientationPortrait:
      radians = M_PI_2;
      break;
    case UIDeviceOrientationLandscapeLeft:
      radians = 0.f;
      break;
    case UIDeviceOrientationLandscapeRight:
      radians = M_PI;
      break;
    case UIDeviceOrientationPortraitUpsideDown:
      radians = -M_PI_2;
      break;
  }

  return radians;
}

-(CGImageRef) CGImageRotated:(CGImageRef) originalCGImage withRadians:(double) radians {
  CGSize imageSize = CGSizeMake(CGImageGetWidth(originalCGImage), CGImageGetHeight(originalCGImage));
  CGSize rotatedSize;
  if (radians == M_PI_2 || radians == -M_PI_2) {
    rotatedSize = CGSizeMake(imageSize.height, imageSize.width);
  } else {
    rotatedSize = imageSize;
  }

  double rotatedCenterX = rotatedSize.width / 2.f;
  double rotatedCenterY = rotatedSize.height / 2.f;

  UIGraphicsBeginImageContextWithOptions(rotatedSize, NO, 1.f);
  CGContextRef rotatedContext = UIGraphicsGetCurrentContext();
  if (radians == 0.f || radians == M_PI) { // 0 or 180 degrees
    CGContextTranslateCTM(rotatedContext, rotatedCenterX, rotatedCenterY);
    if (radians == 0.0f) {
      CGContextScaleCTM(rotatedContext, 1.f, -1.f);
    } else {
      CGContextScaleCTM(rotatedContext, -1.f, 1.f);
    }
    CGContextTranslateCTM(rotatedContext, -rotatedCenterX, -rotatedCenterY);
  } else if (radians == M_PI_2 || radians == -M_PI_2) { // +/- 90 degrees
    CGContextTranslateCTM(rotatedContext, rotatedCenterX, rotatedCenterY);
    CGContextRotateCTM(rotatedContext, radians);
    CGContextScaleCTM(rotatedContext, 1.f, -1.f);
    CGContextTranslateCTM(rotatedContext, -rotatedCenterY, -rotatedCenterX);
  }

  CGRect drawingRect = CGRectMake(0.f, 0.f, imageSize.width, imageSize.height);
  CGContextDrawImage(rotatedContext, drawingRect, originalCGImage);
  CGImageRef rotatedCGImage = CGBitmapContextCreateImage(rotatedContext);

  UIGraphicsEndImageContext();

  return rotatedCGImage;
}

- (void) invokeTapToFocus:(CGPoint)point {
  [self.sessionManager tapToFocus:point.x yPoint:point.y];
}

- (void) invokeTakePicture {
  [self invokeTakePicture:0.0 withHeight:0.0 withQuality:0.85];
}

- (void) invokeTakePictureOnFocus {
    // the sessionManager will call onFocus, as soon as the camera is done with focussing.
  [self.sessionManager takePictureOnFocus];
}

- (void) invokeTakePicture:(CGFloat) width withHeight:(CGFloat) height withQuality:(CGFloat) quality{
    AVCaptureConnection *connection = [self.sessionManager.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
    [self.sessionManager.stillImageOutput captureStillImageAsynchronouslyFromConnection:connection completionHandler:^(CMSampleBufferRef sampleBuffer, NSError *error) {

      NSLog(@"Done creating still image");

      if (error) {
        NSLog(@"%@", error);
      } else {

        NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:sampleBuffer];
        UIImage *capturedImage  = [[UIImage alloc] initWithData:imageData];

        CIImage *capturedCImage;
        //image resize

        if(width > 0 && height > 0){
          CGFloat scaleHeight = width/capturedImage.size.height;
          CGFloat scaleWidth = height/capturedImage.size.width;
          CGFloat scale = scaleHeight > scaleWidth ? scaleWidth : scaleHeight;

          CIFilter *resizeFilter = [CIFilter filterWithName:@"CILanczosScaleTransform"];
          [resizeFilter setValue:[[CIImage alloc] initWithCGImage:[capturedImage CGImage]] forKey:kCIInputImageKey];
          [resizeFilter setValue:[NSNumber numberWithFloat:1.0f] forKey:@"inputAspectRatio"];
          [resizeFilter setValue:[NSNumber numberWithFloat:scale] forKey:@"inputScale"];
          capturedCImage = [resizeFilter outputImage];
        }else{
          capturedCImage = [[CIImage alloc] initWithCGImage:[capturedImage CGImage]];
        }

        CIImage *imageToFilter;
        CIImage *finalCImage;

        //fix front mirroring
        if (self.sessionManager.defaultCamera == AVCaptureDevicePositionFront) {
          CGAffineTransform matrix = CGAffineTransformTranslate(CGAffineTransformMakeScale(1, -1), 0, capturedCImage.extent.size.height);
          imageToFilter = [capturedCImage imageByApplyingTransform:matrix];
        } else {
          imageToFilter = capturedCImage;
        }

        CIFilter *filter = [self.sessionManager ciFilter];
        if (filter != nil) {
          [self.sessionManager.filterLock lock];
          [filter setValue:imageToFilter forKey:kCIInputImageKey];
          finalCImage = [filter outputImage];
          [self.sessionManager.filterLock unlock];
        } else {
          finalCImage = imageToFilter;
        }

        CGImageRef finalImage = [self.cameraRenderController.ciContext createCGImage:finalCImage fromRect:finalCImage.extent];
        UIImage *resultImage = [UIImage imageWithCGImage:finalImage];

        double radians = [self radiansFromUIImageOrientation:resultImage.imageOrientation];
        CGImageRef resultFinalImage = [self CGImageRotated:finalImage withRadians:radians];

        CGImageRelease(finalImage); // release CGImageRef to remove memory leaks

        CDVPluginResult *pluginResult;
        if (self.storeToFile) {
          NSData *data = UIImageJPEGRepresentation([UIImage imageWithCGImage:resultFinalImage], (CGFloat) quality);
          NSString* filePath = [self getTempFilePath:@"jpg"];
          NSError *err;

          if (![data writeToFile:filePath options:NSAtomicWrite error:&err]) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_IO_EXCEPTION messageAsString:[err localizedDescription]];
          }
          else {
            CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)imageData, NULL);
            if(imageSource) {
                NSMutableDictionary *metadata = [NSMutableDictionary dictionaryWithDictionary:(__bridge NSDictionary *)CGImageSourceCopyPropertiesAtIndex(imageSource, 0, NULL)];
                NSLog(@"exif data 2 = %@", metadata[(__bridge NSString *)kCGImagePropertyExifDictionary]);
                [self writeExifInfosToMetadata:metadata];
                
                metadata[(__bridge NSString *)kCGImageDestinationLossyCompressionQuality] = @(quality);

                NSString *type = @"public.jpeg";
                NSMutableData *data = [NSMutableData data];
                CGImageDestinationRef dest = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)data, (__bridge CFStringRef)type, 1, NULL);

                CGImageRef cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
                CGImageDestinationAddImage(dest, cgImage, (__bridge CFDictionaryRef)metadata);
                CGImageDestinationFinalize(dest);

                NSError *error;
                NSURL *fileUrl;
                
                if(self.storageDirectory.length > 0){
                    NSString *filePath = [NSString stringWithFormat:@"%@%@", self.storageDirectory, [self getFileName:@"jpg"]];
                    fileUrl = [NSURL URLWithString:filePath];
                } else {
                    fileUrl = [self getFileUrl:@"jpg"];
                }

                // Write the file at path
                if (![data writeToURL:fileUrl options:NSDataWritingAtomic error:&error]) {
                    NSLog(@"We have an error to save the picture: %@", error);
                } else {
                    NSMutableDictionary *resultMedia = [NSMutableDictionary dictionary];

                    resultMedia[@"filePath"] = fileUrl.absoluteString;
                    resultMedia[@"width"] = @(CGImageGetWidth(cgImage));
                    resultMedia[@"height"] = @(CGImageGetHeight(cgImage));
                    resultMedia[@"orientation"] = metadata[(__bridge NSString *)kCGImagePropertyOrientation];

                    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:resultMedia];
                    // This means that the callback on JS side is kept for further calls from native side to JS side
                    [pluginResult setKeepCallbackAsBool:YES];
                    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.onPictureTakenHandlerId];
                }
                
                CGImageRelease(cgImage);
                CFRelease(dest);
                CFRelease(imageSource);
            }
          }
        } else {
          NSMutableArray *params = [[NSMutableArray alloc] init];
          NSString *base64Image = [self getBase64Image:resultFinalImage withQuality:quality];
          [params addObject:base64Image];
          pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:params];
        }

        CGImageRelease(resultFinalImage); // release CGImageRef to remove memory leaks

        [pluginResult setKeepCallbackAsBool:self.cameraRenderController.tapToTakePicture];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.onPictureTakenHandlerId];
      }
    }];
}

- (void)writeExifInfosToMetadata:(NSMutableDictionary *)metadata {
    NSMutableDictionary *tiff = (NSMutableDictionary *)metadata[(__bridge NSString *)kCGImagePropertyTIFFDictionary];
    tiff[(__bridge NSString *)kCGImagePropertyTIFFSoftware] = self.exifInfos[@"software"];
    
    NSMutableDictionary *gps = [NSMutableDictionary dictionary];
    metadata[(__bridge NSString *)kCGImagePropertyGPSDictionary] = gps;
    
    // Calculate north/south and east/west because we can't set negative latitude and longitude
    NSString *latitudeRef;
    NSString *longitudeRef;
    
    double latitude = [self.exifInfos[@"latitude"] doubleValue];
    double longitude = [self.exifInfos[@"longitude"] doubleValue];
    
    if (latitude < 0.0) {
        latitudeRef = @"S";
        self.exifInfos[@"latitude"] = @(fabs(latitude));
    } else {
        latitudeRef = @"N";
    }
    
    if (longitude < 0.0) {
        longitudeRef = @"W";
        self.exifInfos[@"longitude"] = @(fabs(longitude));
    } else {
        longitudeRef = @"E";
    }
    
    NSNumber *trueHeading = self.exifInfos[@"trueHeading"];
    NSNumber *magneticHeading = self.exifInfos[@"magneticHeading"];
    
    if (trueHeading != nil || magneticHeading != nil) {
        if (trueHeading == nil || [trueHeading doubleValue] < 0.0) {
            gps[(__bridge NSString *)kCGImagePropertyGPSImgDirection] = @[magneticHeading, @(1)];
            gps[(__bridge NSString *)kCGImagePropertyGPSImgDirectionRef] = @"M";
        } else {
            gps[(__bridge NSString *)kCGImagePropertyGPSImgDirection] = @[trueHeading, @(1)];
            gps[(__bridge NSString *)kCGImagePropertyGPSImgDirectionRef] = @"T";
        }
    }
    
    gps[(__bridge NSString *)kCGImagePropertyGPSLatitudeRef] = latitudeRef;
    gps[(__bridge NSString *)kCGImagePropertyGPSLongitudeRef] = longitudeRef;
    gps[(__bridge NSString *)kCGImagePropertyGPSLatitude] = self.exifInfos[@"latitude"];
    gps[(__bridge NSString *)kCGImagePropertyGPSLongitude] = self.exifInfos[@"longitude"];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"HH:mm:ss";
    gps[(__bridge NSString *)kCGImagePropertyGPSTimeStamp] = [dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:[self.exifInfos[@"timestamp"] doubleValue]]];
    dateFormatter.dateFormat = @"yyyy:MM:dd";
    gps[(__bridge NSString *)kCGImagePropertyGPSDateStamp] = [dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:[self.exifInfos[@"timestamp"] doubleValue]]];
    
    // Clear EXIF after usage
    self.exifInfos = [NSDictionary dictionary];
}

- (NSString*)getTempDirectoryPath
{
  NSString* tmpPath = [NSTemporaryDirectory()stringByStandardizingPath];
  return tmpPath;
}

- (NSString*)getTempFilePath:(NSString*)extension
{
    NSString* tmpPath = [self getTempDirectoryPath];
    NSFileManager* fileMgr = [[NSFileManager alloc] init]; // recommended by Apple (vs [NSFileManager defaultManager]) to be threadsafe
    NSString* filePath;

    // generate unique file name
    int i = 1;
    do {
        filePath = [NSString stringWithFormat:@"%@/%@%04d.%@", tmpPath, TMP_IMAGE_PREFIX, i++, extension];
    } while ([fileMgr fileExistsAtPath:filePath]);

    return filePath;
}

- (NSURL *)getTempDirectoryUrl {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSURL *documentsDirectory = [paths objectAtIndex:0];
    NSURL *tempDirectoryUrl = [documentsDirectory URLByAppendingPathComponent:@"NoCloud"];
    return tempDirectoryUrl;
}

- (NSURL *)getFileUrl:(NSString *)extension {
    NSString *fileName = [self getFileName:extension];
    NSURL *tempDirectoryUrl = [self getTempDirectoryUrl];
    NSURL *fileUrl = [tempDirectoryUrl URLByAppendingPathComponent:fileName];
    return fileUrl;
}

- (NSString *)getFileName:(NSString *)extension {
    NSString *extensionString = extension ?: @"";
    NSString *fileName = [NSString stringWithFormat:@"%@%04d.%@", TMP_IMAGE_PREFIX, arc4random_uniform(1000000), extensionString];
    return fileName;
}

@end
