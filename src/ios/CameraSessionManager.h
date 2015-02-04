#import <CoreImage/CoreImage.h>
#import <AVFoundation/AVFoundation.h>

@interface CameraSessionManager : NSObject

- (CameraSessionManager *)init;
- (void) setupSession:(NSString *)defaultCamera;
- (void) switchCamera;
- (void) updateOrientation:(AVCaptureVideoOrientation)orientation;
- (AVCaptureVideoOrientation) getCurrentOrientation:(UIInterfaceOrientation)toInterfaceOrientation;

@property (atomic) CIFilter *ciFilter;
@property (nonatomic) NSLock *filterLock;
@property (nonatomic) AVCaptureSession *session;
@property (nonatomic) dispatch_queue_t sessionQueue;
@property (nonatomic) AVCaptureDevicePosition defaultCamera;
@property (nonatomic) AVCaptureDeviceInput *videoDeviceInput;
@property (nonatomic) AVCaptureStillImageOutput *stillImageOutput;
@property (nonatomic) AVCaptureVideoDataOutput *dataOutput;
@property (nonatomic, assign) id delegate;

@end
