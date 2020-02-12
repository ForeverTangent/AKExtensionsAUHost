//
//  BasicSynth2Parameters.swift
//  BasicSynth2
//
//  Created by Stanley Rosenbaum on 2/6/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import Foundation
import AudioToolbox

/// Manages the BasicSynth2 object's paramOne.
class BasicSynth2AudioUnitParameters {

    public enum BasicSynth2AUParameters: AUParameterAddress {
		case attackDuration
		case decayDuration
		case sustainLevel
		case releaseDuration
		case pitchBend
		case pulseWidth
		case filterCutoffFrequency
		case filterAttackDuration
		case filterDecayDuration
		case filterSustainLevel
		case filterReleaseDuration
		case filterEnvelopeStrength
    }

	var attackDurationAUParameter : AUParameter = {
		let parameter =
			AUParameterTree.createParameter(withIdentifier: "attackDuration",
											name: "Attack",
											address: BasicSynth2AUParameters.attackDuration.rawValue,
											min: 0,
											max: 1,
											unit: .seconds,
											unitName: nil,
											flags: [.flag_IsReadable,
													.flag_IsWritable],
											valueStrings: nil,
											dependentParameters: nil)
		// Set default value
		parameter.value = 0

		return parameter
	}()

	var decayDurationAUParameter : AUParameter = {
		let parameter =
			AUParameterTree.createParameter(withIdentifier: "decayDuration",
											name: "Decay",
											address: BasicSynth2AUParameters.decayDuration.rawValue,
											min: 0,
											max: 1,
											unit: .seconds,
											unitName: nil,
											flags: [.flag_IsReadable,
													.flag_IsWritable],
											valueStrings: nil,
											dependentParameters: nil)
		// Set default value
		parameter.value = 0

		return parameter
	}()

	var sustainLevelAUParameter : AUParameter = {
		let parameter =
			AUParameterTree.createParameter(withIdentifier: "sustainLevel",
											name: "Sustain",
											address: BasicSynth2AUParameters.sustainLevel.rawValue,
											min: 0,
											max: 1,
											unit: .generic,
											unitName: nil,
											flags: [.flag_IsReadable,
													.flag_IsWritable],
											valueStrings: nil,
											dependentParameters: nil)
		// Set default value
		parameter.value = 0

		return parameter
	}()

	var releaseDurationAUParameter : AUParameter = {
		let parameter =
			AUParameterTree.createParameter(withIdentifier: "releaseDuration",
											name: "Release",
											address: BasicSynth2AUParameters.releaseDuration.rawValue,
											min: 0,
											max: 1,
											unit: .seconds,
											unitName: nil,
											flags: [.flag_IsReadable,
													.flag_IsWritable],
											valueStrings: nil,
											dependentParameters: nil)
		// Set default value
		parameter.value = 0

		return parameter
	}()

	var pitchBendAUParameter : AUParameter = {
		let parameter =
			AUParameterTree.createParameter(withIdentifier: "pitchBend",
											name: "Pitch Bend",
											address: BasicSynth2AUParameters.pitchBend.rawValue,
											min: -48,
											max: 48,
											unit: .relativeSemiTones,
											unitName: nil,
											flags: [],
											valueStrings: nil,
											dependentParameters: nil)
		// Set default value
		parameter.value = 0

		return parameter
	}()

	var pulseWidthAUParameter : AUParameter = {
		let parameter =
			AUParameterTree.createParameter(withIdentifier: "pulseWidth",
											name: "Pulse Width",
											address: BasicSynth2AUParameters.pulseWidth.rawValue,
											min: 0.001,
											max: 0.5,
											unit: .generic,
											unitName: nil,
											flags: [.flag_IsReadable,
													.flag_IsWritable],
											valueStrings: nil,
											dependentParameters: nil)
		// Set default value
		parameter.value = 0.5

		return parameter
	}()

	var filterCutoffFrequencyAUParameter : AUParameter = {
		let parameter =
			AUParameterTree.createParameter(withIdentifier: "filterCutoffFrequency",
											name: "Filter Cutoff Frequency",
											address: BasicSynth2AUParameters.filterCutoffFrequency.rawValue,
											min: 0.0,
											max: 22050.0,
											unit: .generic,
											unitName: nil,
											flags: [.flag_IsReadable,
													.flag_IsWritable],
											valueStrings: nil,
											dependentParameters: nil)
		// Set default value
		parameter.value = 11025

		return parameter
	}()

	var filterAttackDurationAUParameter : AUParameter = {
		let parameter =
			AUParameterTree.createParameter(withIdentifier: "filterAttackDuration",
											name: "Filter Attack Duration",
											address: BasicSynth2AUParameters.filterAttackDuration.rawValue,
											min: 0.0,
											max: 1.0,
											unit: .generic,
											unitName: nil,
											flags: [.flag_IsReadable,
													.flag_IsWritable],
											valueStrings: nil,
											dependentParameters: nil)
		// Set default value
		parameter.value = 0.1

		return parameter
	}()

	var filterDecayDurationAUParameter : AUParameter = {
		let parameter =
			AUParameterTree.createParameter(withIdentifier: "filterDecayDuration",
											name: "Filter Decay Duration",
											address: BasicSynth2AUParameters.filterDecayDuration.rawValue,
											min: 0.0,
											max: 1.0,
											unit: .generic,
											unitName: nil,
											flags: [.flag_IsReadable,
													.flag_IsWritable],
											valueStrings: nil,
											dependentParameters: nil)
		// Set default value
		parameter.value = 0.1

		return parameter
	}()

