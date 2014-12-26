#import <Cordova/CDV.h>
#import <Cordova/CDVPlugin.h>
#import <Cordova/CDVInvokedUrlCommand.h>
#import "CameraViewController.h"

@interface CameraPreview : CDVPlugin

-(void)reportEvent:(NSDictionary*)eventData;
	@property (nonatomic, strong) CameraViewController* cameraViewController;
@end
