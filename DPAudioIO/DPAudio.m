#import "DPAudio.h"


@implementation DPAudio

#pragma mark - OSStatus Utility

+ (void)checkResult:(OSStatus)result operation:(const char *)operation
{
    if (result == noErr) {
        return;
    }
    
    char errorString[20];
    // see if it appears to be a 4-char-code
    *(UInt32 *)(errorString + 1) = CFSwapInt32HostToBig(result);
    if (isprint(errorString[1]) && isprint(errorString[2]) && isprint(errorString[3]) && isprint(errorString[4])) {
        errorString[0] = errorString[5] = '\'';
        errorString[6] = '\0';
    }
    else {
        // no, format it as an integer
        sprintf(errorString, "%d", (int)result);
    }
    fprintf(stderr, "Error: %s (%s)\n", operation, errorString);
    exit(1);
}

#pragma mark - AudioStreamBasicDescription

+ (AudioStreamBasicDescription)physicalInputWithSampleRate:(float)sampleRate
{
    UInt32 byteSize = sizeof(SInt16);
    AudioStreamBasicDescription asbd;
    asbd.mSampleRate       = sampleRate;
    asbd.mFormatID         = kAudioFormatLinearPCM;
    asbd.mFormatFlags      = kAudioFormatFlagIsPacked | kAudioFormatFlagIsSignedInteger;
    asbd.mBytesPerPacket   = byteSize;
    asbd.mFramesPerPacket  = 1;
    asbd.mBytesPerFrame    = byteSize;
    asbd.mChannelsPerFrame = 1;
    asbd.mBitsPerChannel   = 8 * byteSize;
    return asbd;
}

+ (AudioStreamBasicDescription)physicalOutputWithSampleRate:(float)sampleRate
{
    UInt32 byteSize = sizeof(Float32);
    AudioStreamBasicDescription asbd;
    asbd.mSampleRate       = sampleRate;
    asbd.mFormatID         = kAudioFormatLinearPCM;
    asbd.mFormatFlags      = kAudioFormatFlagsNativeFloatPacked | kAudioFormatFlagIsNonInterleaved;
    asbd.mBytesPerPacket   = byteSize;
    asbd.mFramesPerPacket  = 1;
    asbd.mBytesPerFrame    = byteSize;
    asbd.mChannelsPerFrame = 2;
    asbd.mBitsPerChannel   = 8 * byteSize;
    return asbd;
}

@end
