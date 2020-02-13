/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A simple playback engine built on AVAudioEngine and its related classes.
*/

import AVFoundation
import AudioKit

public class SimplePlayEngine {
    
    // The engine's active unit node.
    private var activeAVAudioUnit: AVAudioUnit?

    private var instrumentPlayer: InstrumentPlayer?

    // Synchronizes starting/stopping the engine and scheduling file segments.
    private let stateChangeQueue = DispatchQueue(label: "com.example.apple-samplecode.StateChangeQueue")

    // Playback engine.
    private let engine = AVAudioEngine()
    
    // Engine's player node.
    private let player = AVAudioPlayerNode()

    // File to play.
    private var file: AVAudioFile?
    
    // Whether we are playing.
    private var isPlaying = false

	// for Midi
	private var akMidi = AudioKit.midi

    // This block will be called every render cycle and will receive MIDI events
    private let midiOutBlock: AUMIDIOutputEventBlock = { sampleTime, cable, length, data in return noErr }

    private var componentType: OSType {
        return activeAVAudioUnit?.audioComponentDescription.componentType ?? kAudioUnitType_Effect
    }
    
    private var isEffect: Bool {
        // SimplePlayEngine only supports effects or instruments.
        // If it's not an instrument, it's an effect
        return !isInstrument
    }

    private var isInstrument: Bool {
        return componentType == kAudioUnitType_MusicDevice
    }

    // MARK: Initialization

    public init() {


//		setUpAKMidi()

        engine.attach(player)

        guard let fileURL = Bundle.main.url(forResource: "Synth", withExtension: "aif") else {
            fatalError("\"Synth.aif\" file not found.")
        }
        setPlayerFile(fileURL)

        engine.prepare()

    }

    private func setPlayerFile(_ fileURL: URL) {
        do {
            let file = try AVAudioFile(forReading: fileURL)
            self.file = file
            engine.connect(player, to: engine.mainMixerNode, format: file.processingFormat)
        } catch {
            fatalError("Could not create AVAudioFile instance. error: \(error).")
        }
    }
    
