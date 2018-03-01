#import "CameraRenderController.h"
#import <CoreVideo/CVOpenGLESTextureCache.h>
#import <GLKit/GLKit.h>
#import <OpenGLES/ES2/glext.h>

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
  [glkView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
  [self setView:glkView];
}

- (void)viewDidLoad {
  [super viewDidLoad];

  self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];

  if (!self.context) {
    NSLog(@"Failed to create ES context");
  }

  CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, self.context, NULL, &_videoTextureCache);
  if (err) {
    NSLog(@"Error at CVOpenGLESTextureCacheCreate %d", err);
    return;
  }

  GLKView *view = (GLKView *)self.view;
  view.context = self.context;
  view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
  view.contentMode = UIViewContentModeScaleToFill;

  glGenRenderbuffers(1, &_renderBuffer);
  glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);

  self.ciContext = [CIContext contextWithEAGLContext:self.context];

  if (self.dragEnabled) {
    //add drag action listener
    NSLog(@"Enabling view dragging");
    UIPanGestureRecognizer *drag = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [self.view addGestureRecognizer:drag];
  }

  if (self.tapToFocus && self.tapToTakePicture){
    //tap to focus and take picture
    UITapGestureRecognizer *tapToFocusAndTakePicture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector (handleFocusAndTakePictureTap:)];
    [self.view addGestureRecognizer:tapToFocusAndTakePicture];

  } else if (self.tapToFocus){
    // tap to focus
    UITapGestureRecognizer *tapToFocusGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector (handleFocusTap:)];
    [self.view addGestureRecognizer:tapToFocusGesture];

  } else if (self.tapToTakePicture) {
    //tap to take picture
    UITapGestureRecognizer *takePictureTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTakePictureTap:)];
    [self.view addGestureRecognizer:takePictureTap];
  }

  self.view.userInteractionEnabled = self.dragEnabled || self.tapToTakePicture || self.tapToFocus;
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
      
      if (!self.sessionManager.session.running){
          NSLog(@"Starting session from viewWillAppear");
          [self.sessionManager.session startRunning];
      }
      
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

- (void) handleFocusAndTakePictureTap:(UITapGestureRecognizer*)recognizer {
  NSLog(@"handleFocusAndTakePictureTap");

  // let the delegate take an image, the next time the image is in focus.
  [self.delegate invokeTakePictureOnFocus];

  // let the delegate focus on the tapped point.
  [self handleFocusTap:recognizer];
}

- (void) handleTakePictureTap:(UITapGestureRecognizer*)recognizer {
  NSLog(@"handleTakePictureTap");
  [self.delegate invokeTakePicture];
}

- (void) handleFocusTap:(UITapGestureRecognizer*)recognizer {
  NSLog(@"handleTapFocusTap");

  if (recognizer.state == UIGestureRecognizerStateEnded)    {
    CGPoint point = [recognizer locationInView:self.view];
    [self.delegate invokeTapToFocus:point];
  }
}

- (void) onFocus{
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
      
      if (!self.sessionManager.session.running){
          NSLog(@"Starting session");
          [self.sessionManager.session startRunning];
      }
      
      });
}

- (void) applicationEnteredForeground:(NSNotification *)notification {
  dispatch_async(self.sessionManager.sessionQueue, ^{
      NSLog(@"Stopping session");
      [self.sessionManager.session stopRunning];
      });
}

-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    }
        
        
    }
}

- (void)viewDidUnload {
  [super viewDidUnload];

  if ([EAGLContext currentContext] == self.context) {
    [EAGLContext setCurrentContext:nil];
  }
  self.context = nil;
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Release any cached data, images, etc. that aren't in use.
}

- (BOOL)shouldAutorotate {
  return YES;
}

-(void) willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
  [self.sessionManager updateOrientation:[self.sessionManager getCurrentOrientation:toInterfaceOrientation]];
}

@end
