//
//  BasicSynth2DSPKernel.hpp
//  BasicSynth2
//
//  Created by Stanley Rosenbaum on 2/6/20.
//  Copyright © 2020 Apple. All rights reserved.
//

#ifndef BasicSynth2DSPKernel_hpp
#define BasicSynth2DSPKernel_hpp

#import <AudioKit/AudioKit.h>
#import "AUv3DSPKernel.hpp"
#import "AUv3ParameterRamper.hpp"

#include <iostream>

enum {
	AttackDurationAddress = 0,
	DecayDurationAddress,
	SustainLevelAddress,
	ReleaseDurationAddress,
	PitchBendAddress,
	PulseWidthAddress,
	FilterCutoffFrequencyAddress,
	FilterAttackDurationAddress,
	FilterDecayDurationAddress,
	FilterSustainLevelAddress,
	FilterReleaseDurationAddress,
	FilterEnvelopeStrengthAddress,
	NumberOfFilterSynthEnumElements
};

/*
 BasicSynth2DSPKernel
 Performs simple copying of the input signal to the output.
 As a non-ObjC class, this is safe to use from render thread.
 */
//class BasicSynth2DSPKernel : public AUv3DSPKernel {
class BasicSynth2DSPKernel {
protected:
	int channels;
	float sampleRate;

	enum { stageOff, stageOn, stageRelease };
	int stage = stageOff;

	float internalGate = 0;
	float amp = 0;
	float filterAmp = 0;

	sp_data *sp = nullptr;
	sp_blsquare *blsquare;
	sp_adsr *adsr;
	sp_butlp *filter;
	sp_adsr *filterEnv;

	float width;

public:
	bool resetted = false;

	float getSampleRate() { return sampleRate; }

	int currentNoteNumber = 0;

	float attackDuration = 0.1;
	float decayDuration = 0.1;
	float sustainLevel = 1.0;
	float releaseDuration = 0.1;
	float pitchBend = 0;
	float pulseWidth = 0.5;
	float filterCutoffFrequency = 22050.0;
	float filterAttackDuration = 0.1;
	float filterDecayDuration = 0.1;
	float filterSustainLevel = 1.0;
	float filterReleaseDuration = 0.1;
	float filterEnvelopeStrength = 1.0;

	UInt64 currentRunningIndex = 0;

	// This may be a little confusing.
	// This is AudioKit's version of the Parameter Ramper (which I think is based on Apple's older Parameter Ramper
	// The default ramper that comes with the default AUv3 Extension is Apple's newer Parameter Ramper and was renamed
	// ParameterRamper->AUv3ParameterRamper for this project, to avoid collisions with AK's current ParameterRamper (the older Parameter Ramper)
	//
	// tl/dr: This version of Parameter Ramper being used is an variation of an older one, that isn't weird to init,
	// so the code stays simpler to understand.
	//
	ParameterRamper attackDurationRamper = 0.1;
	ParameterRamper decayDurationRamper = 0.1;
	ParameterRamper sustainLevelRamper = 1.0;
	ParameterRamper releaseDurationRamper = 0.1;
	ParameterRamper pitchBendRamper = 0;
	ParameterRamper pulseWidthRamper = 0.5;
	ParameterRamper filterCutoffFrequencyRamper = 0.1;
	ParameterRamper filterAttackDurationRamper = 0.1;
	ParameterRamper filterDecayDurationRamper = 0.1;
	ParameterRamper filterSustainLevelRamper = 1.0;
	ParameterRamper filterReleaseDurationRamper = 0.1;
	ParameterRamper filterEnvelopeStrengthRamper = 0.0;

	AudioBufferList *outBufferListPtr = nullptr;

	BasicSynth2DSPKernel() {
		std::cout << "BasicSynth2DSPKernel Constructor" << std::endl;

		sp_blsquare_create(&blsquare);
		sp_adsr_create(&adsr);
		sp_butlp_create(&filter);
		sp_adsr_create(&filterEnv);

	};

