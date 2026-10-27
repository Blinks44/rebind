import Foundation
import HIDPP
import Testing
@testable import rebind

private final class LightingKeyboard: HIDPPDeviceIO {
    let maxOutputReportSize: Int? = 20
    var flags: UInt8 = 0
    var events: UInt8 = 0x80
    var brightness: UInt16 = 50
    var powerMode: UInt8 = 1
    var failedZone: UInt8?
    var rejectsWake = false
    var brightnessInfo: [UInt8] = [0, 100, 5, 3, 0, 0, 0]
    var illumination = true
    var supportsDisabled = false
    var supportsPowerModes = true
    var writeObserved: (() -> Void)?
    private(set) var writes: [[UInt8]] = []

    func performSynchronousOutputReportRequest(_ report: Data, timeout: TimeInterval,
                                               matching: @escaping (Data) -> Bool) -> Data? {
        let b = Array(report)
        let function = b[3] >> 4
        var payload: [UInt8]
        switch (b[2], function) {
        case (20, 0): payload = brightnessInfo
        case (20, 1): payload = [UInt8(brightness >> 8), UInt8(brightness & 255)]
        case (20, 2): brightness = UInt16(b[4]) << 8 | UInt16(b[5]); payload = []
        case (20, 3): payload = [illumination ? 1 : 0]
        case (20, 4): illumination = b[4] != 0; payload = []
        case (10, 0):
            if b[4] == 255 { payload = [255, 0, 2, 0, 0, 0, 0, 0] }
            else if b[5] == 255 { payload = [b[4], 0, 0, 1, supportsDisabled ? 2 : 1, 0, 0, 0] }
            else { payload = [b[4], b[5], 0, supportsDisabled && b[5] == 1 ? 0 : 1, 0, 0, 0, 0] }
        case (10, 1):
            writes.append(b)
            writeObserved?()
            guard b[4] != failedZone else { return nil }
            payload = []
        case (10, 5):
            if b[4] == 1 { flags = b[5]; events = b[6] }
            payload = [b[4], flags, events]
        case (10, 8):
            guard supportsPowerModes else { return nil }
            if b[4] == 1 {
                guard !rejectsWake else { return nil }
                powerMode = b[5]
                writes.append(b)
            }
            payload = [b[4], powerMode]
        default: return nil
        }
        if (b[2] == 20 && function == 2) || (b[2] == 10 && function == 5 && b[4] == 1) {
            writes.append(b)
            writeObserved?()
        }
        let reply = Data(Array(b.prefix(4)) + payload + Array(repeating: 0, count: max(0, 16 - payload.count)))
        return matching(reply) ? reply : nil
    }
}

struct KeyboardLightingOwnershipTests {
    private func lighting(_ io: LightingKeyboard, ownership: KeyboardLightingOwnership) throws -> KeyboardLighting {
        let transport = try #require(HIDPPTransport(device: io, deviceIndex: 1))
        return try #require(KeyboardLighting(transport: transport, brightnessIndex: 20, rgbIndex: 10, ownership: ownership, slot: 1))
    }

    @Test func refreshRetainsClaimAndCleanupPreservesUnrelatedEventFlags() throws {
        let io = LightingKeyboard(), ownership = KeyboardLightingOwnership()
        let first = try lighting(io, ownership: ownership)
        let settings = KeyboardLightingSettings(deviceKey: "keyboard", color: 0x2080FF)
        #expect(first.apply(settings, percentage: 50, charging: false, canWrite: { true }))
        #expect(io.flags == 1 && io.events == 0x80)
        let refreshed = try lighting(io, ownership: ownership)
        #expect(refreshed.apply(settings, percentage: 50, charging: false, canWrite: { true }))
        ownership.releaseAll(canWrite: { true })
        #expect(io.flags == 0 && io.events == 0x80)
    }

    @Test func companionOwnershipAndRevokedWritesDoNotSendAnotherZone() throws {
        let io = LightingKeyboard(), ownership = KeyboardLightingOwnership()
        let feature = try lighting(io, ownership: ownership)
        let settings = KeyboardLightingSettings(deviceKey: "keyboard", color: 0x123456)
        io.flags = 1 // Someone else owns lighting; no Rebind claim exists.
        #expect(feature.apply(settings, percentage: 50, charging: false, canWrite: { true }) == false)
        #expect(io.writes.isEmpty)
        io.flags = 0
        var allowed = true
        io.writeObserved = {
            if let last = io.writes.last, last[2] == 10, last[3] >> 4 == 1 { allowed = false }
        }
        #expect(feature.apply(settings, percentage: 50, charging: false, canWrite: { allowed }) == false)
        #expect(io.writes.filter { $0[2] == 10 && $0[3] >> 4 == 1 }.count == 1)
    }

