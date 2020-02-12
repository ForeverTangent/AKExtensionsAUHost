//
//  BasicSynth2DSPKernelAdapter.m
//  BasicSynth2Framework
//
//  Created by Stanley Rosenbaum on 2/7/20.
//  Copyright © 2020 Apple. All rights reserved.
//

/*
 See LICENSE folder for this sample’s licensing information.

 Abstract:
 Adapter object providing a Swift-accessible interface to the filter's underlying DSP code.
 */

#import <AVFoundation/AVFoundation.h>
#import <CoreAudioKit/AUViewController.h>
#import "BasicSynth2DSPKernelAdapter.h"
#import "BasicSynth2DSPKernel.hpp"
#import "AUv3BufferedAudioBus.hpp"


@implementation BasicSynth2DSPKernelAdapter {
	// C++ members need to be ivars; they would be copied on access if they were properties.
	BasicSynth2DSPKernel _kernel;
	AUv3BufferedOutputBus _outputBusBuffer;
	AUAudioUnitBusArray *_outputBusArray;
	AUParameterTree *_parameterTree;
}


- (instancetype)init {

	NSLog(@"BasicSynth2DSPKernelAdapter init");

	if (self = [super init]) {

		NSLog(@"BasicSynth2DSPKernelAdapter self = [super init]");

		self.defaultFormat = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:44100 channels:2];
		// Create a DSP kernel to handle the signal processing.
		_kernel.init(self.defaultFormat.channelCount, self.defaultFormat.sampleRate);

		_kernel.setParameter(FilterCutoffFrequencyAddress, 11025.0);
		_kernel.setParameter(PulseWidthAddress, 0.5);

		_sampleRate = 44100.0;
		_numberOfOutputChannels = 2;

		_rampDuration = 0.0;

//		self.rampDuration = _rampDuration;

		_outputBusBuffer.init(self.defaultFormat, 2);
		self.outputBus = _outputBusBuffer.bus;

		// Create the input and output busses.
		_outputBus = [[AUAudioUnitBus alloc] initWithFormat:self.defaultFormat error:nil];
	}
	return self;
}

- (void)setKernel:(BasicSynth2DSPKernel) ptr {
	NSLog(@"Obj-C BasicSynth2DSPKernelAdapter setKernel");
	_kernel = ptr;
}

- (void)setParameter:(AUParameter *)parameter value:(AUValue)value {
	NSLog(@"Obj-C BasicSynth2DSPKernelAdapter setParameter");
	_kernel.setParameter(parameter.address, value);
}

- (AUValue)valueForParameter:(AUParameter *)parameter {
	return _kernel.getParameter(parameter.address);
}

- (AUAudioFrameCount)maximumFramesToRender {
	return _kernel.maximumFramesToRender();
}

- (void)setMaximumFramesToRender:(AUAudioFrameCount)maximumFramesToRender {
	_kernel.setMaximumFramesToRender(maximumFramesToRender);
}

- (void)allocateRenderResources {

	NSLog(@"BasicSynth2DSPKernelAdapter allocateRenderResources PLAIN");
	_outputBusBuffer.allocateRenderResources(self.maximumFramesToRender);
	_kernel.init(self.outputBus.format.channelCount, self.outputBus.format.sampleRate);
	_kernel.reset();
}

//- (BOOL)allocateRenderResourcesAndReturnError:(NSError **)outError {
//
//	NSLog(@"BasicSynth2DSPKernelAdapter allocateRenderResources BOOL ^^^");
//
////	if (![super allocateRenderResourcesAndReturnError:outError]) {
////		return NO;
////	}
//
//	_outputBusBuffer.allocateRenderResources(self.maximumFramesToRender);
//	_kernel.init(self.outputBus.format.channelCount, self.outputBus.format.sampleRate);
//	_kernel.reset();
//	return YES;
//}

- (void)deallocateRenderResources {
	NSLog(@"BasicSynth2DSPKernelAdapter deallocateRenderResources \\/");
	_kernel.destroy();
	_outputBusBuffer.deallocateRenderResources();
}

//- (void)stopNote:(uint8_t)note {
//	_kernel.stopNote(note);
//}
//
//- (void)startNote:(uint8_t)note velocity:(uint8_t)velocity {
//	_kernel.startNote(note, velocity);
//}
//
//- (void)startNote:(uint8_t)note velocity:(uint8_t)velocity frequency:(float)frequency {
//	_kernel.startNote(note, velocity, frequency);
//};

#pragma mark - AUAudioUnit (AUAudioUnitImplementation internalRenderBlock)

- (AUInternalRenderBlock)internalRenderBlock {
	__block BasicSynth2DSPKernel *state = &_kernel;
	__block AUv3BufferedOutputBus *outputBuffer = &_outputBusBuffer;
	return ^AUAudioUnitStatus(
							  AudioUnitRenderActionFlags *actionFlags,
							  const AudioTimeStamp       *timestamp,
							  AVAudioFrameCount           frameCount,
							  NSInteger                   outputBusNumber,
							  AudioBufferList            *outputData,
							  const AURenderEvent        *realtimeEventListHead,
							  AURenderPullInputBlock      pullInputBlock) {
		outputBuffer->prepareOutputBufferList(outputData, frameCount, true);
		state->setOutputBuffer(outputData);
		state->processWithEvents(timestamp, frameCount, realtimeEventListHead);
		return noErr;
	};
}

@end