	~BasicSynth2DSPKernel() {
		std::cout << "BasicSynth2DSPKernel Destroyer!" << std::endl;

		//printf("~BasicSynth2DSPKernel(), &sp is %p\n", (void *)sp);
		// releasing the memory in the destructor only
		sp_blsquare_destroy(&blsquare);
		sp_adsr_destroy(&adsr);
		sp_butlp_destroy(&filter);
		sp_adsr_destroy(&filterEnv);
		sp_destroy(&sp);
	}

	void init(int channelCount, double sampleRate) {
		std::cout << "BasicSynth2DSPKernel init Called" << std::endl;

		channels = channelCount;
		sampleRate = sampleRate;

		if (sp == nullptr) {
			std::cout << "SoundPipe init" << std::endl;
			sp_create(&sp);
		}
		sp->sr = sampleRate;
		sp->nchan = channelCount;

		sp_adsr_create(&adsr);

		sp_adsr_init(this->getSpData(), adsr);
		sp_blsquare_init(this->getSpData(), blsquare);
		*blsquare->freq = 0;
		*blsquare->amp = 0;
		*blsquare->width = 0.5;

		sp_adsr_init(this->getSpData(), filterEnv);
		sp_butlp_init(this->getSpData(), filter);
		filter->freq = 22050.0;

		attackDurationRamper.init();
		decayDurationRamper.init();
		sustainLevelRamper.init();
		releaseDurationRamper.init();
		pitchBendRamper.init();
		pulseWidthRamper.init();
		filterCutoffFrequencyRamper.init();
		filterAttackDurationRamper.init();
		filterDecayDurationRamper.init();
		filterSustainLevelRamper.init();
		filterReleaseDurationRamper.init();
		filterEnvelopeStrengthRamper.init();

	}

	void destroy() {
		std::cout << "Destorying BasicSynth2DSPKernel" << std::endl;
		//printf("BasicSynth2DSPKernel.destroy(), &sp is %p\n", (void *)sp);
	}

	void clear() {
		stage = stageOff;
		amp = 0;
		filterAmp = 0;
	}

	double frequencyScale() {
		return 2. * M_PI / sampleRate;
	}

	sp_data *getSpData() {
		return sp;
	}

	// Normal MIDI off, not running mode.
	// Mainly used for MIDI Panic
	void noteOff(int noteNumber, int velocity) {

		std::cout << "noteOff() " << std::to_string(noteNumber) + " " + std::to_string(velocity) << std::endl;

		stage = stageRelease;
		internalGate = 0;
	}


	void noteOn(int noteNumber, int velocity) {
		noteOn(noteNumber, velocity, (float)noteToHz(noteNumber));
	}

	void noteOn(int noteNumber, int velocity, float frequency) {
		std::cout << "noteOn() " << std::to_string(noteNumber) + " " + std::to_string(velocity) << std::endl;

		if (velocity == 0) {
			// For check for running mode midi off.
			if (stage == stageOn && currentNoteNumber == noteNumber) {

				std::cout << "	Note Release" << std::endl;

				stage = stageRelease;
				internalGate = 0;
			}
		} else {
			std::cout << "	Note Attack" << std::endl;
			stage = stageOn;
			internalGate = 1;

			currentNoteNumber = noteNumber;

		}

		if (velocity != 0) {

			currentNoteNumber = noteNumber;

			*blsquare->freq = frequency;
			*blsquare->amp = (float)pow2(velocity / 127.);
		}
	}

