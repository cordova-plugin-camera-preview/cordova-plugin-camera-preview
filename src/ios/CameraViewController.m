#import "CameraViewController.h"
#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>


static void * CapturingStillImageContext = &CapturingStillImageContext;
static void * SessionRunningAndDeviceAuthorizedContext = &SessionRunningAndDeviceAuthorizedContext;

@implementation CameraViewController

- (BOOL)isSessionRunningAndDeviceAuthorized
{
    return [[self session] isRunning] && [self isDeviceAuthorized];
}

+ (NSSet *)keyPathsForValuesAffectingSessionRunningAndDeviceAuthorized
{
    return [NSSet setWithObjects:@"session.running", @"deviceAuthorized", nil];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	return self;
}
- (BOOL)disablesAutomaticKeyboardDismissal {
    return NO;
}
- (void)addInterations {
    
    if(self.dragEnabled){
        //add drag action listener
        UIPanGestureRecognizer *drag = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panPiece:)];
        [self.view addGestureRecognizer:drag];
    }
    
    if(self.tapToTakePicture){
        NSLog(@"tapToTakePicture");
        //tap to take picture
        UITapGestureRecognizer *takePictureTap =
        [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTakePictureTap:)];
        [self.view addGestureRecognizer:takePictureTap];
    }
    
    if(self.dragEnabled || self.tapToTakePicture){
       self.view.userInteractionEnabled = YES;
    }
    else{
        self.view.userInteractionEnabled = NO;
    }
}
-(void) handleTakePictureTap:(UITapGestureRecognizer*)recognizer {
    NSLog(@"handleTakePictureTap");
    [self.delegate didTookPictureAction];
}
- (void)viewDidLoad{
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor clearColor];

     // Check for device authorization
     [self checkDeviceAuthorizationStatus];
     
     dispatch_queue_t sessionQueue = dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL);
     [self setSessionQueue:sessionQueue];
     
     dispatch_async(sessionQueue, ^{
        [self setBackgroundRecordingID:UIBackgroundTaskInvalid];
        
        NSError *error = nil;
        
		// Initial camera face
         NSLog(@"defaultCamera: %@", self.defaultCamera);
		AVCaptureDevicePosition position = AVCaptureDevicePositionUnspecified;
        if ([self.defaultCamera  isEqual: @"front"]){
            position = AVCaptureDevicePositionFront;
        }
        else{
            position = AVCaptureDevicePositionBack;
        }
			
        AVCaptureDevice *videoDevice = [CameraViewController deviceWithMediaType:AVMediaTypeVideo preferringPosition:position];
        AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
        
        if (error){
            NSLog(@"%@", error);
        }
        
        if ([self.session canAddInput:videoDeviceInput])
        {
            [self.session addInput:videoDeviceInput];
            [self setVideoDeviceInput:videoDeviceInput];
        }
        
        AVCaptureStillImageOutput *stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
        if ([self.session canAddOutput:stillImageOutput])
        {
            [stillImageOutput setOutputSettings:@{AVVideoCodecKey : AVVideoCodecJPEG}];
            [self.session addOutput:stillImageOutput];
            [self setStillImageOutput:stillImageOutput];
        }
    });
    
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Camera not found!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alertView show];
    }
}

- (void)viewDidAppear:(BOOL)animated{
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
}

- (void)panPiece:(UIPanGestureRecognizer *)gestureRecognizer{
    
    UIView *piece = [gestureRecognizer view];

    [self adjustAnchorPointForGestureRecognizer:gestureRecognizer];

    if ([gestureRecognizer state] == UIGestureRecognizerStateBegan || [gestureRecognizer state] == UIGestureRecognizerStateChanged) {
        
        CGPoint translation = [gestureRecognizer translationInView:[piece superview]];

        [piece setCenter:CGPointMake([piece center].x + translation.x, [piece center].y + translation.y)];
        
        [gestureRecognizer setTranslation:CGPointZero inView:[piece superview]];
        
    }
    
}
- (void)adjustAnchorPointForGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer

