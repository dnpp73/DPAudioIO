#import "DPAudio.h"


@class DPAudioInput;


@protocol DPAudioInputDelegate <NSObject>
@optional
- (void)audioInput:(DPAudioInput*)audioInput
     hasBufferList:(AudioBufferList*)bufferList
        bufferSize:(UInt32)bufferSize
  numberOfChannels:(UInt32)numberOfChannels;
@end


@interface DPAudioInput : NSObject

@property (nonatomic, weak) id<DPAudioInputDelegate> delegate;
- (instancetype)initWithDelegate:(id<DPAudioInputDelegate>)delegate;

@property (nonatomic) AudioStreamBasicDescription streamFormat;
@property (nonatomic, readonly) UInt32 deviceBufferFrameSize;

@property (nonatomic, readonly, getter=isFetchingAudio) BOOL fetchingAudio;
- (void)startFetchingAudio;
- (void)stopFetchingAudio;

@end
