import CoreAudio

/// Changes only the default input's advertised main mute control; never opens an audio stream.
nonisolated enum CoreAudioInput {
    static func defaultDevice() -> AudioDeviceID? {
        var address = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
        var device: AudioDeviceID = kAudioObjectUnknown
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        guard AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &device) == noErr,
              size == MemoryLayout<AudioDeviceID>.size, device != kAudioObjectUnknown else { return nil }
        return device
    }

    static func supportsMute(_ device: AudioDeviceID) -> Bool {
        var address = muteAddress
        var writable: DarwinBoolean = false
        return AudioObjectHasProperty(device, &address)
            && AudioObjectIsPropertySettable(device, &address, &writable) == noErr
            && writable.boolValue && muted(device) != nil
    }

    static func toggleMute(device: AudioDeviceID, canPerform: () -> Bool,
                           defaultDevice: () -> AudioDeviceID? = { Self.defaultDevice() },
                           read: (AudioDeviceID) -> Bool? = { muted($0) },
                           write: (AudioDeviceID, Bool) -> Bool = { setMuted($1, device: $0) }) -> WindowActionResult {
        guard canPerform() else { return .cancelled }
        guard defaultDevice() == device, let current = read(device) else { return .unavailable }
        guard canPerform() else { return .cancelled }
        // A queued command must never mute a replacement microphone.
        guard defaultDevice() == device else { return .unavailable }
        guard canPerform() else { return .cancelled }
        return write(device, !current) ? .performed : .unavailable
    }

    private static var muteAddress: AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyMute, mScope: kAudioObjectPropertyScopeInput,
                                   mElement: kAudioObjectPropertyElementMain)
    }

    private static func muted(_ device: AudioDeviceID) -> Bool? {
        var address = muteAddress
        var value: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        guard AudioObjectGetPropertyData(device, &address, 0, nil, &size, &value) == noErr,
              size == MemoryLayout<UInt32>.size, value <= 1 else { return nil }
        return value != 0
    }

    private static func setMuted(_ muted: Bool, device: AudioDeviceID) -> Bool {
        var address = muteAddress
        var value: UInt32 = muted ? 1 : 0
        return AudioObjectSetPropertyData(device, &address, 0, nil, UInt32(MemoryLayout<UInt32>.size), &value) == noErr
    }
}
