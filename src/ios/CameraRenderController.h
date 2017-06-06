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
- (void) invokeTakePictureOnFocus;
@end;

@protocol FocusDelegate
- (void) invokeTapToFocus:(CGPoint)point;
@end;

@interface CameraRenderController : UIViewController <AVCaptureVideoDataOutputSampleBufferDelegate, OnFocusDelegate> {
  GLuint _renderBuffer;
  CVOpenGLESTextureCacheRef _videoTextureCache;
  CVOpenGLESTextureRef _lumaTexture;
}

@property (nonatomic) CameraSessionManager *sessionManager;
@property (nonatomic) CIContext *ciContext;
@property (nonatomic) CIImage *latestFrame;
@property (nonatomic) EAGLContext *context;
@property (nonatomic) NSLock *renderLock;
@property BOOL dragEnabled;
@property BOOL tapToTakePicture;
@property BOOL tapToFocus;
@property (nonatomic, assign) id delegate;

@end
