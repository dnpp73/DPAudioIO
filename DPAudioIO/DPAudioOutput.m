#import "DPAudioOutput.h"


#pragma mark - AudioUnit Callback function

static OSStatus OutputRenderCallback(void                       *inRefCon,
                                     AudioUnitRenderActionFlags *ioActionFlags,
                                     const AudioTimeStamp       *inTimeStamp,
                                     UInt32                     inBusNumber,
                                     UInt32                     inNumberFrames,
                                     AudioBufferList            *ioData)
{
    DPAudioOutput* audioOutput = (__bridge DPAudioOutput*)inRefCon;
    if ([audioOutput.dataSource respondsToSelector:@selector(audioOutput:callbackWithActionFlags:inTimeStamp:inBusNumber:inNumberFrames:ioData:)]) {
        [audioOutput.dataSource audioOutput:audioOutput
                    callbackWithActionFlags:ioActionFlags
                                inTimeStamp:inTimeStamp
                                inBusNumber:inBusNumber
                             inNumberFrames:inNumberFrames
                                     ioData:ioData];
    }
    return noErr;
}


@interface DPAudioOutput ()
{
    AudioUnit                   _outputUnit;
    AudioStreamBasicDescription _outputASBD;
    BOOL                        _isCustomASBD;
}
@property (nonatomic, readonly, getter=isConfigured) BOOL configured;
@end


@implementation DPAudioOutput

@synthesize playing    = _isPlaying;
@synthesize configured = _isConfigured;

#pragma mark - Initializer

- (void)dealloc
{
    if (_isConfigured) {
        [DPAudio checkResult:AudioOutputUnitStop(_outputUnit)
                   operation:"Failed to uninitialize output unit"];
        
        [DPAudio checkResult:AudioUnitUninitialize(_outputUnit)
                   operation:"Failed to uninitialize output unit"];
        
        [DPAudio checkResult:AudioComponentInstanceDispose(_outputUnit)
                   operation:"Failed to uninitialize output unit"];
    }
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self configureOutput];
    }
    return self;
}

- (instancetype)initWithDataSource:(id<DPAudioOutputDataSource>)dataSource
{
    self = [self init];
    if (self) {
        self.dataSource = dataSource;
    }
    return self;
}

#pragma mark - Execute

- (void)startPlayback
{
    if (_isConfigured) {
        if (!_isPlaying) {
            [DPAudio checkResult:AudioOutputUnitStart(_outputUnit)
                       operation:"Failed to start output unit"];
            _isPlaying = YES;
        }
    }
}

- (void)stopPlayback
{
    if (_isConfigured) {
        if (_isPlaying) {
            [DPAudio checkResult:AudioOutputUnitStop(_outputUnit)
                       operation:"Failed to stop output unit"];
            _isPlaying = NO;
        }
    }
}
#pragma mark - Accessor

- (AudioStreamBasicDescription)audioStreamBasicDescription
{
    return _outputASBD;
}

- (void)setAudioStreamBasicDescription:(AudioStreamBasicDescription)audioStreamBasicDescription
{
    BOOL wasPlaying = NO;
    if (_isPlaying) {
        [self stopPlayback];
        wasPlaying = YES;
    }
    _isCustomASBD = YES;
    _outputASBD = audioStreamBasicDescription;
    // Set the format for output
    [DPAudio checkResult:AudioUnitSetProperty(_outputUnit,
                                              kAudioUnitProperty_StreamFormat,
                                              kAudioUnitScope_Input,
                                              0,
                                              &_outputASBD,
                                              sizeof(_outputASBD))
               operation:"Couldn't set the ASBD for input scope/bos 0"];
    
    if(wasPlaying) {
        [self startPlayback];
    }
}

#pragma mark - Configure AudioUnit

