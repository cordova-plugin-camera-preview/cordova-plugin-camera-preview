#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <CoreVideo/CoreVideo.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreImage/CoreImage.h>
#import <ImageIO/ImageIO.h>

@interface CameraRenderController : GLKViewController
<AVCaptureVideoDataOutputSampleBufferDelegate> {
    CIContext *coreImageContext;
    GLuint _renderBuffer;
}

@property (strong, nonatomic) AVCaptureSession *session;
@property (strong, nonatomic) EAGLContext *context;

@end