	void run(int frameCount, float *outL, float *outR) {

		float originalFrequency = *blsquare->freq;
		*blsquare->freq *= powf(2, this->pitchBend / 12.0);
		*blsquare->freq = clamp(*blsquare->freq, 0.0f, 22050.0f);
		float bentFrequency = *blsquare->freq;

		*blsquare->width = this->pulseWidth;

		adsr->atk = (float)this->attackDuration;
		adsr->dec = (float)this->decayDuration;
		adsr->sus = (float)this->sustainLevel;
		adsr->rel = (float)this->releaseDuration;

		float sff = (float)this->filterCutoffFrequency;
		filter->freq = (float)this->filterCutoffFrequency;
		float filterStrength = this->filterEnvelopeStrength;

		filter->freq = sff;

		filterEnv->atk = (float)this->filterAttackDuration;
		filterEnv->dec = (float)this->filterDecayDuration;
		filterEnv->sus = (float)this->filterSustainLevel;
		filterEnv->rel = (float)this->filterReleaseDuration;

		for (int frameIndex = 0; frameIndex < frameCount; ++frameIndex) {
			float x = 0;

			*blsquare->freq = bentFrequency;
			sp_adsr_compute(this->getSpData(), adsr, &internalGate, &amp);
			sp_blsquare_compute(this->getSpData(), blsquare, nil, &x);

			float xf = 0;

			float filterFreq = clamp(sff, 0.0f, 22050.0f);

			sp_adsr_compute(this->getSpData(), filterEnv, &internalGate, &filterAmp);

			filterAmp = filterAmp * filterStrength;
			filter->freq = filterFreq + ((22050.0f - filterFreq) * filterAmp);

			filter->freq = clamp(filter->freq, 0.0f, 22050.0f);
			sp_butlp_compute(this->getSpData(), filter, &x, &xf);

			*outL++ += amp * xf;
			*outR++ += amp * xf;
		}

		*blsquare->freq = originalFrequency;

		if (stage == stageRelease && amp < 0.00001) {
			clear();
		}

	}


	// Override to handle MIDI events.
	void handleMIDIEvent(AUMIDIEvent const& midiEvent) {
		if (midiEvent.length != 3) return;
		uint8_t status = midiEvent.data[0] & 0xF0;

		switch (status) {
			case 0x80 : {

				std::cout << "MIDI Note Off. " + std::to_string(midiEvent.data[0]) + " " + std::to_string(midiEvent.data[1]) + " " + std::to_string(midiEvent.data[2]) << std::endl;

				uint8_t note = midiEvent.data[1];
				if (note > 127) break;
				this->noteOn(note, 0);
				break;
			}
			case 0x90 : {

				std::cout << "MIDI Note ON!  " + std::to_string(midiEvent.data[0]) + " " + std::to_string(midiEvent.data[1]) + " " + std::to_string(midiEvent.data[2]) << std::endl;

				uint8_t note = midiEvent.data[1];
				uint8_t veloc = midiEvent.data[2];
				if (note > 127 || veloc > 127) break;
				this->noteOn(note, veloc);
				break;
			}
			case 0xB0 : {

				std::cout << "MIDI CC! " + std::to_string(midiEvent.data[0]) + " " + std::to_string(midiEvent.data[1]) + " " + std::to_string(midiEvent.data[2]) << std::endl;

				uint8_t cc = midiEvent.data[1];
				uint8_t cc_value = midiEvent.data[2];

				std::cout << "CC Received " << std::to_string(cc) + " " + std::to_string(cc_value) << std::endl;

				break;
			}
		}
	}


	AUAudioFrameCount maximumFramesToRender() const {
		return maxFramesToRender;
	}


	void setMaximumFramesToRender(const AUAudioFrameCount &maxFrames) {
		maxFramesToRender = maxFrames;
	}


	void process(AUAudioFrameCount frameCount, AUAudioFrameCount bufferOffset) {

		float *outL = (float *)outBufferListPtr->mBuffers[0].mData + bufferOffset;
		float *outR = (float *)outBufferListPtr->mBuffers[1].mData + bufferOffset;

		standardFilterSynthGetAndSteps();

		this->run(frameCount, outL, outR);

		currentRunningIndex += frameCount / 2;

		for (AUAudioFrameCount i = 0; i < frameCount; ++i) {
			outL[i] *= .5f;
			outR[i] *= .5f;
		}
	}

