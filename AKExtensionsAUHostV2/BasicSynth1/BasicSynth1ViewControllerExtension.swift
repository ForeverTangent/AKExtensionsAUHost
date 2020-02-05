//
//  BasicSynth1ViewControllerExtension.swift
//  BasicSynth1
//
//  Created by Stanley Rosenbaum on 2/5/20.
//  Copyright © 2020 Apple. All rights reserved.
//

/*
Abstract:
AUv3FilterDemoViewController is the app extension's principal class, responsible for creating both the audio unit and its view.
*/

import CoreAudioKit
import BasicSynth1Framework

extension BasicSynth1AudioUnitViewController: AUAudioUnitFactory {

	public func createAudioUnit(with componentDescription: AudioComponentDescription) throws -> AUAudioUnit {
		audioUnit = try BasicSynth1AudioUnit(componentDescription: componentDescription, options: [])
		return audioUnit!
	}

}

