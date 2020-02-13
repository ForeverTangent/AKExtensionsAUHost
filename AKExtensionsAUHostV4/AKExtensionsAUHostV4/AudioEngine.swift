//
//  AudioEngine.swift
//  AKExtensionsAUHostV4
//
//  Created by Stanley Rosenbaum on 2/13/20.
//  Copyright © 2020 STAQUE. All rights reserved.
//

import AVFoundation


protocol AudioPlayerInstrumentDelegate {
	func schedule( midiEvent: AUScheduleMIDIEventBlock? )


}


class AudioPlayer: NSObject {

	private let engine = AVAudioEngine()

	private var synthNode: AVAudioUnit?
	private var file: AVAudioFile!
	private var isPlaying = false
	private let audioPlayerQueue = DispatchQueue(label: "AudioPlayerQueue")

	init(_ synthNode: AVAudioUnit) {
		self.synthNode = synthNode
		super.init()

		if let theSynthNode = self.synthNode {
			engine.attach(theSynthNode)
		}

	}

	func play() {
		audioPlayerQueue.sync {
			guard !self.isPlaying else { return }
			self.startPlaying()
		}
	}

	private func startPlaying() {
		guard let theSynthNode = self.synthNode else { return }
		engine.connect(theSynthNode, to: engine.mainMixerNode, format: file.processingFormat)
		let hardwareFormat = engine.outputNode.outputFormat(forBus: 0)
		engine.connect(engine.mainMixerNode, to: engine.outputNode, format: hardwareFormat)
		do {
			try engine.start()
		} catch {
			fatalError("can't start engine \(error)")
		}

		isPlaying = true
	}


}