    private func setSessionActive(_ active: Bool) {
        #if os(iOS)
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(active)
        } catch {
            fatalError("Could not set Audio Session active \(active). error: \(error).")
        }
        #endif
    }

    // MARK: Playback State
    
    public func startPlaying() {
        stateChangeQueue.sync {
            if !self.isPlaying { self.startPlayingInternal() }
        }
    }

	public func stopPlaying() {
		stateChangeQueue.sync {
			if self.isPlaying { self.stopPlayingInternal() }
		}
	}

	public func startMIDIPlaying() {
		stateChangeQueue.sync {
			if !self.isPlaying { self.startMIDIPlayingInternal() }
		}
	}

	public func stopMIDIPlaying() {
		stateChangeQueue.sync {
			if self.isPlaying { self.stopMIDIPlayingInternal() }
		}
	}

    public func togglePlay() -> Bool {
        if isPlaying {
            stopPlaying()
        } else {
            startPlaying()
        }
        return isPlaying
    }

	public func toggleMIDIPlay() -> Bool {
		if isPlaying {
			stopMIDIPlaying()
		} else {
			startMIDIPlaying()
		}
		return isPlaying
	}

	private func startMIDIPlayingInternal() {

		print("startMIDIPlayingInternal()")

		// assumptions: we are protected by stateChangeQueue. we are not playing.
		setSessionActive(true)

		let hardwareFormat = engine.outputNode.outputFormat(forBus: 0)
		engine.connect(engine.mainMixerNode, to: engine.outputNode, format: hardwareFormat)

		// Start the engine.
		do {
			try engine.start()
		} catch {
			isPlaying = false
			fatalError("Could not start engine. error: \(error).")
		}

		if isInstrument {
			akMidi.openInput()
			akMidi.addListener(self)

			instrumentPlayer = InstrumentPlayer(audioUnit: activeAVAudioUnit?.auAudioUnit)
		}

		isPlaying = true
	}

    private func startPlayingInternal() {
        // assumptions: we are protected by stateChangeQueue. we are not playing.
        setSessionActive(true)
        
        if isEffect {
            // Schedule buffers on the player.
            scheduleEffectLoop()
            scheduleEffectLoop()
        }
        
        let hardwareFormat = engine.outputNode.outputFormat(forBus: 0)
        engine.connect(engine.mainMixerNode, to: engine.outputNode, format: hardwareFormat)
        
        // Start the engine.
        do {
            try engine.start()
        } catch {
            isPlaying = false
            fatalError("Could not start engine. error: \(error).")
        }
        
        if isEffect {
            // Start the player.
            player.play()
        } else if isInstrument {
            instrumentPlayer = InstrumentPlayer(audioUnit: activeAVAudioUnit?.auAudioUnit)
            instrumentPlayer?.play()
        }

        isPlaying = true
    }

	private func stopMIDIPlayingInternal() {

		print("stopMIDIPlayingInternal()")

		if isInstrument {
			instrumentPlayer?.stop()
		}

		engine.stop()
		isPlaying = false
		setSessionActive(false)


	}

    private func stopPlayingInternal() {

		print("stopPlayingInternal()")

        if isEffect {
            player.stop()
        } else if isInstrument {
            instrumentPlayer?.stop()
        }
        engine.stop()
        isPlaying = false
        setSessionActive(false)
    }
    
    private func scheduleEffectLoop() {
        guard let file = file else {
            fatalError("`file` must not be nil in \(#function).")
        }
        
        player.scheduleFile(file, at: nil) {
            self.stateChangeQueue.async {
                if self.isPlaying {
                    self.scheduleEffectLoop()
                }
            }
        }
    }

    private func resetAudioLoop() {
        if isEffect {
            // Connect player -> mixer.
            guard let format = file?.processingFormat else { fatalError("No AVAudioFile defined (processing format unavailable).") }
            engine.connect(player, to: engine.mainMixerNode, format: format)
        }
    }

    public func reset() {
        connect(avAudioUnit: nil)
    }

    public func connect(avAudioUnit: AVAudioUnit?, completion: @escaping (() -> Void) = {}) {

        // If effect, ensure audio loop is reset (but only once per call to this method)
        var needsAudioLoopReset = true

        // Destroy the currently connected audio unit, if any.
        if let audioUnit = activeAVAudioUnit {
            if isEffect {
                // Break the player -> effect connection.
                engine.disconnectNodeInput(audioUnit)
            }

            // Break the audio unit -> mixer connection
            engine.disconnectNodeInput(engine.mainMixerNode)

            resetAudioLoop()
            needsAudioLoopReset = false

            // We're done with the unit; release all references.
            engine.detach(audioUnit)
        }

        activeAVAudioUnit = avAudioUnit

        // Internal function to resume playing and call the completion handler.
        func rewiringComplete() {
            if isEffect && isPlaying {
                player.play()
            } else if isInstrument && isPlaying {
                instrumentPlayer = InstrumentPlayer(audioUnit: activeAVAudioUnit?.auAudioUnit)
                instrumentPlayer?.play()
            }
            completion()
        }

        let hardwareFormat = engine.outputNode.outputFormat(forBus: 0)

        // Connect the main mixer -> output node
        engine.connect(engine.mainMixerNode, to: engine.outputNode, format: hardwareFormat)

        // Pause the player before re-wiring it. It is not simple to keep it playing across an insertion or deletion.
        if isEffect && isPlaying {
            player.pause()
        } else if isInstrument && isPlaying {
            instrumentPlayer?.stop()
            instrumentPlayer = nil
        }

        guard let avAudioUnit = avAudioUnit else {
            if needsAudioLoopReset { resetAudioLoop() }
            rewiringComplete()
            return
        }

        let auAudioUnit = avAudioUnit.auAudioUnit

        if !auAudioUnit.midiOutputNames.isEmpty {
            auAudioUnit.midiOutputEventBlock = midiOutBlock
        }

        // Attach the AVAudioUnit the the graph.
        engine.attach(avAudioUnit)

        if isEffect {
            // Disconnect the player -> mixer.
            engine.disconnectNodeInput(engine.mainMixerNode)

            // Connect the player -> effect -> mixer.
            if let format = file?.processingFormat {
                engine.connect(player, to: avAudioUnit, format: format)
                engine.connect(avAudioUnit, to: engine.mainMixerNode, format: format)
            }
        } else {
            let stereoFormat = AVAudioFormat(standardFormatWithSampleRate: hardwareFormat.sampleRate, channels: 2)
            engine.connect(avAudioUnit, to: engine.mainMixerNode, format: stereoFormat)
        }
        rewiringComplete()
    }


	func setUpAKMidi() {

		print("setUpAKMidi()")

		akMidi.openInput()
		akMidi.addListener(self)
	}

    // MARK: InstrumentPlayer

    /// Simple MIDI note generator that plays a two-octave scale.
    public class InstrumentPlayer {

        private var isPlaying = false
        private var isDone = false
        private var noteBlock: AUScheduleMIDIEventBlock

        init?(audioUnit: AUAudioUnit?) {
            guard let audioUnit = audioUnit else { return nil }
            guard let theNoteBlock = audioUnit.scheduleMIDIEventBlock else { return nil }

            noteBlock = theNoteBlock
        }

        func play() {
            if !isPlaying {
                isDone = false
                scheduleInstrumentLoop()
            }
        }

        @discardableResult
        func stop() -> Bool {

			print("InstrumentPlayer.stop()")

            isPlaying = false
            synced(isDone) {}
            return isDone
        }

        private func synced(_ lock: Any, closure: () -> Void) {
            objc_sync_enter(lock)
            closure()
            objc_sync_exit(lock)
        }


		public func scheduleCCFor(_ cc: UInt8, with data: UInt8) {
			isPlaying = true

			print("scheduleCCFor( \(cc), \(data)")

			let cbytes = UnsafeMutablePointer<UInt8>.allocate(capacity: 3)

			DispatchQueue.global(qos: .default).async {

				cbytes[0] = 0xB0 // status note on/off
				cbytes[1] = cc // note
				cbytes[2] = data // velocity

				self.noteBlock(AUEventSampleTimeImmediate, 0, 3, cbytes)

//				self.synced(self.isDone) {
//					self.noteBlock(AUEventSampleTimeImmediate, 0, 3, cbytes)
//				} // while isPlaying

				self.isDone = true
				cbytes.deallocate()
			}
		}



		public func scheduleInstrumentNote(on: Bool,
											noteNumber: UInt8,
											at velocity: UInt8) {
			isPlaying = true

			print("scheduleInstrumentNoteFor() \(noteNumber) at \(velocity)")

			let cbytes = UnsafeMutablePointer<UInt8>.allocate(capacity: 3)

			DispatchQueue.global(qos: .default).async {

				cbytes[0] = on ? 0x90 : 0x80 // status note on/off
				cbytes[1] = noteNumber // note
				cbytes[2] = velocity // velocity

				self.noteBlock(AUEventSampleTimeImmediate, 0, 3, cbytes)

//				self.synced(self.isDone) {
//					self.noteBlock(AUEventSampleTimeImmediate, 0, 3, cbytes)
//				} // while isPlaying

				self.isDone = true
				cbytes.deallocate()
			}
		}

        private func scheduleInstrumentLoop() {
            isPlaying = true

            let cbytes = UnsafeMutablePointer<UInt8>.allocate(capacity: 3)

            DispatchQueue.global(qos: .default).async {

                var step = 0

                // The steps arrays define the musical intervals of a scale (w = whole step, h = half step).

                // C Major: w, w, h, w, w, w, h
                let steps = [2, 2, 1, 2, 2, 2, 1]

                // C Minor: w, h, w, w, w, h, w
                // let steps = [2, 1, 2, 2, 2, 1, 2]

                // C Lydian: w, w, w, h, w, w, h
                // let steps = [2, 2, 2, 1, 2, 2, 1]

                cbytes[0] = 0xB0 // status
                cbytes[1] = 60 // note
                cbytes[2] = 0 // velocity
                self.noteBlock(AUEventSampleTimeImmediate, 0, 3, cbytes)

                usleep(useconds_t(0.5))

                var releaseTime: Float = 0.05

                usleep(useconds_t(0.1 * 1e6))

                var note = 0
                self.synced(self.isDone) {

                    while self.isPlaying {
                        // lengthen the releaseTime by 5% each time up to 10 seconds.
                        if releaseTime < 10.0 {
                            releaseTime = min(releaseTime * 1.05, 10.0)
                        }

                        cbytes[0] = 0x90
                        cbytes[1] = UInt8(60 + note)
                        cbytes[2] = 64
                        self.noteBlock(AUEventSampleTimeImmediate, 0, 3, cbytes)

						usleep(useconds_t(1.2 * 1e6)) // Note Length

                        cbytes[2] = 0    // note off
                        self.noteBlock(AUEventSampleTimeImmediate, 0, 3, cbytes)

                        // Reset the note and step after a 2-octave run. (12 semi-tones * 2)
                        if note >= 24 {
                            note = 0
                            step = 0
                            continue
                        }

                        // Increment the note interval to the next interval step in the scale
                        note += steps[step]

                        step += 1

                        if step >= steps.count {
                            step = 0
                        }

                    } // while isPlaying

                    cbytes[0] = 0xB0
                    cbytes[1] = 60
                    cbytes[2] = 0
                    self.noteBlock(AUEventSampleTimeImmediate, 0, 3, cbytes)

                    self.isDone = true

                    cbytes.deallocate()
                }
            }
        }
    }

}