{
    
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        
        UIView *piece = gestureRecognizer.view;
        
        CGPoint locationInView = [gestureRecognizer locationInView:piece];
        
        CGPoint locationInSuperview = [gestureRecognizer locationInView:piece.superview];
        
        
        
        piece.layer.anchorPoint = CGPointMake(locationInView.x / piece.bounds.size.width, locationInView.y / piece.bounds.size.height);
        
        piece.center = locationInSuperview;
        
    }
    
}
- (void)viewDidDisappear:(BOOL)animated {
    
    dispatch_async([self sessionQueue], ^{
        [[self session] stopRunning];
        
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureDeviceSubjectAreaDidChangeNotification object:[[self videoDeviceInput] device]];
        [[NSNotificationCenter defaultCenter] removeObserver:[self runtimeErrorHandlingObserver]];
        
        [self removeObserver:self forKeyPath:@"sessionRunningAndDeviceAuthorized" context:SessionRunningAndDeviceAuthorizedContext];
        [self removeObserver:self forKeyPath:@"stillImageOutput.capturingStillImage" context:CapturingStillImageContext];
        
    });
}
- (void)viewWillAppear:(BOOL)animated {
    dispatch_async([self sessionQueue], ^{
        [self addObserver:self forKeyPath:@"sessionRunningAndDeviceAuthorized" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:SessionRunningAndDeviceAuthorizedContext];
        [self addObserver:self forKeyPath:@"stillImageOutput.capturingStillImage" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:CapturingStillImageContext];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subjectAreaDidChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:[[self videoDeviceInput] device]];
        
        __weak CameraViewController *weakSelf = self;
        [self setRuntimeErrorHandlingObserver:[[NSNotificationCenter defaultCenter] addObserverForName:AVCaptureSessionRuntimeErrorNotification object:[self session] queue:nil usingBlock:^(NSNotification *note) {
            CameraViewController *strongSelf = weakSelf;
            dispatch_async([strongSelf sessionQueue], ^{
                // Manually restarting the session since it must have been stopped due to an error.
                [[strongSelf session] startRunning];
                
            });
        }]];
        
        NSLog(@"startRunning");
        [[self session] startRunning];
    });
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == SessionRunningAndDeviceAuthorizedContext)
    {
        BOOL isRunning = [change[NSKeyValueChangeNewKey] boolValue];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (isRunning) {
                //setEnabled:YES
            }
            else {
                //setEnabled:NO
            }
        });
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}


