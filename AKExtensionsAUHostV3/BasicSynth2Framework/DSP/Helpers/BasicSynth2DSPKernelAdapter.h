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
@property AUAudioUnitBusArray * _Nonnull outputBusArray;

@property AVAudioFormat * _Nonnull defaultFormat;

@property (readonly) BOOL isPlaying;
@property (readonly) BOOL isSetUp;

@property double rampDuration;

//- (void)startNote:(uint8_t)note velocity:(uint8_t)velocity;
//- (void)startNote:(uint8_t)note velocity:(uint8_t)velocity frequency:(float)frequency;
//- (void)stopNote:(uint8_t)note;

- (void)setParameter:(AUParameter *)parameter value:(AUValue)value;
- (AUValue)valueForParameter:(AUParameter *)parameter;

- (void)allocateRenderResources;
- (void)deallocateRenderResources;
- (AUInternalRenderBlock)internalRenderBlock;

@end

NS_ASSUME_NONNULL_END

//@interface AUParameter(BasicSynth2)
//
//+(_Nonnull instancetype)parameterWithIdentifier:(NSString * _Nonnull)identifier
//										   name:(NSString * _Nonnull)name
//										address:(AUParameterAddress)address
//											min:(AUValue)min
//											max:(AUValue)max
//										   unit:(AudioUnitParameterUnit)unit
//										  flags:(AudioUnitParameterOptions)flags;
//
//+(_Nonnull instancetype)parameterWithIdentifier:(NSString * _Nonnull)identifier
//										   name:(NSString * _Nonnull)name
//										address:(AUParameterAddress)address
//											min:(AUValue)min
//											max:(AUValue)max
//										   unit:(AudioUnitParameterUnit)unit;
//@end
//
//@interface AUParameterTree(BasicSynth2)
//+(_Nonnull instancetype)treeWithChildren:(NSArray<AUParameter *> * _Nonnull)children;
//@end
