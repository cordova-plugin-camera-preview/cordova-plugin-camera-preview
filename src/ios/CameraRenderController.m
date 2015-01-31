#import "CameraRenderController.h"

@implementation CameraRenderController
@synthesize context = _context;
@synthesize delegate;

- (CameraRenderController *)init {
    if (self = [super init]) {
        self.renderLock = [[NSLock alloc] init];
    }
    return self;
}

- (void)loadView {
    GLKView *glkView = [[GLKView alloc] init];
    [glkView setBackgroundColor:[UIColor blackColor]];
    [self setView:glkView];
}

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

    self.ciContext = [CIContext contextWithEAGLContext:self.context]; 

    if (self.dragEnabled) {
        //add drag action listener
        NSLog(@"Enabling view dragging");
        UIPanGestureRecognizer *drag = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self.view addGestureRecognizer:drag];
    }

    if (self.tapToTakePicture) {
        //tap to take picture
        UITapGestureRecognizer *takePictureTap =
        [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTakePictureTap:)];
        [self.view addGestureRecognizer:takePictureTap];
    }

    self.view.userInteractionEnabled = self.dragEnabled || self.tapToTakePicture;
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [[NSNotificationCenter defaultCenter] addObserver:self 
        selector:@selector(appplicationIsActive:) 
        name:UIApplicationDidBecomeActiveNotification 
        object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self 
        selector:@selector(applicationEnteredForeground:) 
        name:UIApplicationWillEnterForegroundNotification
        object:nil];

    dispatch_async(self.sessionManager.sessionQueue, ^{
      NSLog(@"Starting session");
      [self.sessionManager.session startRunning];
    });
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [[NSNotificationCenter defaultCenter] removeObserver:self
        name:UIApplicationDidBecomeActiveNotification
        object:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self
        name:UIApplicationWillEnterForegroundNotification
        object:nil];

    dispatch_async(self.sessionManager.sessionQueue, ^{
      NSLog(@"Stopping session");
      [self.sessionManager.session stopRunning];
    });
}

- (void) handleTakePictureTap:(UITapGestureRecognizer*)recognizer {
    NSLog(@"handleTakePictureTap");
    [self.delegate invokeTakePicture];
}

- (IBAction)handlePan:(UIPanGestureRecognizer *)recognizer {
    CGPoint translation = [recognizer translationInView:self.view];
    recognizer.view.center = CGPointMake(recognizer.view.center.x + translation.x, 
                                     recognizer.view.center.y + translation.y);
    [recognizer setTranslation:CGPointMake(0, 0) inView:self.view];
}

- (void) appplicationIsActive:(NSNotification *)notification {
    dispatch_async(self.sessionManager.sessionQueue, ^{
      NSLog(@"Starting session");
      [self.sessionManager.session startRunning];
    });
}

- (void) applicationEnteredForeground:(NSNotification *)notification {
    dispatch_async(self.sessionManager.sessionQueue, ^{
      NSLog(@"Stopping session");
      [self.sessionManager.session stopRunning];
    });
}

-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    if ([self.renderLock tryLock]) {
        CVPixelBufferRef pixelBuffer = (CVPixelBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
        CIImage *image = [CIImage imageWithCVPixelBuffer:pixelBuffer];

        CGFloat scaleHeight = self.view.frame.size.height/image.extent.size.height;
        CGFloat scaleWidth = self.view.frame.size.width/image.extent.size.width;
        CGFloat scale  = scaleHeight < scaleWidth ? scaleWidth : scaleHeight;

        CIFilter *resizeFilter = [CIFilter filterWithName:@"CILanczosScaleTransform"];
        [resizeFilter setValue:image forKey:kCIInputImageKey];
        [resizeFilter setValue:[NSNumber numberWithFloat:1.0f] forKey:@"inputAspectRatio"];
        [resizeFilter setValue:[NSNumber numberWithFloat:scale] forKey:@"inputScale"];
        CIImage *scaledImage = [resizeFilter outputImage];

        CIFilter *cropFilter = [CIFilter filterWithName:@"CICrop"];
        CIVector *cropRect = [CIVector vectorWithX:0 Y:0 Z:self.view.frame.size.width W:self.view.frame.size.height];
        [cropFilter setValue:scaledImage forKey:kCIInputImageKey];
        [cropFilter setValue:cropRect forKey:@"inputRectangle"];
        CIImage *croppedImage = [cropFilter outputImage];

        CIFilter *filter = [self.sessionManager ciFilter];

        CIImage *result;
        if (filter != nil) {
            [self.sessionManager.filterLock lock];
            [filter setValue:croppedImage forKey:kCIInputImageKey];
            result = [filter outputImage];
            [self.sessionManager.filterLock unlock];
        } else {
            result = croppedImage;
        }

        self.latestFrame = result;

        CGFloat pointScale = [[UIScreen mainScreen] scale];
        CGRect dest = CGRectMake(0, 0, self.view.frame.size.width*pointScale, self.view.frame.size.height*pointScale);

        [self.ciContext drawImage:result inRect:dest fromRect:[result extent]];
        [self.context presentRenderbuffer:GL_RENDERBUFFER];
        [(GLKView *)(self.view) display];
        [self.renderLock unlock];
    }
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

- (BOOL)shouldAutorotate {
    return NO;
}

@end