- (void)takePicture:(void(^)(NSString*, NSString*))callback {
    dispatch_async([self sessionQueue], ^{
        // Update the orientation on the still image output video connection before capturing.
        [[[self stillImageOutput] connectionWithMediaType:AVMediaTypeVideo] setVideoOrientation:(AVCaptureVideoOrientation)[self interfaceOrientation]];
        
        // Flash set to Auto for Still Capture
        [CameraViewController setFlashMode:AVCaptureFlashModeAuto forDevice:[[self videoDeviceInput] device]];
        
        // Capture a still image.
        [[self stillImageOutput] captureStillImageAsynchronouslyFromConnection:[[self stillImageOutput] connectionWithMediaType:AVMediaTypeVideo] completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
            
            if (imageDataSampleBuffer){
                
                NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
                UIImage *image = [[UIImage alloc] initWithData:imageData];
                
                AVCaptureDevice *currentVideoDevice = [[self videoDeviceInput] device];
                
                //fix front mirroring
                if ([currentVideoDevice position] == AVCaptureDevicePositionFront) {
                     UIImage *flippedImage = [UIImage imageWithCGImage:image.CGImage scale:image.scale orientation:UIImageOrientationLeftMirrored];
                    [self.libraryImageView setImage:flippedImage];
                }
                else{
                    [self.libraryImageView setImage:image];
                }
				
				//final picture callback
                UIImage *finalPicture = [self imageWithView:self.finalImageView];
                [self.libraryImageView setImage:NULL];
                
                ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
                
                dispatch_group_t group = dispatch_group_create();
                
                __block NSString *originalPicturePath;
                __block NSString *previewPicturePath;
                
                //task 1
                dispatch_group_enter(group);
                [library writeImageToSavedPhotosAlbum:[finalPicture CGImage] orientation:(ALAssetOrientation)[finalPicture imageOrientation] completionBlock:^(NSURL *assetURL, NSError *error) {
                     if (error) {
                         NSLog(@"FAILED to save Preview picture.");
                     }
                     else {
                         previewPicturePath = [assetURL absoluteString];
                         NSLog(@"previewPicturePath: %@", previewPicturePath);
                         dispatch_group_leave(group);
                    }
                }];
                
                //task 2
                dispatch_group_enter(group);
                [library writeImageToSavedPhotosAlbum:[image CGImage] orientation:(ALAssetOrientation)[image imageOrientation] completionBlock:^(NSURL *assetURL, NSError *error) {
                    if (error) {
                        NSLog(@"FAILED to save Original picture.");
                    }
                    else {
                        originalPicturePath = [assetURL absoluteString];
                        NSLog(@"originalPicturePath: %@", originalPicturePath);
                    }
                    dispatch_group_leave(group);
                }];
                
                dispatch_group_notify(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                    NSLog(@"All pictures was saved!");
                    callback(originalPicturePath, previewPicturePath);
                });
            }
        }];
    });
   
}

- (void)subjectAreaDidChange:(NSNotification *)notification
{
    CGPoint devicePoint = CGPointMake(.5, .5);
    [self focusWithMode:AVCaptureFocusModeContinuousAutoFocus exposeWithMode:AVCaptureExposureModeContinuousAutoExposure atDevicePoint:devicePoint monitorSubjectAreaChange:NO];
}

#pragma mark Device Configuration

- (void)focusWithMode:(AVCaptureFocusMode)focusMode exposeWithMode:(AVCaptureExposureMode)exposureMode atDevicePoint:(CGPoint)point monitorSubjectAreaChange:(BOOL)monitorSubjectAreaChange
{
    dispatch_async([self sessionQueue], ^{
        AVCaptureDevice *device = [[self videoDeviceInput] device];
        NSError *error = nil;
        if ([device lockForConfiguration:&error])
        {
            if ([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:focusMode])
            {
                [device setFocusMode:focusMode];
                [device setFocusPointOfInterest:point];
            }
            if ([device isExposurePointOfInterestSupported] && [device isExposureModeSupported:exposureMode])
            {
                [device setExposureMode:exposureMode];
                [device setExposurePointOfInterest:point];
            }
            [device setSubjectAreaChangeMonitoringEnabled:monitorSubjectAreaChange];
            [device unlockForConfiguration];
        }
        else
        {
            NSLog(@"%@", error);
        }
    });
}

+ (void)setFlashMode:(AVCaptureFlashMode)flashMode forDevice:(AVCaptureDevice *)device
{
    if ([device hasFlash] && [device isFlashModeSupported:flashMode])
    {
        NSError *error = nil;
        if ([device lockForConfiguration:&error])
        {
            [device setFlashMode:flashMode];
            [device unlockForConfiguration];
        }
        else
        {
            NSLog(@"%@", error);
        }
    }
}

+ (AVCaptureDevice *)deviceWithMediaType:(NSString *)mediaType preferringPosition:(AVCaptureDevicePosition)position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:mediaType];
    AVCaptureDevice *captureDevice = [devices firstObject];
    
    for (AVCaptureDevice *device in devices)
    {
        if ([device position] == position)
        {
            captureDevice = device;
            break;
        }
    }
    
    return captureDevice;
}

#pragma mark UI

