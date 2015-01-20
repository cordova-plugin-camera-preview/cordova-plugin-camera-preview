#import <CoreImage/CoreImage.h>
#import <AVFoundation/AVFoundation.h>

@interface CameraSessionManager : NSObject

- (CameraSessionManager *) init:(NSString *)defaultCamera;
- (void) switchCamera;

@property (atomic) CIFilter *ciFilter;
@property (nonatomic) AVCaptureSession *session;
@property (nonatomic) dispatch_queue_t sessionQueue;
@property (nonatomic) AVCaptureDevicePosition defaultCamera;
@property (nonatomic) AVCaptureDeviceInput *videoDeviceInput;
@property (nonatomic) AVCaptureStillImageOutput *stillImageOutput;

@end