	var filterSustainLevelAUParameter : AUParameter = {
		let parameter =
			AUParameterTree.createParameter(withIdentifier: "filterSustainLevel",
											name: "Filter Sustain Level",
											address: BasicSynth2AUParameters.filterSustainLevel.rawValue,
											min: 0.0,
											max: 1.0,
											unit: .generic,
											unitName: nil,
											flags: [.flag_IsReadable,
													.flag_IsWritable],
											valueStrings: nil,
											dependentParameters: nil)
		// Set default value
		parameter.value = 1.0

		return parameter
	}()

	var filterReleaseDurationAUParameter : AUParameter = {
		let parameter =
			AUParameterTree.createParameter(withIdentifier: "filterReleaseDuration",
											name: "Filter Release Duration",
											address: BasicSynth2AUParameters.filterReleaseDuration.rawValue,
											min: 0.0,
											max: 1.0,
											unit: .generic,
											unitName: nil,
											flags: [.flag_IsReadable,
													.flag_IsWritable],
											valueStrings: nil,
											dependentParameters: nil)
		// Set default value
		parameter.value = 0.1

		return parameter
	}()

	var filterEnvelopeStrengthAUParameter : AUParameter = {
		let parameter =
			AUParameterTree.createParameter(withIdentifier: "filterEnvelopeStrength",
											name: "Filter Envelope Strength",
											address: BasicSynth2AUParameters.filterEnvelopeStrength.rawValue,
											min: 0.0,
											max: 1.0,
											unit: .generic,
											unitName: nil,
											flags: [.flag_IsReadable,
													.flag_IsWritable],
											valueStrings: nil,
											dependentParameters: nil)
		// Set default value
		parameter.value = 0.0

		return parameter
	}()

    let parameterTree: AUParameterTree

    init(kernelAdapter: BasicSynth2DSPKernelAdapter) {

        // Create the audio unit's tree of parameters
        parameterTree = AUParameterTree.createTree(withChildren: [
			attackDurationAUParameter,
			decayDurationAUParameter,
			sustainLevelAUParameter,
			releaseDurationAUParameter,
			pitchBendAUParameter,
			pulseWidthAUParameter,
			filterCutoffFrequencyAUParameter,
			filterAttackDurationAUParameter,
			filterDecayDurationAUParameter,
			filterSustainLevelAUParameter,
			filterReleaseDurationAUParameter,
			filterEnvelopeStrengthAUParameter,
		])


        // Closure observing all externally-generated parameter value changes.
        parameterTree.implementorValueObserver = { param, value in
            kernelAdapter.setParameter(param, value: value)
        }

        // Closure returning state of requested parameter.
        parameterTree.implementorValueProvider = { param in
            return kernelAdapter.value(for: param)
        }

        // Closure returning string representation of requested parameter value.
		parameterTree.implementorStringFromValueCallback = { param, value in
			switch param.address {
				case BasicSynth2AUParameters.attackDuration.rawValue:
					return String(format: "%.f", value ?? param.value)
				case BasicSynth2AUParameters.decayDuration.rawValue:
					return String(format: "%.f", value ?? param.value)
				case BasicSynth2AUParameters.sustainLevel.rawValue:
					return String(format: "%.f", value ?? param.value)
				case BasicSynth2AUParameters.releaseDuration.rawValue:
					return String(format: "%.f", value ?? param.value)
				case BasicSynth2AUParameters.pitchBend.rawValue:
					return String(format: "%.f", value ?? param.value)
				case BasicSynth2AUParameters.pulseWidth.rawValue:
					return String(format: "%.f", value ?? param.value)
				case BasicSynth2AUParameters.filterCutoffFrequency.rawValue:
					return String(format: "%.f", value ?? param.value)
				case BasicSynth2AUParameters.filterAttackDuration.rawValue:
					return String(format: "%.f", value ?? param.value)
				case BasicSynth2AUParameters.filterDecayDuration.rawValue:
					return String(format: "%.f", value ?? param.value)
				case BasicSynth2AUParameters.filterSustainLevel.rawValue:
					return String(format: "%.f", value ?? param.value)
				case BasicSynth2AUParameters.filterReleaseDuration.rawValue:
					return String(format: "%.f", value ?? param.value)
				case BasicSynth2AUParameters.filterEnvelopeStrength.rawValue:
					return String(format: "%.f", value ?? param.value)
				default:
					return "?"
			}
		}
    }

	func setParameter(_ parameter: BasicSynth2AUParameters, with value: AUValue) {
		switch parameter {
			case .attackDuration:
				attackDurationAUParameter.value = value
			case .decayDuration:
				decayDurationAUParameter.value = value
			case .sustainLevel:
				sustainLevelAUParameter.value = value
			case .releaseDuration:
				releaseDurationAUParameter.value = value
			case .pitchBend:
				pitchBendAUParameter.value = value
			case .pulseWidth:
				pulseWidthAUParameter.value = value
			case .filterCutoffFrequency:
				filterCutoffFrequencyAUParameter.value = value
			case .filterAttackDuration:
				filterAttackDurationAUParameter.value = value
			case .filterDecayDuration:
				filterDecayDurationAUParameter.value = value
			case .filterSustainLevel:
				filterSustainLevelAUParameter.value = value
			case .filterReleaseDuration:
				filterReleaseDurationAUParameter.value = value
			case .filterEnvelopeStrength:
				filterEnvelopeStrengthAUParameter.value = value
		}
	}
}
