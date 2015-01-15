#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "AVCamPreviewView.h"

@protocol CameraViewDelegate
    - (void)didTookPictureAction;
@end

@interface CameraViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIScrollViewDelegate>{
    id <NSObject, CameraViewDelegate> delegate;
}

@property (retain) id <NSObject, CameraViewDelegate> delegate;
@property (nonatomic, weak) IBOutlet UIImageView *libraryImageView;
@property (nonatomic, weak) IBOutlet UIView *finalImageView;


@property (nonatomic, strong) NSString *frameImagePath;
@property (nonatomic, weak) IBOutlet AVCamPreviewView *previewView;

-(void) hideCamera;
-(void) showCamera;
-(void) stopCamera;
-(void) switchCamera;
-(void) addInterations;

// Session
@property (nonatomic) dispatch_queue_t sessionQueue; // Communicate with the session and other session objects on this queue.
@property (nonatomic) AVCaptureSession *session;
@property (nonatomic) AVCaptureDeviceInput *videoDeviceInput;
@property (nonatomic) AVCaptureMovieFileOutput *movieFileOutput;
@property (nonatomic) AVCaptureStillImageOutput *stillImageOutput;
@property (nonatomic) NSString *defaultCamera;
@property (nonatomic) BOOL dragEnabled;
@property (nonatomic) BOOL tapToTakePicture;

// Utilities.
@property (nonatomic) UIBackgroundTaskIdentifier backgroundRecordingID;
@property (nonatomic, getter = isDeviceAuthorized) BOOL deviceAuthorized;
@property (nonatomic, readonly, getter = isSessionRunningAndDeviceAuthorized) BOOL sessionRunningAndDeviceAuthorized;
@property (nonatomic) BOOL lockInterfaceRotation;
@property (nonatomic) id runtimeErrorHandlingObserver;

- (void)takePicture:(void(^)(NSString*, NSString*))callback ;
- (void)handleTakePictureTap:(UITapGestureRecognizer*)recognizer;

@end