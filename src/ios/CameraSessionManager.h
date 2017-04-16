#import <CoreImage/CoreImage.h>
#import <AVFoundation/AVFoundation.h>

@interface CameraSessionManager : NSObject

- (CameraSessionManager *)init;
- (NSArray *) getDeviceFormats;
- (NSArray *) getFlashModes;
- (void) setupSession:(NSString *)defaultCamera;
- (void) switchCamera;
- (void) setFlashMode:(NSInteger)flashMode;
- (void) setZoom:(CGFloat)desiredZoomFactor;
- (CGFloat) getZoom;
- (CGFloat) getMaxZoom;
- (NSArray *) getExposureModes;
- (NSString *) getExposureMode;
- (NSString *) setExposureMode:(NSString *)exposureMode;
- (NSArray *) getExposureCompensationRange;
- (CGFloat) getExposureCompensation;
- (void) setExposureCompensation:(CGFloat)exposureCompensation;
- (void) updateOrientation:(AVCaptureVideoOrientation)orientation;
- (void) tapToFocus:(CGFloat)xPoint yPoint:(CGFloat)yPoint;
- (void) setTorchMode;
- (AVCaptureVideoOrientation) getCurrentOrientation:(UIInterfaceOrientation)toInterfaceOrientation;

@property (atomic) CIFilter *ciFilter;
@property (nonatomic) NSLock *filterLock;
@property (nonatomic) AVCaptureSession *session;
@property (nonatomic) dispatch_queue_t sessionQueue;
@property (nonatomic) AVCaptureDevicePosition defaultCamera;
@property (nonatomic) NSInteger defaultFlashMode;
@property (nonatomic) CGFloat videoZoomFactor;
@property (nonatomic) AVCaptureDevice *device;
@property (nonatomic) AVCaptureDeviceInput *videoDeviceInput;
@property (nonatomic) AVCaptureStillImageOutput *stillImageOutput;
@property (nonatomic) AVCaptureVideoDataOutput *dataOutput;
@property (nonatomic, assign) id delegate;

@end
