//
//  DSPKernel.mm
//  BasicSynth2
//
//  Created by Stanley Rosenbaum on 2/6/20.
//  Copyright © 2020 Apple. All rights reserved.
//

#import "AUv3DSPKernel.hpp"

// I just renamed this class from DSPKernel -> AUv3DSPKernel to differentiate it from the previous DSPKernel
// Xcode AU Generator used to make, and that is also found in the current AudioKit.

void AUv3DSPKernel::handleOneEvent(AURenderEvent const *event) {
    switch (event->head.eventType) {
        case AURenderEventParameter: {
            handleParameterEvent(event->parameter);
            break;
        }

        case AURenderEventMIDI:
            handleMIDIEvent(event->MIDI);
            break;

        default:
            break;
    }
}

void AUv3DSPKernel::performAllSimultaneousEvents(AUEventSampleTime now, AURenderEvent const *&event, AUMIDIOutputEventBlock midiOut) {
    do {
        handleOneEvent(event);

        if (event->head.eventType == AURenderEventMIDI && midiOut)
        {
            midiOut(now, 0, event->MIDI.length, event->MIDI.data);
        }
        
        // Go to next event.
        event = event->head.next;

        // While event is not null and is simultaneous (or late).
    } while (event && event->head.eventSampleTime <= now);
}

/**
 This function handles the event list processing and rendering loop for you.
 Call it inside your internalRenderBlock.
 */
void AUv3DSPKernel::processWithEvents(AudioTimeStamp const *timestamp, AUAudioFrameCount frameCount, AURenderEvent const *events, AUMIDIOutputEventBlock midiOut) {

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

        // **** start late events late.
        auto timeZero = AUEventSampleTime(0);
        auto headEventTime = event->head.eventSampleTime;
        AUAudioFrameCount const framesThisSegment = AUAudioFrameCount(std::max(timeZero, headEventTime - now));

        // Compute everything before the next event.
        if (framesThisSegment > 0) {
            AUAudioFrameCount const bufferOffset = frameCount - framesRemaining;
            process(framesThisSegment, bufferOffset);

            // Advance frames.
            framesRemaining -= framesThisSegment;

            // Advance time.
            now += AUEventSampleTime(framesThisSegment);
        }

        performAllSimultaneousEvents(now, event, midiOut);
    }
}
