#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <CoreVideo/CoreVideo.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreImage/CoreImage.h>
#import <ImageIO/ImageIO.h>

#import "CameraSessionManager.h"

@interface CameraRenderController : GLKViewController
<AVCaptureVideoDataOutputSampleBufferDelegate> {
    GLuint _renderBuffer;
}

@property (strong, nonatomic) CameraSessionManager *sessionManager;
@property (strong, nonatomic) CIContext *ciContext;
@property (strong, nonatomic) EAGLContext *context;

@end
