#import <Cordova/CDV.h>
#import <Cordova/CDVPlugin.h>
#import <Cordova/CDVInvokedUrlCommand.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <Photos/Photos.h>
#import "CameraPreview.h"


@implementation CameraPreview

-(void) pluginInitialize{
  // start as transparent
  self.webView.opaque = NO;
  self.webView.backgroundColor = [UIColor clearColor];
}

- (void) startCamera:(CDVInvokedUrlCommand*)command {

  CDVPluginResult *pluginResult;

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
    BOOL tapToFocus = (BOOL) [command.arguments[9] boolValue];

    // Create the session manager
    self.sessionManager = [[CameraSessionManager alloc] init];

    // render controller setup
    self.cameraRenderController = [[CameraRenderController alloc] init];
    self.cameraRenderController.dragEnabled = dragEnabled;
    self.cameraRenderController.tapToTakePicture = tapToTakePicture;
    self.cameraRenderController.tapToFocus = tapToFocus;
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
    NSInteger flashMode = [self.sessionManager getFlashMode];
    NSString * sFlashMode;
    if (flashMode == 0) {
      sFlashMode = @"off";
    } else if (flashMode == 1) {
      sFlashMode = @"on";
    } else if (flashMode == 2) {
      sFlashMode = @"auto";
    } else {
      sFlashMode = @"unsupported";
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

    [self invokeTakePicture:width withHeight:height withQuality:quality];
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

        NSMutableArray *params = [[NSMutableArray alloc] init];

        CGImageRef finalImage = [self.cameraRenderController.ciContext createCGImage:finalCImage fromRect:finalCImage.extent];
        UIImage *resultImage = [UIImage imageWithCGImage:finalImage];
        //UIImage *resultImage2 = [UIImage imageWithCGImage:finalImage];
        
        
        //ALAssetsLibrary* library = [ALAssetsLibrary new];
        //[library writeImageToSavedPhotosAlbum:resultImage.CGImage orientation:(ALAssetOrientation)(resultImage.imageOrientation) completionBlock:nil];

        double radians = [self radiansFromUIImageOrientation:resultImage.imageOrientation];
        CGImageRef resultFinalImage = [self CGImageRotated:finalImage withRadians:radians];

        CGImageRelease(finalImage); // release CGImageRef to remove memory leaks

        NSString *base64Image = [self getBase64Image:resultFinalImage withQuality:quality];
          
        UIImage *resultImage2 = [self fixOrientation:capturedImage];
        [self save:resultImage2];
          
        CGImageRelease(resultFinalImage); //release CGImageRef to remove memory leaks
        
        [params addObject:base64Image];

        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:params];
        [pluginResult setKeepCallbackAsBool:true];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.onPictureTakenHandlerId];
          
        //
        
      }
    }];
}

- (UIImage *)fixOrientation:(UIImage*) img {
    
    // No-op if the orientation is already correct
    if (img.imageOrientation == UIImageOrientationUp) return img;
    
    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (img.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, img.size.width, img.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, img.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, img.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationUpMirrored:
            break;
    }
    
    switch (img.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, img.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, img.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationDown:
        case UIImageOrientationLeft:
        case UIImageOrientationRight:
            break;
    }
    
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, img.size.width, img.size.height,
                                             CGImageGetBitsPerComponent(img.CGImage), 0,
                                             CGImageGetColorSpace(img.CGImage),
                                             CGImageGetBitmapInfo(img.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (img.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx, CGRectMake(0,0,img.size.height,img.size.width), img.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,img.size.width,img.size.height), img.CGImage);
            break;
    }
    
    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img2 = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img2;
}

- (void)save:(UIImage*) img {
    PHAuthorizationStatus oldStatus = [PHPhotoLibrary authorizationStatus];
    
    // 请求\检查访问权限 :
    // 如果用户还没有做出选择，会自动弹框，用户对弹框做出选择后，才会调用block
    // 如果之前已经做过选择，会直接执行block
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (status == PHAuthorizationStatusDenied) { // 用户拒绝当前App访问相册
                if (oldStatus != PHAuthorizationStatusNotDetermined) {
                    //DLog(@"提醒用户打开开关");
                }
            } else if (status == PHAuthorizationStatusAuthorized) { // 用户允许当前App访问相册
                [self saveImageIntoAlbum:img];
            } else if (status == PHAuthorizationStatusRestricted) { // 无法访问相册
                //[SVProgressHUD showErrorWithStatus:@"因系统原因，无法访问相册！"];
            }
        });
    }];
}
#pragma mark - 保存图片到自定义相册
- (void)saveImageIntoAlbum:(UIImage*) img
{
    // 获得相片
    PHFetchResult<PHAsset *> *createdAssets = [self createdAssets:img];
    if (createdAssets == nil) {
        //[SVProgressHUD showErrorWithStatus:@"保存图片失败！"];
        return;
    }
    
    // 获得相册
    PHAssetCollection *createdCollection = self.createdCollection;
    if (createdCollection == nil) {
        //[SVProgressHUD showErrorWithStatus:@"创建或者获取相册失败！"];
        return;
    }
    
    // 添加刚才保存的图片到【自定义相册】
    NSError *error = nil;
    [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
        PHAssetCollectionChangeRequest *request = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:createdCollection];
        [request insertAssets:createdAssets atIndexes:[NSIndexSet indexSetWithIndex:0]];
    } error:&error];
    
    // 最后的判断
    if (error) {
        //[SVProgressHUD showErrorWithStatus:@"保存图片失败！"];
    } else {
        //[SVProgressHUD showSuccessWithStatus:@"保存图片成功！"];
    }
}
#pragma mark - 获得当前App对应的自定义相册
- (PHAssetCollection *)createdCollection
{
    // 获得APP名字
    NSString *title = [NSBundle mainBundle].infoDictionary[(__bridge NSString *)kCFBundleNameKey];
    
    // 抓取所有的自定义相册
    PHFetchResult<PHAssetCollection *> *collections = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    
    // 查找当前App对应的自定义相册
    for (PHAssetCollection *collection in collections) {
        if ([collection.localizedTitle isEqualToString:title]) {
            return collection;
        }
    }
    
    /** 当前App对应的自定义相册没有被创建过 **/
    // 创建一个【自定义相册】
    NSError *error = nil;
    __block NSString *createdCollectionID = nil;
    [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
        createdCollectionID = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:title].placeholderForCreatedAssetCollection.localIdentifier;
    } error:&error];
    
    if (error) return nil;
    
    // 根据唯一标识获得刚才创建的相册
    return [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[createdCollectionID] options:nil].firstObject;
}
#pragma mark - 获得相片
- (PHFetchResult<PHAsset *> *)createdAssets:(UIImage*) img
{
    NSError *error = nil;
    __block NSString *assetID = nil;
    
    // 保存图片到【相机胶卷】
    [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
        assetID = [PHAssetChangeRequest creationRequestForAssetFromImage:img].placeholderForCreatedAsset.localIdentifier;
    } error:&error];
    
    if (error) return nil;
    
    // 获取刚才保存的相片
    return [PHAsset fetchAssetsWithLocalIdentifiers:@[assetID] options:nil];
}

@end