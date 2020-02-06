/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The manager object used to find and instantiate audio units and manage their presets and view configurations.
*/

import Foundation
import CoreAudioKit
import AVFoundation

#if os(iOS)
import UIKit
public typealias ViewController = UIViewController
#elseif os(macOS)
import AppKit
public typealias ViewController = NSViewController
#endif

// An enum used to prevent exposing the Core Audio component description's componentType to the UI layer.
enum AudioUnitType: Int {
    case effect
    case instrument
}

// An enum used to prevent exposing the Core Audio AudioComponentInstantiationOptions to the UI layer.
enum InstantiationType: Int {
    case inProcess
    case outOfProcess
}

enum PresetType: Int {
    case factory
    case user
}

enum UserPresetsChangeType: Int {
    case save
    case delete
    case external
    case undefined
}

struct UserPresetsChange {
    let type: UserPresetsChangeType
    let userPresets: [Preset]
}

extension Notification.Name {
    static let userPresetsChanged = Notification.Name("userPresetsChanged")
}

// A simple wrapper type to prevent exposing the Core Audio AUAudioUnitPreset in the UI layer.
public struct Preset {
    init(name: String) {
        let preset = AUAudioUnitPreset()
        preset.name = name
        preset.number = -1
        self.init(preset: preset)
    }
    fileprivate init(preset: AUAudioUnitPreset) {
        audioUnitPreset = preset
    }
    fileprivate let audioUnitPreset: AUAudioUnitPreset
    public var number: Int { return audioUnitPreset.number }
    public var name: String { return audioUnitPreset.name }
}

public struct Component {

    private let audioUnitType: AudioUnitType
    fileprivate let avAudioUnitComponent: AVAudioUnitComponent?

    fileprivate init(_ component: AVAudioUnitComponent?, type: AudioUnitType) {
        audioUnitType = type
        avAudioUnitComponent = component
    }

    public var name: String {
        guard let component = avAudioUnitComponent else {
            return audioUnitType == .effect ? "(No Effect)" : "(No Instrument)"
        }
        return "\(component.name) (\(component.manufacturerName))"
    }

    public var hasCustomView: Bool {
        #if os(macOS)
        return avAudioUnitComponent?.hasCustomView ?? false
        #else
        return false
        #endif
    }
}

// Manages the interaction with the AudioToolbox and AVFoundation frameworks.
class AudioUnitManager {

    // Filter out these AUs. They don't make sense for this demo.
    var filterClosure: (AVAudioUnitComponent) -> Bool = {
        let blacklist = ["AUNewPitch", "AURoundTripAAC", "AUNetSend"]
        var allowed = !blacklist.contains($0.name)
        #if os(macOS)
        if allowed && $0.typeName == AVAudioUnitTypeEffect {
            allowed = $0.hasCustomView
        }
        #endif
        return allowed
    }
    
    var observer: NSKeyValueObservation?
    var userPresetChangeType: UserPresetsChangeType = .undefined

    /// The user-selected audio unit.
    private var audioUnit: AUAudioUnit? {
        didSet {
            // A new audio unit was selected. Reset our internal state.
            observer = nil
            userPresetChangeType = .undefined

            // If the selected audio unit doesn't support user presets, return.
            guard audioUnit?.supportsUserPresets ?? false else { return }
            
            // Start observing the selected audio unit's "userPresets" property.
            observer = audioUnit?.observe(\.userPresets) { _, _ in
                DispatchQueue.main.async {
                    var changeType = self.userPresetChangeType
                    // If the change wasn't triggered by a user save or delete, it changed
                    // due to an external add or remove from the presets folder.
                    if ![.save, .delete].contains(changeType) {
                        changeType = .external
                    }
                    
                    // Post a notification to any registered listeners.
                    let change = UserPresetsChange(type: changeType, userPresets: self.userPresets)
                    NotificationCenter.default.post(name: .userPresetsChanged, object: change)
                    
                    // Reset property to its default value
                    self.userPresetChangeType = .undefined
                }
            }
        }
    }

    /// The serial dispatch queue used to control access to the AVAudioUnitComponent array.
    private let componentsAccessQueue = DispatchQueue(label: "com.example.apple-samplecode.ComponentsAccessQueue")

    private var _components = [Component]()

    /// The loaded AVAudioUnitComponent objects.
    private var components: [Component] {
        // This property can be accessed by multiple threads. Synchronize reads/writes.
        get {
            var array = [Component]()
            componentsAccessQueue.sync {
                array = _components
            }
            return array
        }
        set {
            componentsAccessQueue.sync {
                _components = newValue
            }
        }
    }

    /// The playback engine used to play audio.
    private let playEngine = SimplePlayEngine()

    private var options = AudioComponentInstantiationOptions.loadOutOfProcess

    /// Determines how the audio unit is instantiated.
    @available(iOS, unavailable)
    var instantiationType = InstantiationType.outOfProcess {
        didSet {
            options = instantiationType == .inProcess ? .loadInProcess : .loadOutOfProcess
        }
    }

    // MARK: Preset Management

    /// Gets the audio unit's factory presets.
    public var factoryPresets: [Preset] {
        guard let presets = audioUnit?.factoryPresets else { return [] }
        return presets.map { Preset(preset: $0) }
    }