extension SimplePlayEngine: AKMIDIListener {

	public func receivedMIDINoteOn(noteNumber: MIDINoteNumber,
								   velocity: MIDIVelocity,
								   channel: MIDIChannel,
								   portID: MIDIUniqueID? = nil,
								   offset: MIDITimeStamp = 0) {
		updateText("Channel: \(channel + 1) noteOn: \(noteNumber) velocity: \(velocity) ")

		if let theInstrumentPlayer = instrumentPlayer,
			isPlaying {
			theInstrumentPlayer.scheduleInstrumentNote(on: true, noteNumber: noteNumber, at: velocity)
		}


	}

	public func receivedMIDINoteOff(noteNumber: MIDINoteNumber,
									velocity: MIDIVelocity,
									channel: MIDIChannel,
									portID: MIDIUniqueID? = nil,
									offset: MIDITimeStamp = 0) {
		updateText("Channel: \(channel + 1) noteOff: \(noteNumber) velocity: \(velocity) ")

		if let theInstrumentPlayer = instrumentPlayer,
			isPlaying {
			theInstrumentPlayer.scheduleInstrumentNote(on: false, noteNumber: noteNumber, at: velocity)
		}

	}

	public func receivedMIDIController(_ controller: MIDIByte,
									   value: MIDIByte,
									   channel: MIDIChannel,
									   portID: MIDIUniqueID? = nil,
									   offset: MIDITimeStamp = 0) {
		updateText("Channel: \(channel + 1) controller: \(controller) value: \(value) ")
		if let theInstrumentPlayer = instrumentPlayer,
			isPlaying {
			theInstrumentPlayer.scheduleCCFor(controller, with: value)
		}
	}