	/**
	 This function handles the event list processing and rendering loop for you.
	 Call it inside your internalRenderBlock.
	 */
	void processWithEvents(AudioTimeStamp const *timestamp, AUAudioFrameCount frameCount, AURenderEvent const *events) {

		AUEventSampleTime now = AUEventSampleTime(timestamp->mSampleTime);
		AUAudioFrameCount framesRemaining = frameCount;
		AURenderEvent const *event = events;

		while (framesRemaining > 0) {
			// If there are no more events, we can process the entire remaining segment and exit.
			if (event == nullptr) {
				AUAudioFrameCount const bufferOffset = frameCount - framesRemaining;
				process(framesRemaining, bufferOffset);
				return;
			}

			AUAudioFrameCount const framesThisSegment = AUAudioFrameCount(event->head.eventSampleTime - now);

			// Compute everything before the next event.
			if (framesThisSegment > 0) {
				AUAudioFrameCount const bufferOffset = frameCount - framesRemaining;
				process(framesThisSegment, bufferOffset);

				// Advance frames.
				framesRemaining -= framesThisSegment;

				// Advance time.
				now += AUEventSampleTime(framesThisSegment);
			}

			performAllSimultaneousEvents(now, event);
		}
		
	}


	void reset() {

		resetted = true;

		attackDurationRamper.reset();
		decayDurationRamper.reset();
		sustainLevelRamper.reset();
		releaseDurationRamper.reset();
		pitchBendRamper.reset();

		pulseWidthRamper.reset();

		filterCutoffFrequencyRamper.reset();
		filterAttackDurationRamper.reset();
		filterDecayDurationRamper.reset();
		filterSustainLevelRamper.reset();
		filterReleaseDurationRamper.reset();
		filterEnvelopeStrengthRamper.reset();

	}


	// MARK: - Set Parameters
	// This is the access point for the parameters
	void setParameter(AUParameterAddress address, AUValue value) {
		switch (address) {
			case AttackDurationAddress:
				attackDurationRamper.setUIValue(clamp(value, 0.0f, 99.0f));
				break;
			case DecayDurationAddress:
				decayDurationRamper.setUIValue(clamp(value, 0.0f, 99.0f));
				break;
			case SustainLevelAddress:
				sustainLevelRamper.setUIValue(clamp(value, 0.0f, 99.0f));
				break;
			case ReleaseDurationAddress:
				releaseDurationRamper.setUIValue(clamp(value, 0.0f, 99.0f));
				break;
			case PitchBendAddress:
				pitchBendRamper.setUIValue(clamp(value, (float)-24, (float)24));
				break;
			case PulseWidthAddress:
				pulseWidth = clamp(value, 0.01f, 0.5f);
				pulseWidthRamper.setImmediate(pulseWidth);
				break;
			case FilterCutoffFrequencyAddress:
				filterCutoffFrequency = clamp(value, 1.0f, 22050.0f);
				filterCutoffFrequencyRamper.setImmediate(filterCutoffFrequency);
				break;
			case FilterAttackDurationAddress:
				filterAttackDurationRamper.setUIValue(clamp(value, 0.0f, 99.0f));
				break;
			case FilterDecayDurationAddress:
				filterDecayDurationRamper.setUIValue(clamp(value, 0.0f, 99.0f));
				break;
			case FilterSustainLevelAddress:
				filterSustainLevelRamper.setUIValue(clamp(value, 0.0f, 99.0f));
				break;
			case FilterReleaseDurationAddress:
				filterReleaseDurationRamper.setUIValue(clamp(value, 0.0f, 99.0f));
				break;
			case FilterEnvelopeStrengthAddress:
				filterEnvelopeStrengthRamper.setUIValue(clamp(value, 0.0f, 1.0f));
				break;
		}
	}


	AUValue getParameter(AUParameterAddress address) {
		switch (address) {
			case AttackDurationAddress:
				return attackDurationRamper.getUIValue();
			case DecayDurationAddress:
				return decayDurationRamper.getUIValue();
			case SustainLevelAddress:
				return sustainLevelRamper.getUIValue();
			case ReleaseDurationAddress:
				return releaseDurationRamper.getUIValue();
			case PitchBendAddress:
				return pitchBendRamper.getUIValue();
			case PulseWidthAddress:
				return pulseWidthRamper.getUIValue();
			case FilterCutoffFrequencyAddress:
				return filterCutoffFrequencyRamper.getUIValue();
			case FilterAttackDurationAddress:
				return filterAttackDurationRamper.getUIValue();
			case FilterDecayDurationAddress:
				return filterDecayDurationRamper.getUIValue();
			case FilterSustainLevelAddress:
				return filterSustainLevelRamper.getUIValue();
			case FilterReleaseDurationAddress:
				return filterReleaseDurationRamper.getUIValue();
			case FilterEnvelopeStrengthAddress:
				return filterEnvelopeStrengthRamper.getUIValue();
			default: return 0.0f;
		}
	}

