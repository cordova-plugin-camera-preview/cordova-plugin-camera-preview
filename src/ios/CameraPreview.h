#import <Cordova/CDV.h>
#import <Cordova/CDVPlugin.h>
#import <Cordova/CDVInvokedUrlCommand.h>
#import "CameraViewController.h"
#import "CameraRenderController.h"

@interface CameraPreview : CDVPlugin <CameraViewDelegate>

    -(void)reportEvent:(NSDictionary*)eventData;
	@property (nonatomic, strong) CameraViewController* cameraViewController;
  @property (nonatomic, strong) CameraRenderController* cameraRenderController;
@end
