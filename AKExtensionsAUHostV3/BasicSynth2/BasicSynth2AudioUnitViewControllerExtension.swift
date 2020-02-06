//
//  BasicSynth2AudioUnitViewControllerExtension.swift
//  BasicSynth2
//
//  Created by Stanley Rosenbaum on 2/6/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import CoreAudioKit
import BasicSynth2Framework

extension BasicSynth2AudioUnitViewController: AUAudioUnitFactory {

	public func createAudioUnit(with componentDescription: AudioComponentDescription) throws -> AUAudioUnit {
		audioUnit = try BasicSynth2AudioUnit(componentDescription: componentDescription, options: [])

		return audioUnit!
	}

}
