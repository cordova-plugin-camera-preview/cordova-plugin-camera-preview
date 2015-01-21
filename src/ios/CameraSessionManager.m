#include "CameraSessionManager.h"

@implementation CameraSessionManager

- (CameraSessionManager *)init
{
    if (self = [super init]) {
        // Create the AVCaptureSession
        self.session = [[AVCaptureSession alloc] init];
        self.sessionQueue = dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL);
        [self setCiFilter:nil];
    }
    return self;
}

- (void) setupSession:(NSString *)defaultCamera
{
    // If this fails, video input will just stream blank frames
    // and the user will be notified. User only has to accep once.
    [self checkDeviceAuthorizationStatus];

    dispatch_async(self.sessionQueue, ^{
        NSError *error = nil;

        NSLog(@"defaultCamera: %@", defaultCamera);
        if ([defaultCamera isEqual: @"front"]) {
            self.defaultCamera = AVCaptureDevicePositionFront;
        } else {
            self.defaultCamera = AVCaptureDevicePositionBack;
        }

        AVCaptureDevice *videoDevice = [CameraSessionManager deviceWithMediaType:AVMediaTypeVideo preferringPosition:self.defaultCamera];        
        AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];

        if (error) {
            NSLog(@"%@", error);
        }

        if ([self.session canAddInput:videoDeviceInput]) {
            [self.session addInput:videoDeviceInput];
            self.videoDeviceInput = videoDeviceInput;
        }

        AVCaptureStillImageOutput *stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
        if ([self.session canAddOutput:stillImageOutput]) {
            [stillImageOutput setOutputSettings:@{AVVideoCodecKey : AVVideoCodecJPEG}];
            [self.session addOutput:stillImageOutput];
            self.stillImageOutput = stillImageOutput;

            AVCaptureConnection *captureConnection = [self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
            if ([captureConnection isVideoOrientationSupported]) {
                [captureConnection setVideoOrientation:(AVCaptureVideoOrientation)[[UIApplication sharedApplication] statusBarOrientation]];
            }
        }

        AVCaptureVideoDataOutput *dataOutput = [[AVCaptureVideoDataOutput alloc] init];
        if ([self.session canAddOutput:dataOutput])
        {
            self.dataOutput = dataOutput;
            [dataOutput setAlwaysDiscardsLateVideoFrames:YES];
            [dataOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];

            [dataOutput setSampleBufferDelegate:self.delegate queue:self.sessionQueue];

            [self.session addOutput:dataOutput];

            AVCaptureConnection *captureConnection = [self.dataOutput connectionWithMediaType:AVMediaTypeVideo];
            if ([captureConnection isVideoOrientationSupported]) {
                [captureConnection setVideoOrientation:(AVCaptureVideoOrientation)[[UIApplication sharedApplication] statusBarOrientation]];
            }
        }
    });
}

- (void) switchCamera
{
    if (self.defaultCamera == AVCaptureDevicePositionFront) {
        self.defaultCamera = AVCaptureDevicePositionBack;
    } else {
        self.defaultCamera = AVCaptureDevicePositionFront;
    }

    dispatch_async([self sessionQueue], ^{
        NSError *error = nil;

        [self.session beginConfiguration];

        if (self.videoDeviceInput != nil) {
            [self.session removeInput:[self videoDeviceInput]];
        }

        AVCaptureDevice *videoDevice = [CameraSessionManager deviceWithMediaType:AVMediaTypeVideo preferringPosition:self.defaultCamera];
        AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];

        if (error) {
            NSLog(@"%@", error);
        }

        if ([self.session canAddInput:videoDeviceInput]) {
            [self.session addInput:videoDeviceInput];
            [self setVideoDeviceInput:videoDeviceInput];
        }

        AVCaptureConnection *captureConnection;
        if (self.stillImageOutput != nil) {
            captureConnection = [self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
            if ([captureConnection isVideoOrientationSupported]) {
                [captureConnection setVideoOrientation:(AVCaptureVideoOrientation)[[UIApplication sharedApplication] statusBarOrientation]];
            }
        }

        if (self.dataOutput != nil) {
            captureConnection = [self.dataOutput connectionWithMediaType:AVMediaTypeVideo];
            if ([captureConnection isVideoOrientationSupported]) {
                [captureConnection setVideoOrientation:(AVCaptureVideoOrientation)[[UIApplication sharedApplication] statusBarOrientation]];
            }
        }

        [self.session commitConfiguration];
    });
}

- (void)checkDeviceAuthorizationStatus
{
    NSString *mediaType = AVMediaTypeVideo;

    [AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL granted) {
        if (!granted) {
            //Not granted access to mediaType
            dispatch_async(dispatch_get_main_queue(), ^{
                [[[UIAlertView alloc] initWithTitle:@"Error"
                                            message:@"Camera permission not found. Please, check your privacy settings."
                                           delegate:self
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil] show];
            });
        }
    }];
}

+ (AVCaptureDevice *) deviceWithMediaType:(NSString *)mediaType preferringPosition:(AVCaptureDevicePosition)position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:mediaType];
    AVCaptureDevice *captureDevice = [devices firstObject];

    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) {
            captureDevice = device;
            break;
        }
    }

    return captureDevice;
}

@end
