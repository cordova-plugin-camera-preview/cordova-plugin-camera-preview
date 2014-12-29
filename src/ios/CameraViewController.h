#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "AVCamPreviewView.h"

@interface CameraViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIScrollViewDelegate>{
}



@property (nonatomic, weak) IBOutlet UIImageView *libraryImageView;
@property (nonatomic, weak) IBOutlet UIView *finalImageView;
@property (nonatomic, weak) IBOutlet UIImageView *overlayFrameImageView;


@property (nonatomic, strong) NSString *frameImagePath;
@property (nonatomic, weak) IBOutlet AVCamPreviewView *previewView;

-(void) hideCamera;
-(void) showCamera;
-(void) stopCamera;
-(void) switchCamera;

// Session
@property (nonatomic) dispatch_queue_t sessionQueue; // Communicate with the session and other session objects on this queue.
@property (nonatomic) AVCaptureSession *session;
@property (nonatomic) AVCaptureDeviceInput *videoDeviceInput;
@property (nonatomic) AVCaptureMovieFileOutput *movieFileOutput;
@property (nonatomic) AVCaptureStillImageOutput *stillImageOutput;

// Utilities.
@property (nonatomic) UIBackgroundTaskIdentifier backgroundRecordingID;
@property (nonatomic, getter = isDeviceAuthorized) BOOL deviceAuthorized;
@property (nonatomic, readonly, getter = isSessionRunningAndDeviceAuthorized) BOOL sessionRunningAndDeviceAuthorized;
@property (nonatomic) BOOL lockInterfaceRotation;
@property (nonatomic) id runtimeErrorHandlingObserver;

- (void)takePicture:(void(^)(NSString*, NSString*))callback ;


@end