	public func receivedMIDIAftertouch(noteNumber: MIDINoteNumber,
									   pressure: MIDIByte,
									   channel: MIDIChannel,
									   portID: MIDIUniqueID? = nil,
									   offset: MIDITimeStamp = 0) {
		updateText("Channel: \(channel + 1) AftertouchOnNote: \(noteNumber) pressure: \(pressure) ")
	}

	public func receivedMIDIAftertouch(_ pressure: MIDIByte,
									   channel: MIDIChannel,
									   portID: MIDIUniqueID? = nil,
									   offset: MIDITimeStamp = 0) {
		updateText("Channel: \(channel + 1) Aftertouch pressure: \(pressure) ")
	}

	public func receivedMIDIPitchWheel(_ pitchWheelValue: MIDIWord,
									   channel: MIDIChannel,
									   portID: MIDIUniqueID? = nil,
									   offset: MIDITimeStamp = 0) {
		updateText("Channel: \(channel + 1)  PitchWheel: \(pitchWheelValue)")
	}

	public func receivedMIDIProgramChange(_ program: MIDIByte,
										  channel: MIDIChannel,
										  portID: MIDIUniqueID? = nil,
										  offset: MIDITimeStamp = 0) {
		updateText("Channel: \(channel + 1) programChange: \(program)")
	}

	public func receivedMIDISystemCommand(_ data: [MIDIByte],
										  portID: MIDIUniqueID? = nil,
										  offset: MIDITimeStamp = 0) {
		if let command = AKMIDISystemCommand(rawValue: data[0]) {
			var newString = "MIDI System Command: \(command) \n"
			for i in 0 ..< data.count {
				newString.append("\(data[i]) ")
			}
			updateText(newString)
		}
	}

	func updateText(_ input: String) {
		DispatchQueue.main.async(execute: {
			print("\(input)")
		})
	}
}