    @Test func failedFirstColorReturnsFirmwareOwnershipAndIdleBatteryRefreshWritesNothing() throws {
        let io = LightingKeyboard(), ownership = KeyboardLightingOwnership()
        let feature = try lighting(io, ownership: ownership)
        let settings = KeyboardLightingSettings(deviceKey: "keyboard", color: 0x123456, lowBattery: .red)
        io.failedZone = 1
        #expect(feature.apply(settings, percentage: 50, charging: false, canWrite: { true }) == false)
        #expect(io.flags == 0 && io.brightness == 50)
        let count = io.writes.count
        io.powerMode = 3
        #expect(feature.apply(settings, percentage: 8, charging: false, background: true, canWrite: { true }))
        #expect(io.writes.count == count)
        io.powerMode = 1
        #expect(feature.apply(settings, percentage: nil, charging: false, background: true, canWrite: { true }))
        #expect(io.writes.count == count)
    }

    @Test func explicitOnWakesNativeIdleAndReleasesOnlyItsTemporaryPowerLease() throws {
        let io = LightingKeyboard(), ownership = KeyboardLightingOwnership()
        let feature = try lighting(io, ownership: ownership)
        io.powerMode = 3
        let settings = KeyboardLightingSettings(deviceKey: "keyboard")
        #expect(feature.apply(settings, percentage: 50, charging: false, canWrite: { true }))
        #expect(io.powerMode == 1 && io.flags == 0 && io.events == 0x80)
        #expect(io.writes.contains { $0[2] == 10 && $0[3] >> 4 == 5 && $0[5] == 2 })
        #expect(io.writes.contains { $0[2] == 10 && $0[3] >> 4 == 8 && $0[4] == 1 && $0[5] == 1 })
        io.powerMode = 3
        io.rejectsWake = true
        #expect(feature.apply(settings, percentage: 50, charging: false, canWrite: { true }) == false)
        #expect(io.flags == 0 && io.events == 0x80)
    }

    @Test func experimentalRGBWithoutBrightnessUsesAdvertisedDisabledEffectsOnly() throws {
        let io = LightingKeyboard(), ownership = KeyboardLightingOwnership()
        io.supportsDisabled = true
        io.supportsPowerModes = false
        let transport = try #require(HIDPPTransport(device: io, deviceIndex: 1))
        let rgb = try #require(KeyboardLighting(transport: transport, brightnessIndex: nil, rgbIndex: 10,
            ownership: ownership, slot: 1, isExperimental: true))
        let state = try #require(rgb.read())
        #expect(state.isExperimental && state.brightnessValues.isEmpty && state.supportsPower)
        var settings = KeyboardLightingSettings(deviceKey: "mouse", color: 0x112233)
        #expect(rgb.apply(settings, percentage: nil, charging: false, canWrite: { true }))
        #expect(io.writes.filter { $0[2] == 10 && $0[3] >> 4 == 1 }.count == 2)
        settings.isEnabled = false
        #expect(rgb.apply(settings, percentage: nil, charging: false, canWrite: { true }))
        #expect(io.writes.last?[5] == 1) // Disabled is ordinal 1, not an assumed zero.
        #expect(rgb.read()?.isEnabled == false)
        #expect(io.writes.contains { $0[2] == 20 } == false)
    }

    @Test func missingDisabledEffectHidesSwitchAndDoesNotInventAnOffCommand() throws {
        let io = LightingKeyboard()
        let transport = try #require(HIDPPTransport(device: io, deviceIndex: 1))
        let rgb = try #require(KeyboardLighting(transport: transport, brightnessIndex: nil, rgbIndex: 10,
            ownership: KeyboardLightingOwnership(), slot: 1, isExperimental: true))
        #expect(rgb.read()?.supportsPower == false)
        #expect(rgb.apply(KeyboardLightingSettings(deviceKey: "mouse", isEnabled: false),
            percentage: nil, charging: false, canWrite: { true }) == false)
        #expect(io.writes.isEmpty)
    }

    @Test func experimentalBrightnessMapsAdvertisedRangeAndSeparateIllumination() throws {
        let io = LightingKeyboard()
        io.brightnessInfo = [0, 200, 5, 7, 0, 10, 0]
        let transport = try #require(HIDPPTransport(device: io, deviceIndex: 1))
        let rgb = try #require(KeyboardLighting(transport: transport, brightnessIndex: 20, rgbIndex: 10,
            ownership: KeyboardLightingOwnership(), slot: 1, isExperimental: true))
        #expect(rgb.read()?.brightnessValues == [13, 25, 50, 100])
        var settings = KeyboardLightingSettings(deviceKey: "keyboard", brightness: 13, color: 0x123456)
        #expect(rgb.apply(settings, percentage: 50, charging: false, canWrite: { true }))
        #expect(io.brightness == 25)
        settings.isEnabled = false
        #expect(rgb.apply(settings, percentage: 50, charging: false, canWrite: { true }))
        #expect(io.illumination == false && io.brightness == 25)
        #expect(rgb.read()?.brightness == 0)
    }
}
