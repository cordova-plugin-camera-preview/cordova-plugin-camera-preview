#import <AssetsLibrary/AssetsLibrary.h>
#import <Cordova/CDV.h>
#import <Cordova/CDVPlugin.h>
#import <Cordova/CDVInvokedUrlCommand.h>

#import "CameraPreview.h"

@implementation CameraPreview

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
    // Create the session manager
    self.sessionManager = [[CameraSessionManager alloc] init];

    //render controller setup
    self.cameraRenderController = [[CameraRenderController alloc] init];
    self.cameraRenderController.dragEnabled = dragEnabled;
    self.cameraRenderController.tapToTakePicture = tapToTakePicture;
    self.cameraRenderController.sessionManager = self.sessionManager;
    self.cameraRenderController.view.frame = CGRectMake(x, y, width, height);
    self.cameraRenderController.delegate = self;

    [self.viewController addChildViewController:self.cameraRenderController];
    //display the camera bellow the webview
    if (toBack) {
      //make transparent
      self.webView.opaque = NO;
      self.webView.backgroundColor = [UIColor clearColor];
      [self.webView.superview insertSubview:self.cameraRenderController.view belowSubview:self.webView];
    }
    else{
      self.cameraRenderController.view.alpha = (CGFloat)[command.arguments[8] floatValue];
      [self.webView.superview insertSubview:self.cameraRenderController.view aboveSubview:self.webView];
    }

    // Setup session
    self.sessionManager.delegate = self.cameraRenderController;
    [self.sessionManager setupSession:defaultCamera];

    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
  } else {
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Invalid number of parameters"];
  }

  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) stopCamera:(CDVInvokedUrlCommand*)command {
  NSLog(@"stopCamera");
  CDVPluginResult *pluginResult;

  if(self.sessionManager != nil) {
    [self.cameraRenderController.view removeFromSuperview];
    [self.cameraRenderController removeFromParentViewController];
    self.cameraRenderController = nil;

    [self.sessionManager.session stopRunning];
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
    [self.sessionManager switchCamera];
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
  } else {
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Camera not started"];
  }

  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) setFlashMode:(CDVInvokedUrlCommand*)command {
  NSLog(@"Flash Mode");
  CDVPluginResult *pluginResult;

  NSInteger flashMode;
  NSString *errMsg;

  if (command.arguments.count <= 0)
  {
    errMsg = @"Please specify a flash mode";
  }
  else
  {
    NSString *strFlashMode = [command.arguments objectAtIndex:0];
    flashMode = [strFlashMode integerValue];
    if (flashMode != AVCaptureFlashModeOff
        && flashMode != AVCaptureFlashModeOn
        && flashMode != AVCaptureFlashModeAuto)
    {
      errMsg = @"Invalid parameter";
    }

  }

  if (errMsg) {
    NSLog(@"%@", errMsg);

  } else {
    if (self.sessionManager != nil) {
      [self.sessionManager setFlashMode:flashMode];
      pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    } else {
      pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Camera not started"];
    }
  }

  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) takePicture:(CDVInvokedUrlCommand*)command {
  NSLog(@"takePicture");
  CDVPluginResult *pluginResult;

  if (self.cameraRenderController != NULL) {
    CGFloat maxW = (CGFloat)[command.arguments[0] floatValue];
    CGFloat maxH = (CGFloat)[command.arguments[1] floatValue];
    [self invokeTakePicture:maxW withHeight:maxH];
  } else {
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Camera not started"];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
  }
}

-(void) setOnPictureTakenHandler:(CDVInvokedUrlCommand*)command {
  NSLog(@"setOnPictureTakenHandler");
  self.onPictureTakenHandlerId = command.callbackId;
}

- (void) invokeTakePicture {
  [self invokeTakePicture:0.0 withHeight:0.0];
}

- (void) invokeTakePicture:(CGFloat) maxWidth withHeight:(CGFloat) maxHeight {
        AVCaptureConnection *connection = [self.sessionManager.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
        [self.sessionManager.stillImageOutput captureStillImageAsynchronouslyFromConnection:connection completionHandler:^(CMSampleBufferRef sampleBuffer, NSError *error) {

          NSLog(@"Done creating still image");

          if (error) {
            NSLog(@"%@", error);
          } else {
            NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:sampleBuffer];
            UIImage *capturedImage  = [[UIImage alloc] initWithData:imageData];

            capturedImage = [self imageCorrectedForCaptureOrientation:capturedImage];

            NSString *originalPicture = [NSString stringWithFormat:@"data:image/jpeg;base64,%@", [UIImageJPEGRepresentation(capturedImage, 0.75f) base64EncodedStringWithOptions:0]];

            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:originalPicture];
            [pluginResult setKeepCallbackAsBool:true];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:self.onPictureTakenHandlerId];
          }
        }];
}

- (UIImage*)imageCorrectedForCaptureOrientation:(UIImage *)sourceImage
{
  float rotation_radians = 0;
  bool perpendicular = false;
  UIImageOrientation imageOrientation = sourceImage.imageOrientation;

  switch (imageOrientation) {
    case UIImageOrientationUp :
      rotation_radians = 0.0;
      break;

    case UIImageOrientationDown:
      rotation_radians = M_PI; // don't be scared of radians, if you're reading this, you're good at math
      break;

    case UIImageOrientationRight:
      rotation_radians = M_PI_2;
      perpendicular = true;
      break;

    case UIImageOrientationLeft:
      rotation_radians = -M_PI_2;
      perpendicular = true;
      break;

    default:
      break;
  }

  CGSize imageSize = sourceImage.size;
  CGFloat imageWidth = imageSize.width;
  CGFloat imageHeight = imageSize.height;

  UIGraphicsBeginImageContext(CGSizeMake(imageWidth, imageHeight));
  CGContextRef context = UIGraphicsGetCurrentContext();

  // Rotate around the center point
  CGContextTranslateCTM(context, imageWidth / 2, imageHeight / 2);
  CGContextRotateCTM(context, rotation_radians);

  CGContextScaleCTM(context, 1.0, -1.0);
  float width = perpendicular ? imageHeight : imageWidth;
  float height = perpendicular ? imageWidth : imageHeight;

  // flip image if front camera
  if (self.sessionManager.defaultCamera == AVCaptureDevicePositionFront) {
    CGContextScaleCTM(context, 1.0f, -1.0f);
  }

  CGContextDrawImage(context, CGRectMake(-width / 2, -height / 2, width, height), [sourceImage CGImage]);

  // Move the origin back since the rotation might've change it (if its 90 degrees)
  if (perpendicular) {
    CGContextTranslateCTM(context, -imageHeight / 2, -imageWidth / 2);
  }

  UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return newImage;
}
@end
