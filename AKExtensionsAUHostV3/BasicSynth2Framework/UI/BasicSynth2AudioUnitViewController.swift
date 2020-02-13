//
//  AudioUnitViewController.swift
//  BasicSynth2
//
//  Created by Stanley Rosenbaum on 2/6/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import CoreAudioKit

open class BasicSynth2AudioUnitViewController: AUViewController {

	public var audioUnit: BasicSynth2AudioUnit? {
		didSet {
			audioUnit?.viewController = self
			/*
			We may be on a dispatch worker queue processing an XPC request at
			this time, and quite possibly the main queue is busy creating the
			view. To be thread-safe, dispatch onto the main queue.

			It's also possible that we are already on the main queue, so to
			protect against deadlock in that case, dispatch asynchronously.
			*/
			performOnMain {
				if self.isViewLoaded {
					self.connectViewToAU()
				}
			}
		}
	}

    private var pulseWidthParameter: AUParameter?
	private var filterCutoffParameter: AUParameter?
	private var parameterObserverToken: AUParameterObserverToken?

	@IBOutlet weak var pulseWidthSlider: UISlider!
	@IBOutlet weak var filterCutoffSlider: UISlider!

	var observer: NSKeyValueObservation?

	var needsConnection = true

    public override func viewDidLoad() {
        super.viewDidLoad()
        
        if audioUnit == nil {
            return
        }
        
        // Get the parameter tree and add observers for any parameters that the UI needs to keep in sync with the AudioUnit
    }


	@IBAction func pulseWidthSliderChange(_ sender: UISlider) {
		guard let thePulseWidthParameter = pulseWidthParameter else { return }
		update(parameter: thePulseWidthParameter, with: sender.value)
	}

	@IBAction func filterCutoffSliderChange(_ sender: UISlider) {
		guard let theFilterCutoffParameter = filterCutoffParameter else {
			print("NO FILTER VALUE")
			return
		}
		print("New Filter Cutoff \(theFilterCutoffParameter.value)")
		update(parameter: theFilterCutoffParameter, with: sender.value)
	}


	func update(parameter: AUParameter, with value: Float) {
		parameter.value = value
	}

	func performOnMain(_ operation: @escaping () -> Void) {
		if Thread.isMainThread {
			operation()
		} else {
			DispatchQueue.main.async {
				operation()
			}
		}
	}

	private func connectViewToAU() {
		guard needsConnection, let paramTree = audioUnit?.parameterTree else { return }

		// Find the cutoff and resonance parameters in the parameter tree.
		guard
			let pulseWidth = paramTree.value(forKey: "pulseWidth") as? AUParameter,
			let filterCutoff = paramTree.value(forKey: "filterCutoffFrequency") as? AUParameter else {
				fatalError("Required AU parameters not found.")
		}

		// Set the instance variables.
		pulseWidthParameter = pulseWidth
		filterCutoffParameter = filterCutoff

		// Observe major state changes like a user selecting a user preset.
		observer = audioUnit?.observe(\.allParameterValues) { object, change in
			DispatchQueue.main.async {
				self.updateUI()
			}
		}

		// Observe value changes made to the cutoff and resonance parameters.
		parameterObserverToken =
			paramTree.token(byAddingParameterObserver: { [weak self] address, value in
				guard let self = self else { return }

				// This closure is being called by an arbitrary queue. Ensure
				// all UI updates are dispatched back to the main thread.
				if [pulseWidth.address].contains(address) {
					DispatchQueue.main.async {
						self.updateUI()
					}
				}
			})

		// Indicate the view and AU are connected
		needsConnection = false

		// Sync UI with parameter state
//		updateUI()
	}


	private func updateUI() {

		guard
			let thePulseWidthParameter = pulseWidthParameter,
			let theFilterCutoffParameter = filterCutoffParameter else {
				return
		}

		// Set latest values on graph view
		pulseWidthSlider.value = thePulseWidthParameter.value
		filterCutoffSlider.value = theFilterCutoffParameter.value

		// Set latest text field values
//		frequencyTextField.text = cutoffParameter.string(fromValue: nil)
//		resonanceTextField.text = resonanceParameter.string(fromValue: nil)

	}
    
}
