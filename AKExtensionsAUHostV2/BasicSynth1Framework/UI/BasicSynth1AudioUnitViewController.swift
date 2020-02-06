//
//  BasicSynth1AudioUnitViewController.swift
//  BasicSynth1
//
//  Created by Stanley Rosenbaum on 2/5/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import CoreAudioKit

class BasicSynth1AudioUnitViewController: AUViewController {
	var audioUnit: AUAudioUnit?

	public override func viewDidLoad() {
		super.viewDidLoad()

		if audioUnit == nil {
			return
		}

		// Get the parameter tree and add observers for any parameters that the UI needs to keep in sync with the AudioUnit
	}

}


/*
Abstract:
AUv3FilterDemoViewController is the app extension's principal class, responsible for creating both the audio unit and its view.
*/

//import CoreAudioKit
//import BasicSynth1Framework

extension BasicSynth1AudioUnitViewController: AUAudioUnitFactory {

	public func createAudioUnit(with componentDescription: AudioComponentDescription) throws -> AUAudioUnit {
		audioUnit = try BasicSynth1AudioUnit(componentDescription: componentDescription, options: [])
		return audioUnit!
	}

}
