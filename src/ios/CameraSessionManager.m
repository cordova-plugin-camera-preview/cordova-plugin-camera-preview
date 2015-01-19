#include "CameraSessionManager.h"

@implementation CameraSessionManager

- (CameraSessionManager *) init:(NSString *)defaultCamera
{
    // If this fails, video input will just stream blank frames
    // and the user will be notified. User only has to accep once.
    [self checkDeviceAuthorizationStatus];

    // Create the AVCaptureSession
    self.session = [[AVCaptureSession alloc] init];
    self.sessionQueue = dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL);
    self.defaultCamera = defaultCamera;
    [self setCiFilter:nil];

    dispatch_async(self.sessionQueue, ^{
        NSError *error = nil;

        NSLog(@"defaultCamera: %@", self.defaultCamera);
        AVCaptureDevicePosition position = AVCaptureDevicePositionUnspecified;
        if ([self.defaultCamera isEqual: @"front"]) {
            position = AVCaptureDevicePositionFront;
        } else {
            position = AVCaptureDevicePositionBack;
        }

        AVCaptureDevice *videoDevice = [CameraSessionManager deviceWithMediaType:AVMediaTypeVideo preferringPosition:position];        
        AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];

        if (error) {
            NSLog(@"%@", error);
        }

        if ([self.session canAddInput:videoDeviceInput]) {
            [self.session addInput:videoDeviceInput];
        }
    });

    return self;
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
