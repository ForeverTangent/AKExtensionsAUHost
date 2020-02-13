//
//  BasicSynth2DSPKernelAdapter.h
//  BasicSynth2
//
//  Created by Stanley Rosenbaum on 2/6/20.
//  Copyright © 2020 Apple. All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>

@class BasicSynth2AudioUnitViewController;

NS_ASSUME_NONNULL_BEGIN

@interface BasicSynth2DSPKernelAdapter: NSObject

@property double sampleRate;
@property double numberOfOutputChannels;

@property (nonatomic) AUAudioFrameCount maximumFramesToRender;

@property AUAudioUnitBus * _Nonnull outputBus;
@property AVAudioFormat * _Nonnull defaultFormat;

@property (readonly) BOOL isPlaying;
@property (readonly) BOOL isSetUp;

@property double rampDuration;

- (void)setParameter:(AUParameter *)parameter value:(AUValue)value;
- (AUValue)valueForParameter:(AUParameter *)parameter;

- (void)allocateRenderResources;
- (void)deallocateRenderResources;
- (AUInternalRenderBlock)internalRenderBlock;

@end

NS_ASSUME_NONNULL_END