	void setBuffers(AudioBufferList* inBufferList, AudioBufferList* outBufferList) {
		outBufferListPtr = outBufferList;
	}

	void setOutputBuffer(AudioBufferList* outBufferList) {
		outBufferListPtr = outBufferList;
	}

	void setAttackDuration(float value) {
		attackDuration = clamp(value, 0.0f, 99.0f);
		attackDurationRamper.setImmediate(attackDuration);
	}

	void setDecayDuration(float value) {
		decayDuration = clamp(value, 0.0f, 99.0f);
		decayDurationRamper.setImmediate(decayDuration);
	}

	void setSustainLevel(float value) {
		sustainLevel = clamp(value, 0.0f, 99.0f);
		sustainLevelRamper.setImmediate(sustainLevel);
	}

	void setReleaseDuration(float value) {
		releaseDuration = clamp(value, 0.0f, 99.0f);
		releaseDurationRamper.setImmediate(releaseDuration);
	}

	void setPulseWidth(float value) {
		pulseWidth = clamp(value, 0.0f, 1.0f);
		pulseWidthRamper.setImmediate(pulseWidth);
	}

	void setPitchBend(float value) {
		pitchBend = clamp(value, (float)-48, (float)48);
		pitchBendRamper.setImmediate(pitchBend);
	}

	void setFilterCutoffFrequency(float value) {
		filterCutoffFrequency = clamp(value, 0.0f, 22050.0f);
		filterCutoffFrequencyRamper.setImmediate(filterCutoffFrequency);
	}

	void setFilterAttackDuration(float value) {
		filterAttackDuration = clamp(value, 0.0f, 99.0f);
		filterAttackDurationRamper.setImmediate(filterAttackDuration);
	}

	void setFilterDecayDuration(float value) {
		filterDecayDuration = clamp(value, 0.0f, 99.0f);
		filterDecayDurationRamper.setImmediate(filterDecayDuration);
	}

	void setFilterSustainLevel(float value) {
		filterSustainLevel = clamp(value, 0.0f, 99.0f);
		filterSustainLevelRamper.setImmediate(filterSustainLevel);
	}

	void setFilterReleaseDuration(float value) {
		filterReleaseDuration = clamp(value, 0.0f, 99.0f);
		filterReleaseDurationRamper.setImmediate(filterReleaseDuration);
	}

	void setFilterEnvelopeStength(float value) {
		filterEnvelopeStrength = clamp(value, 0.0f, 1.0f);
		filterEnvelopeStrengthRamper.setImmediate(filterEnvelopeStrength);
	}

	void standardFilterSynthGetAndSteps() {
		attackDuration = attackDurationRamper.getAndStep();
		decayDuration = decayDurationRamper.getAndStep();
		sustainLevel = sustainLevelRamper.getAndStep();
		releaseDuration = releaseDurationRamper.getAndStep();
		pitchBend = double(pitchBendRamper.getAndStep());
		pulseWidth = double(pulseWidthRamper.getAndStep());
		filterCutoffFrequency = double(filterCutoffFrequencyRamper.getAndStep());
		filterAttackDuration = filterAttackDurationRamper.getAndStep();
		filterDecayDuration = filterDecayDurationRamper.getAndStep();
		filterSustainLevel = filterSustainLevelRamper.getAndStep();
		filterReleaseDuration = filterReleaseDurationRamper.getAndStep();
		filterEnvelopeStrength = filterEnvelopeStrengthRamper.getAndStep();
	}

