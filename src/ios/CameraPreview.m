#import <Cordova/CDV.h>
#import <Cordova/CDVPlugin.h>
#import <Cordova/CDVInvokedUrlCommand.h>
#import <GLKit/GLKit.h>

#import "CameraPreview.h"
#import "CameraViewController.h"
#import "CameraRenderController.h"

@interface CameraPreview()

@property (nonatomic, retain) NSString *listenerCallbackId;
@property (nonatomic, retain) NSString *onPictureTakenHandlerId;

@end

@implementation CameraPreview

-(void)startCamera:(CDVInvokedUrlCommand*)command{
 
    CDVPluginResult *pluginResult;
    
    if (command.arguments.count > 0){
		
		    CGFloat x = (CGFloat)[command.arguments[0] floatValue];
        CGFloat y = (CGFloat)[command.arguments[1] floatValue];
        CGFloat width = (CGFloat)[command.arguments[2] floatValue];
        CGFloat height = (CGFloat)[command.arguments[3] floatValue];
        NSString *defaultCamera = command.arguments[4];
        BOOL tapToTakePicture = (BOOL)[command.arguments[5] boolValue];
        BOOL dragEnabled = (BOOL)[command.arguments[6] boolValue];
        
        // Create the AVCaptureSession
        AVCaptureSession *session = [[AVCaptureSession alloc] init];

        //controller params setup
        self.cameraViewController = [[CameraViewController alloc] initWithNibName:@"CameraViewController" bundle:nil];
        self.cameraViewController.delegate = self;
    		self.cameraViewController.defaultCamera = defaultCamera;
        self.cameraViewController.dragEnabled = dragEnabled;
        self.cameraViewController.tapToTakePicture = tapToTakePicture;
        [self.cameraViewController setSession:session];

        //render controller setup
        self.cameraRenderController = [[CameraRenderController alloc] init];
        [self.cameraRenderController setSession:session];

        //frame setup
        self.cameraViewController.view.frame = CGRectMake(x, y, width, height);
        self.cameraViewController.finalImageView.frame = CGRectMake(0, 0, width, height);
        self.cameraRenderController.view.frame = CGRectMake(x, y, width, height);

        //add camera preview view
        [self.viewController addChildViewController:self.cameraViewController];
        [self.viewController.view addSubview:self.cameraViewController.view];

        // Add render view
        [self.viewController addChildViewController:self.cameraRenderController];
        [self.viewController.view addSubview:self.cameraRenderController.view];

        //set user interactions
        [self.cameraViewController addInterations];

        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    }
	else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Invalid number of parameters"];
    }
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}
//CameraView delegate
-(void) didTookPictureAction {
    NSLog(@"didTookPictureActionDelegate");
    if(self.cameraViewController != NULL){
         //take picture
         [self.cameraViewController takePicture: ^(NSString* originalPicturePath, NSString* previewPicturePath){
             NSMutableArray *params = [[NSMutableArray alloc] init];
             [params addObject:originalPicturePath];
             [params addObject:previewPicturePath];
             
             [self callOnPictureTakenHandler:params];
         }];
     }
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
        [self didTookPictureAction];
    }
    else{
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Call startCamera first."];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

-(void)setOnPictureTakenHandler:(CDVInvokedUrlCommand*) command{
    NSLog(@"setOnPictureTakenHandler");
    self.onPictureTakenHandlerId = command.callbackId;
}

-(void)callOnPictureTakenHandler:(NSMutableArray*)eventData{
    NSLog(@"callOnPictureTakenHandler");
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:eventData];
    [pluginResult setKeepCallbackAsBool:true];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.onPictureTakenHandlerId];
}

@end