- (void)checkDeviceAuthorizationStatus
{
    NSString *mediaType = AVMediaTypeVideo;
    
    [AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL granted) {
        if (granted)
        {
            //Granted access to mediaType
            [self setDeviceAuthorized:YES];
        }
        else
        {
            //Not granted access to mediaType
            dispatch_async(dispatch_get_main_queue(), ^{
                [[[UIAlertView alloc] initWithTitle:@"Error"
                                            message:@"Camera permission not found. Please, check your privacy settings."
                                           delegate:self
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil] show];
                [self setDeviceAuthorized:NO];
            });
        }
    }];
}

-(void) hideCamera {
    [self.view setHidden:TRUE];
}
-(void) showCamera {
    [self.view setHidden:FALSE];
}
-(void) stopCamera {
    [self dismissViewControllerAnimated:NO completion:nil];
    [self.view removeFromSuperview];
}

-(void) switchCamera {

    //setEnabled:NO
    
    dispatch_async([self sessionQueue], ^{
        AVCaptureDevice *currentVideoDevice = [[self videoDeviceInput] device];
        AVCaptureDevicePosition preferredPosition = AVCaptureDevicePositionUnspecified;
        AVCaptureDevicePosition currentPosition = [currentVideoDevice position];
        
        switch (currentPosition)
        {
            case AVCaptureDevicePositionUnspecified:
                preferredPosition = AVCaptureDevicePositionBack;
                break;
            case AVCaptureDevicePositionBack:
                preferredPosition = AVCaptureDevicePositionFront;
                break;
            case AVCaptureDevicePositionFront:
                preferredPosition = AVCaptureDevicePositionBack;
                break;
        }

        AVCaptureDevice *videoDevice = [CameraViewController deviceWithMediaType:AVMediaTypeVideo preferringPosition:preferredPosition];
        AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:nil];
        
        [[self session] beginConfiguration];
        
        [[self session] removeInput:[self videoDeviceInput]];
        if ([[self session] canAddInput:videoDeviceInput])
        {
            [[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureDeviceSubjectAreaDidChangeNotification object:currentVideoDevice];
            
            [CameraViewController setFlashMode:AVCaptureFlashModeAuto forDevice:videoDevice];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subjectAreaDidChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:videoDevice];
            
            [[self session] addInput:videoDeviceInput];
            [self setVideoDeviceInput:videoDeviceInput];
        }
        else {
            [[self session] addInput:[self videoDeviceInput]];
        }
        
        [[self session] commitConfiguration];
        
        //dispatch_async(dispatch_get_main_queue(), ^{
            //setEnabled:YES
        //});
    });

}


#define rad(angle) ((angle) / 180.0 * M_PI)
- (CGAffineTransform)orientationTransformedRectOfImage:(UIImage *)img {
    CGAffineTransform rectTransform;
    switch (img.imageOrientation)
    {
        case UIImageOrientationLeft:
            rectTransform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(rad(90)), 0, -img.size.height);
            break;
        case UIImageOrientationRight:
            rectTransform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(rad(-90)), -img.size.width, 0);
            break;
        case UIImageOrientationDown:
            rectTransform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(rad(-180)), -img.size.width, -img.size.height);
            break;
        default:
            rectTransform = CGAffineTransformIdentity;
    };
    
    return CGAffineTransformScale(rectTransform, img.scale, img.scale);
}

-(UIImage *)croppedImage:(UIImage*)originalImage InRect:(CGRect)visibleRect{
    //transform visible rect to image orientation
    CGAffineTransform rectTransform = [self orientationTransformedRectOfImage:originalImage];
    visibleRect = CGRectApplyAffineTransform(visibleRect, rectTransform);
    
    //crop image
    CGImageRef imageRef = CGImageCreateWithImageInRect([originalImage CGImage], visibleRect);
    UIImage *result = [UIImage imageWithCGImage:imageRef scale:originalImage.scale orientation:originalImage.imageOrientation];
    CGImageRelease(imageRef);
    return result;
}


-(UIImage *)imageWithView:(UIView *)view{
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.opaque, 0.0);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage * img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

@end
