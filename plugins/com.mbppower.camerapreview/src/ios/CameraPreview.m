#import <Cordova/CDV.h>
#import <Cordova/CDVPlugin.h>
#import <Cordova/CDVInvokedUrlCommand.h>

#import "CameraPreview.h"
#import "CameraViewController.h"

@interface CameraPreview()

@property (nonatomic, retain) NSString *listenerCallbackId;
	
@end

@implementation CameraPreview


-(void)startCamera:(CDVInvokedUrlCommand*)command{
 
    CDVPluginResult *pluginResult;
    
    if (command.arguments.count > 0){
        self.cameraViewController = [[CameraViewController alloc] initWithNibName:@"CameraViewController" bundle:nil];
        self.cameraViewController.view.backgroundColor = [UIColor clearColor];
        self.viewController.modalPresentationStyle = UIModalPresentationCurrentContext;
        [self.viewController presentViewController:self.cameraViewController animated:NO completion:nil];
        
        self.cameraViewController.view.userInteractionEnabled = false;
        CGFloat x = (CGFloat)[command.arguments[0] floatValue];
        CGFloat y = (CGFloat)[command.arguments[1] floatValue];
        CGFloat width = (CGFloat)[command.arguments[2] floatValue];
        CGFloat height = (CGFloat)[command.arguments[3] floatValue];
        
        NSLog(@"startCamera: %f, %f, %f, %f", x, y, width, height);

        self.cameraViewController.finalImageView.frame = CGRectMake(x, y, width, height);
		pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    }
	else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Invalid number of parameters"];
    }
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

-(void)hideCamera:(CDVInvokedUrlCommand*)command{
    NSLog(@"hideCamera");
    CDVPluginResult *pluginResult;
    
    if(self.cameraViewController != nil){
        [self.cameraViewController hideCamera];
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    }
    else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Camera not started"];
    }
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}
-(void)switchCamera:(CDVInvokedUrlCommand*)command{
    NSLog(@"switchCamera");
    CDVPluginResult *pluginResult;
    
    if(self.cameraViewController != nil){
        [self.cameraViewController switchCamera];
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    }
    else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Camera not started"];
    }
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}
-(void)showCamera:(CDVInvokedUrlCommand*)command{
    NSLog(@"showCamera");
    CDVPluginResult *pluginResult;
    
    if(self.cameraViewController != nil){
        [self.cameraViewController showCamera];
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    }
    else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Camera not started"];
    }
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

-(void)stopCamera:(CDVInvokedUrlCommand*)command{
    NSLog(@"stopCamera");
    CDVPluginResult *pluginResult;
    
    if(self.cameraViewController != nil){
        [self.cameraViewController stopCamera];
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    }
    else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Camera not started"];
    }
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}


- (NSString *)encodeToBase64String:(UIImage *)image {
	return [UIImagePNGRepresentation(image) base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
}

-(void)takePicture:(CDVInvokedUrlCommand*)command{
    NSLog(@"takePicture");
    __block CDVPluginResult *pluginResult;

    if(self.cameraViewController != NULL){
        //take picture
        [self.cameraViewController takePicture: ^(NSString* originalPicturePath, NSString* previewPicturePath){
            NSMutableArray *params = [[NSMutableArray alloc] init];
            [params addObject:originalPicturePath];
            [params addObject:previewPicturePath];
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:params];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }];
    }
    else{
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Call startCamera first."];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

-(void)bindListener:(CDVInvokedUrlCommand*) command{
    NSLog(@"bindListener");
    
    self.listenerCallbackId = command.callbackId;
    
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [pluginResult setKeepCallbackAsBool:true];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

-(void)reportEvent:(NSDictionary*)eventData{
    NSLog(@"reportEvent");
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:eventData];
    [pluginResult setKeepCallbackAsBool:true];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.listenerCallbackId];
}

@end
