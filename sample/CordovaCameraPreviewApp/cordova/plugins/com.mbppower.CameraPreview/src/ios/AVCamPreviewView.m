#import "AVCamPreviewView.h"
#import <AVFoundation/AVFoundation.h>

@implementation AVCamPreviewView

+ (Class)layerClass {
    return [AVCaptureVideoPreviewLayer class];
}

- (AVCaptureSession *)session {
    return [(AVCaptureVideoPreviewLayer *)[self layer] session];
}

- (void)setSession:(AVCaptureSession *)session {
    AVCaptureVideoPreviewLayer *avLayer = (AVCaptureVideoPreviewLayer *)[self layer];
    [avLayer setSession:session];
    
    CGRect bounds = self.layer.bounds;
    avLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    avLayer.bounds = bounds;
    avLayer.position = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
}

@end