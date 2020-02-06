//
//  BasicSynth1AudioUnitViewControllerExtension.swift
//  BasicSynth1
//
//  Created by Stanley Rosenbaum on 2/6/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import CoreAudioKit
import BasicSynth1Framework

extension BasicSynth1AudioUnitViewController: AUAudioUnitFactory {

	public func createAudioUnit(with componentDescription: AudioComponentDescription) throws -> AUAudioUnit {
		audioUnit = try BasicSynth1(componentDescription: componentDescription, options: [])
		return audioUnit!
	}

}
