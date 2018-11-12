#import <Cordova/CDV.h>
#import <Cordova/CDVPlugin.h>
#import <Cordova/CDVInvokedUrlCommand.h>

#import "CameraSessionManager.h"
#import "CameraRenderController.h"

@interface CameraPreview : CDVPlugin <TakePictureDelegate, FocusDelegate, PreviewDelegate>

- (void) startCamera:(CDVInvokedUrlCommand*)command;
- (void) stopCamera:(CDVInvokedUrlCommand*)command;
- (void) showCamera:(CDVInvokedUrlCommand*)command;
- (void) hideCamera:(CDVInvokedUrlCommand*)command;
- (void) getFocusMode:(CDVInvokedUrlCommand*)command;
- (void) setFocusMode:(CDVInvokedUrlCommand*)command;
- (void) getFlashMode:(CDVInvokedUrlCommand*)command;
- (void) setFlashMode:(CDVInvokedUrlCommand*)command;
- (void) setZoom:(CDVInvokedUrlCommand*)command;
- (void) getZoom:(CDVInvokedUrlCommand*)command;
- (void) getHorizontalFOV:(CDVInvokedUrlCommand*)command;
- (void) getMaxZoom:(CDVInvokedUrlCommand*)command;
- (void) getExposureModes:(CDVInvokedUrlCommand*)command;
- (void) getExposureMode:(CDVInvokedUrlCommand*)command;
- (void) setExposureMode:(CDVInvokedUrlCommand*)command;
- (void) getExposureCompensation:(CDVInvokedUrlCommand*)command;
- (void) setExposureCompensation:(CDVInvokedUrlCommand*)command;
- (void) getExposureCompensationRange:(CDVInvokedUrlCommand*)command;
- (void) setPreviewSize: (CDVInvokedUrlCommand*)command;
- (void) switchCamera:(CDVInvokedUrlCommand*)command;
- (void) takePicture:(CDVInvokedUrlCommand*)command;
- (void) setColorEffect:(CDVInvokedUrlCommand*)command;
- (void) getSupportedPictureSizes:(CDVInvokedUrlCommand*)command;
- (void) getSupportedFlashModes:(CDVInvokedUrlCommand*)command;
- (void) getSupportedFocusModes:(CDVInvokedUrlCommand*)command;
- (void) tapToFocus:(CDVInvokedUrlCommand*)command;
- (void) getSupportedWhiteBalanceModes:(CDVInvokedUrlCommand*)command;
- (void) getWhiteBalanceMode:(CDVInvokedUrlCommand*)command;
- (void) setWhiteBalanceMode:(CDVInvokedUrlCommand*)command;
- (void) getCameraPreview:(CDVInvokedUrlCommand*)command;

- (void) invokeTakePicture:(CGFloat) width withHeight:(CGFloat) height withQuality:(CGFloat) quality;
- (void) invokeTakePicture;

- (void) invokeTapToFocus:(CGPoint) point;
- (void) invokePreviewDispatch:(CIImage*) preview;

+ (NSString *)picWidth;
+ (NSString *)picHeight;

+ (NSString *)previewWidth;
+ (NSString *)previewHeight;
+ (NSString *)previewImage;

@property(strong, nonatomic, readwrite) NSString *picWidth;
@property(strong, nonatomic, readwrite) NSString *picHeight;

@property(strong, nonatomic, readwrite) NSString *previewWidth;
@property(strong, nonatomic, readwrite) NSString *previewHeight;
@property(strong, nonatomic, readwrite) NSString *previewImage;

@property (nonatomic) CameraSessionManager *sessionManager;
@property (nonatomic) CameraRenderController *cameraRenderController;
@property (nonatomic) NSString *onPictureTakenHandlerId;
@end