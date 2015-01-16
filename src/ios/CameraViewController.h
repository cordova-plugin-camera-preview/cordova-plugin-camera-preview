#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

@protocol CameraViewDelegate
    - (void)didTookPictureAction;
@end

@interface CameraViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIScrollViewDelegate>{
    id <NSObject, CameraViewDelegate> delegate;
    GLuint _renderBuffer;
}

@property (retain) id <NSObject, CameraViewDelegate> delegate;
@property (nonatomic, weak) IBOutlet UIImageView *libraryImageView;
@property (nonatomic, weak) IBOutlet UIView *finalImageView;
@property (nonatomic, weak) IBOutlet AVCaptureSession *session;

@property (nonatomic, strong) NSString *frameImagePath;

-(void) hideCamera;
-(void) showCamera;
-(void) stopCamera;
-(void) switchCamera;
-(void) addInterations;

// Session
@property (nonatomic) dispatch_queue_t sessionQueue; // Communicate with the session and other session objects on this queue.
@property (nonatomic) AVCaptureDeviceInput *videoDeviceInput;
@property (nonatomic) AVCaptureVideoDataOutput *videoDataOutput;
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
