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
        CGFloat x = (CGFloat)[command.arguments[0] floatValue];
        CGFloat y = (CGFloat)[command.arguments[1] floatValue];
        CGFloat width = (CGFloat)[command.arguments[2] floatValue];
        CGFloat height = (CGFloat)[command.arguments[3] floatValue];
        NSString *defaultCamera = command.arguments[4];
        BOOL tapToTakePicture = (BOOL)[command.arguments[5] boolValue];
        BOOL dragEnabled = (BOOL)[command.arguments[6] boolValue];

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
        [self.viewController.view addSubview:self.cameraRenderController.view];

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

    if(self.sessionManager != nil){
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
        self.cameraRenderController.view.hidden = YES;
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
        self.cameraRenderController.view.hidden = NO;
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

- (void) takePicture:(CDVInvokedUrlCommand*)command {
    NSLog(@"takePicture");
    CDVPluginResult *pluginResult;

    if (self.cameraRenderController != NULL) {
        [self invokeTakePicture];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Camera not started"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

-(void) setOnPictureTakenHandler:(CDVInvokedUrlCommand*)command {
    NSLog(@"setOnPictureTakenHandler");
    self.onPictureTakenHandlerId = command.callbackId;
}

-(void) setColorEffect:(CDVInvokedUrlCommand*)command {
    NSLog(@"setColorEffect");
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    NSString *filterName = command.arguments[0];

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

    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) invokeTakePicture {
    AVCaptureConnection *connection = [self.sessionManager.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
    [self.sessionManager.stillImageOutput captureStillImageAsynchronouslyFromConnection:connection completionHandler:^(CMSampleBufferRef sampleBuffer, NSError *error) {
        NSLog(@"Done creating still image");
        if (error) {
            NSLog(@"%@", error);
        } else {
            [self.cameraRenderController.renderLock lock];
            CIImage *previewCImage = self.cameraRenderController.latestFrame;
            CGImageRef previewImage = [self.cameraRenderController.ciContext createCGImage:previewCImage fromRect:previewCImage.extent];
            [self.cameraRenderController.renderLock unlock];

            NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:sampleBuffer];
            UIImage *capturedImage  = [[UIImage alloc] initWithData:imageData];
            CIImage *capturedCImage = [[CIImage alloc] initWithCGImage:[capturedImage CGImage]];
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
                finalCImage = capturedCImage;
            }
 
            CGImageRef finalImage = [self.cameraRenderController.ciContext createCGImage:finalCImage fromRect:finalCImage.extent];

            ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];

            dispatch_group_t group = dispatch_group_create();

            __block NSString *originalPicturePath;
            __block NSString *previewPicturePath;

            ALAssetOrientation orientation;
            switch ([[UIApplication sharedApplication] statusBarOrientation]) {
                case UIDeviceOrientationPortraitUpsideDown:
                    orientation = ALAssetOrientationLeft;
                    break;
                case UIDeviceOrientationLandscapeLeft:
                    orientation = ALAssetOrientationUp;
                    break;
                case UIDeviceOrientationLandscapeRight:
                    orientation = ALAssetOrientationDown;
                    break;
                case UIDeviceOrientationPortrait:
                default:
                    orientation = ALAssetOrientationRight;
            }

            // task 1
            dispatch_group_enter(group);
            [library writeImageToSavedPhotosAlbum:previewImage orientation:ALAssetOrientationUp completionBlock:^(NSURL *assetURL, NSError *error) {
                if (error) {
                     NSLog(@"FAILED to save Preview picture.");
                } else {
                     previewPicturePath = [assetURL absoluteString];
                     NSLog(@"previewPicturePath: %@", previewPicturePath);
                     dispatch_group_leave(group);
                }
            }];
                
            //task 2
            dispatch_group_enter(group);
            [library writeImageToSavedPhotosAlbum:finalImage orientation:orientation completionBlock:^(NSURL *assetURL, NSError *error) {
                if (error) {
                    NSLog(@"FAILED to save Original picture.");
                } else {
                    originalPicturePath = [assetURL absoluteString];
                    NSLog(@"originalPicturePath: %@", originalPicturePath);
                }
                dispatch_group_leave(group);
            }];

            dispatch_group_notify(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                NSMutableArray *params = [[NSMutableArray alloc] init];
                [params addObject:originalPicturePath];
                [params addObject:previewPicturePath];
             
                CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:params];
                [pluginResult setKeepCallbackAsBool:true];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:self.onPictureTakenHandlerId];
            });
        }
    }];
}

@end
