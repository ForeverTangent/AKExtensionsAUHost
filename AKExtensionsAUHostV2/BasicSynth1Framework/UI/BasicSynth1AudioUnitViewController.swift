//
//  BasicSynth1AudioUnitViewController.swift
//  BasicSynth1
//
//  Created by Stanley Rosenbaum on 2/5/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import CoreAudioKit

open class BasicSynth1AudioUnitViewController: AUViewController {
	public var audioUnit: AUAudioUnit?

	public override func viewDidLoad() {
		super.viewDidLoad()

		if audioUnit == nil {
			return
		}

		// Get the parameter tree and add observers for any parameters that the UI needs to keep in sync with the AudioUnit
	}

}


