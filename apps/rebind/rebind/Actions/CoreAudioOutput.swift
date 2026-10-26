import AudioToolbox
import CoreAudio
import Dispatch

// Read-only capability checks for the default output. The actions themselves are
// system sound keys (MediaKeySender), so macOS applies them and shows its HUD.
// Volume checks the HAL's virtual main volume, the control behind those keys: it
// also covers channel-only outputs (Bluetooth headsets in the hands-free mode,
// many USB/HDMI outputs). Mute checks the public main-element control.
nonisolated enum CoreAudioOutput {
    static func capabilities() -> AudioOutputCapabilities {
        guard let device = defaultDevice() else { return AudioOutputCapabilities() }
        return AudioOutputCapabilities(deviceID: device,
            volume: settable(device, selector: volumeSelector) && volume(device) != nil,
            mute: settable(device, selector: kAudioDevicePropertyMute) && muted(device) != nil)
    }

    /// Never redirect an already queued action to a newly selected output.
    static func isDefaultOutput(_ device: UInt32) -> Bool { defaultDevice() == device }

    private static func defaultDevice() -> AudioDeviceID? {
        var address = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
        var device: AudioDeviceID = kAudioObjectUnknown
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        guard AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &device) == noErr,
              size == MemoryLayout<AudioDeviceID>.size, device != kAudioObjectUnknown else { return nil }
        return device
    }

    private static func outputAddress(_ selector: AudioObjectPropertySelector) -> AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(mSelector: selector, mScope: kAudioObjectPropertyScopeOutput,
                                   mElement: kAudioObjectPropertyElementMain)
    }

    private static func settable(_ device: AudioDeviceID, selector: AudioObjectPropertySelector) -> Bool {
        var address = outputAddress(selector)
        var writable: DarwinBoolean = false
        return AudioObjectHasProperty(device, &address)
            && AudioObjectIsPropertySettable(device, &address, &writable) == noErr && writable.boolValue
    }

    private static let volumeSelector = kAudioHardwareServiceDeviceProperty_VirtualMainVolume

    private static func volume(_ device: AudioDeviceID) -> Float32? {
        var address = outputAddress(volumeSelector)
        var value: Float32 = 0
        var size = UInt32(MemoryLayout<Float32>.size)
        guard AudioObjectGetPropertyData(device, &address, 0, nil, &size, &value) == noErr,
              size == MemoryLayout<Float32>.size, value.isFinite, (0...1).contains(value) else { return nil }
        return value
    }

    private static func muted(_ device: AudioDeviceID) -> Bool? {
        var address = outputAddress(kAudioDevicePropertyMute)
        var value: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        guard AudioObjectGetPropertyData(device, &address, 0, nil, &size, &value) == noErr,
              size == MemoryLayout<UInt32>.size, value <= 1 else { return nil }
        return value != 0
    }
}

/// Owned by the action thread. HAL callbacks only invalidate the cache and wake that thread;
/// no audio queries or actor hops run on Core Audio's notification thread.
nonisolated final class CoreAudioOutputMonitor {
    private let listener: AudioObjectPropertyListenerBlock
    private var selectors: [AudioObjectPropertySelector] = []

    init(changed: @escaping @Sendable () -> Void) {
        listener = { _, _ in changed() }
        for selector in [kAudioHardwarePropertyDefaultOutputDevice, kAudioHardwarePropertyDevices] {
            var address = Self.address(selector)
            if AudioObjectAddPropertyListenerBlock(AudioObjectID(kAudioObjectSystemObject), &address,
                                                  nil, listener) == noErr {
                selectors.append(selector)
            }
        }
    }

    func stop() {
        for selector in selectors {
            var address = Self.address(selector)
            AudioObjectRemovePropertyListenerBlock(AudioObjectID(kAudioObjectSystemObject), &address, nil, listener)
        }
        selectors = []
    }

    private static func address(_ selector: AudioObjectPropertySelector) -> AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(mSelector: selector, mScope: kAudioObjectPropertyScopeGlobal,
                                   mElement: kAudioObjectPropertyElementMain)
    }
}
