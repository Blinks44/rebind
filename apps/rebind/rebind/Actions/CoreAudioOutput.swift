import AudioToolbox
import CoreAudio

// Volume uses the HAL's virtual main volume, the control behind the system volume
// keys: it also covers devices with channel-only controls (Bluetooth headsets in
// the hands-free mode, many USB/HDMI outputs) and keeps their channel balance.
// Mute stays the public main-element control.
nonisolated enum CoreAudioOutput {
    static let volumeStep: Float32 = 1.0 / 16.0

    static func capabilities() -> AudioOutputCapabilities {
        guard let device = defaultDevice() else { return AudioOutputCapabilities() }
        return AudioOutputCapabilities(deviceID: device,
            volume: settable(device, selector: volumeSelector) && volume(device) != nil,
            mute: settable(device, selector: kAudioDevicePropertyMute) && muted(device) != nil)
    }

    static func adjustedVolume(_ current: Float32, action: SystemAction) -> Float32? {
        guard current.isFinite, (0...1).contains(current) else { return nil }
        switch action {
        case .volumeUp: return min(1, current + volumeStep)
        case .volumeDown: return max(0, current - volumeStep)
        case .toggleMute: return nil
        }
    }

    static func perform(_ action: SystemAction, device: UInt32) -> Bool {
        // Never redirect an already queued action to a newly selected output.
        guard defaultDevice() == device else { return false }
        switch action {
        case .volumeUp, .volumeDown:
            guard settable(device, selector: volumeSelector),
                  let current = volume(device), let adjusted = adjustedVolume(current, action: action) else { return false }
            var address = outputAddress(volumeSelector)
            var value = adjusted
            return AudioObjectSetPropertyData(device, &address, 0, nil, UInt32(MemoryLayout<Float32>.size), &value) == noErr
        case .toggleMute:
            guard settable(device, selector: kAudioDevicePropertyMute), let current = muted(device) else { return false }
            var address = outputAddress(kAudioDevicePropertyMute)
            var value: UInt32 = current ? 0 : 1
            return AudioObjectSetPropertyData(device, &address, 0, nil, UInt32(MemoryLayout<UInt32>.size), &value) == noErr
        }
        // Core Audio acceptance is not an acoustic/delivery acknowledgement.
    }

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