    /// Get or set the audio unit's current preset.
    public var currentPreset: Preset? {
        get {
            guard let preset = audioUnit?.currentPreset else { return nil }
            return Preset(preset: preset)
        }
        set {
            audioUnit?.currentPreset = newValue?.audioUnitPreset
        }
    }
    
    // MARK: User Presets
    
    /// Gets the audio unit's user presets.
    public var userPresets: [Preset] {
        guard let presets = audioUnit?.userPresets else { return [] }
        return presets.map { Preset(preset: $0) }.reversed()
    }
    
    public func savePreset(_ preset: Preset) throws {
        userPresetChangeType = .save
        try audioUnit?.saveUserPreset(preset.audioUnitPreset)
    }
    
    public func deletePreset(_ preset: Preset) throws {
        userPresetChangeType = .delete
        try audioUnit?.deleteUserPreset(preset.audioUnitPreset)
    }
    
    var supportsUserPresets: Bool {
        return audioUnit?.supportsUserPresets ?? false
    }

    // MARK: View Configuration

    var preferredWidth: CGFloat {
        return viewConfigurations[currentViewConfigurationIndex].width
    }

    private var currentViewConfigurationIndex = 1

    /// View configurations supported by the host app
    private var viewConfigurations: [AUAudioUnitViewConfiguration] = {
        let compact = AUAudioUnitViewConfiguration(width: 400, height: 100, hostHasController: false)
        let expanded = AUAudioUnitViewConfiguration(width: 800, height: 500, hostHasController: false)
        return [compact, expanded]
    }()

    /// Determines if the selected AU provides more than one user interface.
    var providesAlterativeViews: Bool {
        guard let audioUnit = audioUnit else { return false }
        let supportedConfigurations = audioUnit.supportedViewConfigurations(viewConfigurations)
        return supportedConfigurations.count > 1
    }

    /// Determines if the selected AU provides provides user interface.
    var providesUserInterface: Bool {
        return audioUnit?.providesUserInterface ?? false
    }

    /// Toggles the current view mode (compact or expanded)
    func toggleViewMode() {
        guard let audioUnit = audioUnit else { return }
        currentViewConfigurationIndex = currentViewConfigurationIndex == 0 ? 1 : 0
        audioUnit.select(viewConfigurations[currentViewConfigurationIndex])
    }

    // MARK: Load Audio Units

    func loadAudioUnits(ofType type: AudioUnitType, completion: @escaping ([Component]) -> Void) {

        // Reset the engine to remove any configured audio units.
        playEngine.reset()

        // Locating components is a blocking operation. Perform this work on a separate queue.
        DispatchQueue.global(qos: .default).async {

            let componentType = type == .effect ? kAudioUnitType_Effect : kAudioUnitType_MusicDevice

             // Make a component description matching any Audio Unit of the selected component type.
            let description = AudioComponentDescription(componentType: componentType,
                                                        componentSubType: 0,
                                                        componentManufacturer: 0,
                                                        componentFlags: 0,
                                                        componentFlagsMask: 0)

            let components = AVAudioUnitComponentManager.shared().components(matching: description)

            // Filter out components that don't make sense for this demo.
            // Map AVAudioUnitComponent to array of Component (view model) objects.
            var wrapped = components.filter(self.filterClosure).map { Component($0, type: type) }

            // Insert a "No Effect" element into array if effect
            if type == .effect {
                wrapped.insert(Component(nil, type: type), at: 0)
            }
            self.components = wrapped
            // Notify the caller of the loaded components.
            DispatchQueue.main.async {
                completion(wrapped)
            }
        }
    }

    // MARK: Instantiate an Audio Unit

    func selectComponent(at index: Int, completion: @escaping (Result<Bool, Error>) -> Void) {

        // nil out existing component
        audioUnit = nil

        // Get the wrapped AVAudioUnitComponent
        guard let component = components[index].avAudioUnitComponent else {
            // Reset the engine to remove any configured audio units.
            playEngine.reset()
            // Return success, but indicate an audio unit was not selected.
            // This occurrs when the user selects the (No Effect) row.
            completion(.success(false))
            return
        }

        // Get the component description
        let description = component.audioComponentDescription

        // Instantiate the audio unit and connect it the the play engine.
        AVAudioUnit.instantiate(with: description, options: options) { avAudioUnit, error in
            guard error == nil else {
                DispatchQueue.main.async {
                    completion(.failure(error!))
                }
                return
            }
            self.audioUnit = avAudioUnit?.auAudioUnit
            self.playEngine.connect(avAudioUnit: avAudioUnit) {
                DispatchQueue.main.async {
                    completion(.success(true))
                }
            }
        }
    }

    func loadAudioUnitViewController(completion: @escaping (ViewController?) -> Void) {
        if let audioUnit = audioUnit {
            audioUnit.requestViewController { viewController in
                DispatchQueue.main.async {
                    completion(viewController)
                }
            }
        } else {
            completion(nil)
        }
    }

    // MARK: Audio Transport

    @discardableResult
    func togglePlayback() -> Bool {
        return playEngine.togglePlay()
    }

	@discardableResult
	func toggleMIDIPlayback() -> Bool {
		return playEngine.toggleMIDIPlay()
	}

    func stopPlayback() {
        playEngine.stopPlaying()
    }

	func stopMIDIPlay() {
		playEngine.stopMIDIPlaying()
	}
}
