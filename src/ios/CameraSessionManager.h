#import <CoreImage/CoreImage.h>
#import <AVFoundation/AVFoundation.h>
#import "TemperatureAndTint.h"

@protocol OnFocusDelegate
- (void) onFocus;
@end;

@interface CameraSessionManager : NSObject

- (CameraSessionManager *)init;
- (NSArray *) getDeviceFormats;
- (NSArray *) getFocusModes;
- (NSString *) getFocusMode;
- (NSString *) setFocusMode:(NSString *)focusMode;
- (NSArray *) getFlashModes;
- (NSInteger) getFlashMode;
- (void) setupSession:(NSString *)defaultCamera completion:(void(^)(BOOL started))completion;
- (void) switchCamera:(void(^)(BOOL switched))completion;
- (void) setFlashMode:(NSInteger)flashMode;
- (void) setZoom:(CGFloat)desiredZoomFactor;
- (CGFloat) getZoom;
- (float) getHorizontalFOV;
- (CGFloat) getMaxZoom;
- (NSArray *) getExposureModes;
- (NSString *) getExposureMode;
- (NSString *) setExposureMode:(NSString *)exposureMode;
- (NSArray *) getExposureCompensationRange;
- (CGFloat) getExposureCompensation;
- (void) setExposureCompensation:(CGFloat)exposureCompensation;
- (NSArray *) getSupportedWhiteBalanceModes;
- (NSString *) getWhiteBalanceMode;
- (NSString *) setWhiteBalanceMode:(NSString *)whiteBalanceMode;
- (void) updateOrientation:(AVCaptureVideoOrientation)orientation;
- (void) tapToFocus:(CGFloat)xPoint yPoint:(CGFloat)yPoint;
- (void) takePictureOnFocus;
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
@property (nonatomic) NSString *currentWhiteBalanceMode;
@property (nonatomic) NSDictionary *colorTemperatures;

@end
