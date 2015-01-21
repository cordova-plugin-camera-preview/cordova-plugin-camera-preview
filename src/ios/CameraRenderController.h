#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <CoreVideo/CoreVideo.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreImage/CoreImage.h>
#import <ImageIO/ImageIO.h>

#import "CameraSessionManager.h"

@protocol TakePictureDelegate
- (void) invokeTakePicture;
@end;

@interface CameraRenderController : GLKViewController
<AVCaptureVideoDataOutputSampleBufferDelegate> {
    GLuint _renderBuffer;
}

- (void)resetOrientation;
- (IBAction)handlePan:(UIPanGestureRecognizer *)recognizer;

@property (strong, nonatomic) CameraSessionManager *sessionManager;
@property (strong, nonatomic) CIContext *ciContext;
@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) AVCaptureVideoDataOutput *dataOutput;
@property BOOL dragEnabled;
@property (nonatomic, assign) id delegate;

@end
