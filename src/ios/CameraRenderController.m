#import "CameraRenderController.h"

@implementation CameraRenderController
@synthesize context = _context;

- (void)viewDidLoad
{
    [super viewDidLoad]; 

    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];

    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }

    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    glGenRenderbuffers(1, &_renderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);

    coreImageContext = [CIContext contextWithEAGLContext:self.context]; 

    AVCaptureVideoDataOutput *dataOutput = [[AVCaptureVideoDataOutput alloc] init];
    if ([self.session canAddOutput:dataOutput])
    {
        [dataOutput setAlwaysDiscardsLateVideoFrames:YES];
        [dataOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];   

        [dataOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];

        [self.session addOutput:dataOutput];
    }
}

-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    CVPixelBufferRef pixelBuffer = (CVPixelBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
    CIImage *image = [CIImage imageWithCVPixelBuffer:pixelBuffer];
    CIFilter *filter = [CIFilter filterWithName:@"CIColorInvert"];
    [filter setDefaults];
    [filter setValue:image forKey:kCIInputImageKey];
    CIImage *result = [filter outputImage];
    CGFloat scale = [[UIScreen mainScreen] scale];
    CGRect dest = CGRectMake(0, 0, self.view.frame.size.width*scale, self.view.frame.size.height*scale);
    [coreImageContext drawImage:result inRect:dest fromRect:[image extent]];
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)viewDidUnload
{
    [super viewDidUnload];

    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
  self.context = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc. that aren't in use.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

@end
