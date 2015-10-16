#import "DPAudio.h"


@class DPAudioOutput;


@protocol DPAudioOutputDataSource <NSObject>
@optional
- (void)    audioOutput:(DPAudioOutput*)audioOutput
callbackWithActionFlags:(AudioUnitRenderActionFlags*)ioActionFlags
            inTimeStamp:(const AudioTimeStamp*)inTimeStamp
            inBusNumber:(UInt32)inBusNumber
         inNumberFrames:(UInt32)inNumberFrames
                 ioData:(AudioBufferList*)ioData;
@end


@interface DPAudioOutput : NSObject

@property (nonatomic, weak) id<DPAudioOutputDataSource> dataSource;
- (instancetype)initWithDataSource:(id<DPAudioOutputDataSource>)dataSource;

@property (nonatomic) AudioStreamBasicDescription audioStreamBasicDescription;

@property (nonatomic, readonly, getter=isPlaying) BOOL playing;
- (void)startPlayback;
- (void)stopPlayback;

@end