	void startRamp(AUParameterAddress address, AUValue value, AUAudioFrameCount duration) {
		switch (address) {
			case AttackDurationAddress:
				attackDurationRamper.startRamp(clamp(value, 0.0f, 99.0f), duration);
				break;
			case DecayDurationAddress:
				decayDurationRamper.startRamp(clamp(value, 0.0f, 99.0f), duration);
				break;
			case SustainLevelAddress:
				sustainLevelRamper.startRamp(clamp(value, 0.0f, 99.0f), duration);
				break;
			case ReleaseDurationAddress:
				releaseDurationRamper.startRamp(clamp(value, 0.0f, 99.0f), duration);
				break;
			case PitchBendAddress:
				pitchBendRamper.startRamp(clamp(value, (float)-24, (float)24), duration);
				break;
			case PulseWidthAddress:
				pulseWidthRamper.startRamp(clamp(value, 0.0f, 1.0f), duration);
				break;
			case FilterCutoffFrequencyAddress:
				filterCutoffFrequencyRamper.startRamp(clamp(value, 0.0f, 22050.0f), duration);
				break;
			case FilterAttackDurationAddress:
				filterAttackDurationRamper.startRamp(clamp(value, 0.0f, 99.0f), duration);
				break;
			case FilterDecayDurationAddress:
				filterDecayDurationRamper.startRamp(clamp(value, 0.0f, 99.0f), duration);
				break;
			case FilterSustainLevelAddress:
				filterSustainLevelRamper.startRamp(clamp(value, 0.0f, 99.0f), duration);
				break;
			case FilterReleaseDurationAddress:
				filterReleaseDurationRamper.startRamp(clamp(value, 0.0f, 99.0f), duration);
				break;
			case FilterEnvelopeStrengthAddress:
				filterEnvelopeStrengthRamper.startRamp(clamp(value, 0.0f, 1.0f), duration);
				break;
		}
	}

	static inline double noteToHz(int noteNumber) {
		return 440. * exp2((noteNumber - 69)/12.);
	}

	static inline double floatToHz(float noteNumber) {
		return 440. * exp2((noteNumber - 69.0)/12.);
	}


private:

	AUAudioFrameCount maxFramesToRender = 512;

	void handleOneEvent(AURenderEvent const *event) {
		switch (event->head.eventType) {
			case AURenderEventParameter:
			case AURenderEventParameterRamp: {
				AUParameterEvent const& paramEvent = event->parameter;

				startRamp(paramEvent.parameterAddress, paramEvent.value, paramEvent.rampDurationSampleFrames);
				break;
			}

			case AURenderEventMIDI:
				handleMIDIEvent(event->MIDI);
				break;

			default:
				break;
		}
	}

	void performAllSimultaneousEvents(AUEventSampleTime now, AURenderEvent const*& event) {
		do {
			handleOneEvent(event);

			// Go to next event.
			event = event->head.next;

			// While event is not null and is simultaneous.
		} while (event && event->head.eventSampleTime == now);
	}

};



class BasicSynth2ParametricKernel {
protected:
	ParameterRamper& getRamper(AUParameterAddress address);

public:

	AUValue getParameter(AUParameterAddress address) {
		return getRamper(address).getUIValue();
	}

	void setParameter(AUParameterAddress address, AUValue value) {
		return getRamper(address).setUIValue(value);
	}
	void startRamp(AUParameterAddress address, AUValue value, AUAudioFrameCount duration) {
		getRamper(address).startRamp(value, duration);
	}
};

class BasicSynth2OutputBuffered {
protected:
	AudioBufferList *outBufferListPtr = nullptr;
public:
	void setBuffer(AudioBufferList *outBufferList) {
		outBufferListPtr = outBufferList;
	}
};


class BasicSynth2Buffered: public BasicSynth2OutputBuffered {
protected:
	AudioBufferList *inBufferListPtr = nullptr;
public:
	void setBuffers(AudioBufferList *inBufferList, AudioBufferList *outBufferList) {
		BasicSynth2OutputBuffered::setBuffer(outBufferList);
		inBufferListPtr = inBufferList;
	}
};

class BasicSynth2DSPKernelWithParameters : BasicSynth2DSPKernel, BasicSynth2ParametricKernel {
public:
	void start() {}
	void stop() {}
	bool started;
	bool resetted;

};




#endif /* BasicSynth2DSPKernel_hpp */
