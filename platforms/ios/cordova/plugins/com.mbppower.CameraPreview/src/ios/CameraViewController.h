#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "AVCamPreviewView.h"

@interface CameraViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIScrollViewDelegate>{
}

-(IBAction) takePhotoButtonPressed:(UIButton *)sender;
-(IBAction) hideView:(UIButton *)sender;
-(IBAction) switchCamera:(id)sender forEvent:(UIEvent*)event;
-(IBAction) help:(id)sender forEvent:(UIEvent*)event;
-(IBAction) selectPhoto:(UIButton *)sender;
-(IBAction) confirmPhoto:(UIButton *)sender;

@property (nonatomic, weak) IBOutlet UIView *topBarView;
@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;
@property (nonatomic, weak) IBOutlet UIButton *frameBackButton;
@property (nonatomic, weak) IBOutlet UIButton *shootButton;
@property (nonatomic, weak) IBOutlet UIButton *switchCameraButton;
@property (nonatomic, weak) IBOutlet UIButton *frameInfoButton;
@property (nonatomic, weak) IBOutlet UIButton *confirmPhotoButton;
@property (nonatomic, weak) IBOutlet UIImageView *libraryImageView;
@property (nonatomic, weak) IBOutlet UIView *finalImageView;
@property (nonatomic, weak) IBOutlet UIImageView *overlayFrameImageView;
@property (nonatomic, weak) IBOutlet AVCamPreviewView *cameraContainerView;

@property (nonatomic, strong) UIButton* lastClickedThumb;
@property (nonatomic, assign) NSUInteger *currentCollectionIndex;
@property (nonatomic, strong) NSString *frameImagePath;
@property (nonatomic, strong) NSMutableDictionary* framesJSON;
@property (nonatomic, strong) NSMutableDictionary* currentFrameCollection;


@property (nonatomic, weak) IBOutlet AVCamPreviewView *previewView;

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


@end