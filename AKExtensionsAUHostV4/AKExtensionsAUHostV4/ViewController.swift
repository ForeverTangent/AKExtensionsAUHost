//
//  ViewController.swift
//  AKExtensionsAUHostV4
//
//  Created by Stanley Rosenbaum on 2/13/20.
//  Copyright © 2020 STAQUE. All rights reserved.
//

import UIKit


class ViewController: UIViewController {


	var midiManager = MIDIManager.shared

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.

		midiManager.initMIDI()
	}


}