#if TARGET_OS_IPHONE
- (void)configureOutput
{
    if (_isConfigured) {
        return;
    }
    
    AudioComponentDescription outputcd;
    outputcd.componentFlags        = 0;
    outputcd.componentFlagsMask    = 0;
    outputcd.componentManufacturer = kAudioUnitManufacturer_Apple;
    outputcd.componentSubType      = kAudioUnitSubType_RemoteIO;
    outputcd.componentType         = kAudioUnitType_Output;
    
    AudioComponent comp = AudioComponentFindNext(NULL, &outputcd);
    [DPAudio checkResult:AudioComponentInstanceNew(comp, &_outputUnit)
               operation:"Failed to get output unit"];
    
    UInt32           oneFlag = 1;
    AudioUnitElement bus0    = 0;
    [DPAudio checkResult:AudioUnitSetProperty(_outputUnit,
                                              kAudioOutputUnitProperty_EnableIO,
                                              kAudioUnitScope_Output,
                                              bus0,
                                              &oneFlag,
                                              sizeof(oneFlag))
               operation:"Failed to enable output unit"];
    
    Float64 hardwareSampleRate = 44100;
    #if !(TARGET_IPHONE_SIMULATOR)
    hardwareSampleRate = [[AVAudioSession sharedInstance] sampleRate];
    #endif

    _outputASBD = [DPAudio physicalOutputWithSampleRate:hardwareSampleRate];
    
    [DPAudio checkResult:AudioUnitSetProperty(_outputUnit,
                                              kAudioUnitProperty_StreamFormat,
                                              kAudioUnitScope_Input,
                                              bus0,
                                              &_outputASBD,
                                              sizeof(_outputASBD))
               operation:"Couldn't set the ASBD for input scope/bos 0"];
    
    AURenderCallbackStruct input;
    input.inputProc = OutputRenderCallback;
    input.inputProcRefCon = (__bridge void *)self;
    [DPAudio checkResult:AudioUnitSetProperty(_outputUnit,
                                              kAudioUnitProperty_SetRenderCallback,
                                              kAudioUnitScope_Input,
                                              bus0,
                                              &input,
                                              sizeof(input))
               operation:"Failed to set the render callback on the output unit"];
    
    [DPAudio checkResult:AudioUnitInitialize(_outputUnit)
               operation:"Couldn't initialize output unit"];
    
    _isConfigured = YES;
}
#elif TARGET_OS_MAC
- (void)configureOutput
{
    if (_isConfigured) {
        return;
    }
    
    AudioComponentDescription outputcd;
    outputcd.componentType         = kAudioUnitType_Output;
    outputcd.componentSubType      = kAudioUnitSubType_DefaultOutput;
    outputcd.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    AudioComponent comp = AudioComponentFindNext(NULL,&outputcd);
    if (comp == NULL) {
        NSLog(@"Failed to get output unit");
        exit(-1);
    }
    [DPAudio checkResult:AudioComponentInstanceNew(comp,&_outputUnit)
               operation:"Failed to open component for output unit"];
    
    _outputASBD = [DPAudio physicalOutputWithSampleRate:44100];
    
    [DPAudio checkResult:AudioUnitSetProperty(_outputUnit,
                                              kAudioUnitProperty_StreamFormat,
                                              kAudioUnitScope_Input,
                                              0,
                                              &_outputASBD,
                                              sizeof(_outputASBD))
               operation:"Couldn't set the ASBD for input scope/bos 0"];
    
    AURenderCallbackStruct input;
    input.inputProc = OutputRenderCallback;
    input.inputProcRefCon = (__bridge void *)(self);
    [DPAudio checkResult:AudioUnitSetProperty(_outputUnit,
                                              kAudioUnitProperty_SetRenderCallback,
                                              kAudioUnitScope_Input,
                                              0,
                                              &input,
                                              sizeof(input))
               operation:"Failed to set the render callback on the output unit"];
    
    [DPAudio checkResult:AudioUnitInitialize(_outputUnit)
               operation:"Couldn't initialize output unit"];
    
    _isConfigured = YES;
}
#endif

@end
