#import <AVFoundation/AVFoundation.h>

@interface TemperatureAndTint: NSObject

@property (nonatomic) NSString* mode;
@property (nonatomic) float minTemperature;
@property (nonatomic) float maxTemperature;
@property (nonatomic) float tint;

@end
