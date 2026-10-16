// Audio output volume probe for the volume/mute actions. Not part of Rebind.app.
//
//   DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun swift apps/rebind/tools/audio-output-probe.swift
//
// Lists output devices and which volume and mute controls each one exposes:
// the virtual main volume Rebind uses, the main-element volume and the first
// two channels. Read-only: nothing is changed and no permission is required.

import AudioToolbox
import CoreAudio

func address(_ selector: AudioObjectPropertySelector, _ scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeOutput,
             _ element: AudioObjectPropertyElement = kAudioObjectPropertyElementMain) -> AudioObjectPropertyAddress {
    AudioObjectPropertyAddress(mSelector: selector, mScope: scope, mElement: element)
}

func describe(_ device: AudioObjectID, _ selector: AudioObjectPropertySelector, element: AudioObjectPropertyElement = 0) -> String {
    var target = address(selector, kAudioObjectPropertyScopeOutput, element)
    guard AudioObjectHasProperty(device, &target) else { return "-" }
    var writable: DarwinBoolean = false
    let settable = AudioObjectIsPropertySettable(device, &target, &writable) == noErr && writable.boolValue
    var value: Float32 = 0
    var size = UInt32(MemoryLayout<Float32>.size)
    let read = AudioObjectGetPropertyData(device, &target, 0, nil, &size, &value) == noErr
    // Mute is a 32-bit integer; its bits are read through the same 4-byte buffer.
    let shown = selector == kAudioDevicePropertyMute ? String(value.bitPattern) : String(format: "%.3f", value)
    return (settable ? "rw " : "ro ") + (read ? shown : "unreadable")
}

let system = AudioObjectID(kAudioObjectSystemObject)
var devicesAddress = address(kAudioHardwarePropertyDevices, kAudioObjectPropertyScopeGlobal)
var size: UInt32 = 0
AudioObjectGetPropertyDataSize(system, &devicesAddress, 0, nil, &size)
var devices = [AudioObjectID](repeating: 0, count: Int(size) / MemoryLayout<AudioObjectID>.size)
AudioObjectGetPropertyData(system, &devicesAddress, 0, nil, &size, &devices)

var defaultAddress = address(kAudioHardwarePropertyDefaultOutputDevice, kAudioObjectPropertyScopeGlobal)
var defaultDevice = AudioObjectID(kAudioObjectUnknown)
size = UInt32(MemoryLayout<AudioObjectID>.size)
AudioObjectGetPropertyData(system, &defaultAddress, 0, nil, &size, &defaultDevice)

for device in devices {
    var streams = address(kAudioDevicePropertyStreams)
    var streamSize: UInt32 = 0
    guard AudioObjectGetPropertyDataSize(device, &streams, 0, nil, &streamSize) == noErr, streamSize > 0 else { continue }
    var nameAddress = address(kAudioObjectPropertyName, kAudioObjectPropertyScopeGlobal)
    var name: Unmanaged<CFString>?
    size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
    AudioObjectGetPropertyData(device, &nameAddress, 0, nil, &size, &name)
    let marker = device == defaultDevice ? "* " : "  "
    print(marker + (name?.takeRetainedValue() as String? ?? "Unnamed output"))
    print("    virtual main volume: \(describe(device, kAudioHardwareServiceDeviceProperty_VirtualMainVolume))")
    print("    main volume: \(describe(device, kAudioDevicePropertyVolumeScalar)), "
          + "channel 1: \(describe(device, kAudioDevicePropertyVolumeScalar, element: 1)), "
          + "channel 2: \(describe(device, kAudioDevicePropertyVolumeScalar, element: 2))")
    print("    mute: \(describe(device, kAudioDevicePropertyMute))")
}
print("* = current output")
