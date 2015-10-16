#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#if TARGET_OS_IPHONE
#import <AVFoundation/AVAudioSession.h>
#elif TARGET_OS_MAC
#import <AudioUnit/AudioUnit.h>
#endif


@interface DPAudio : NSObject

+ (void)checkResult:(OSStatus)result operation:(const char *)operation;

+ (AudioStreamBasicDescription)physicalInputWithSampleRate:(float)sampleRate;
+ (AudioStreamBasicDescription)physicalOutputWithSampleRate:(float)sampleRate;

@end
