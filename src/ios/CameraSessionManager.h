#import <CoreImage/CoreImage.h>
#import <AVFoundation/AVFoundation.h>

@interface CameraSessionManager : NSObject

- (CameraSessionManager *) init:(NSString *)defaultCamera;

@property (atomic) CIFilter *ciFilter;
@property (nonatomic) AVCaptureSession *session;
@property (nonatomic) dispatch_queue_t sessionQueue;
@property (nonatomic) NSString *defaultCamera;

@end
