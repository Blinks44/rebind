import Foundation
import Testing
@testable import HIDPP

struct LightingTests {
    private func reply(_ report: Data, _ payload: [UInt8]) -> Data {
        Data(Array(report.prefix(4)) + payload + Array(repeating: 0, count: max(0, 16 - payload.count)))
    }

    @available(macOS 13, *)
    @Test func brightnessUsesAdvertisedRangeAndBigEndianValues() throws {
        let io = MockHIDPPDevice()
        io.responseProvider = { report in self.reply(report, [0x12, 0x34, 5, 3, 0, 10, 1]) }
        let transport = try #require(HIDPPTransport(device: io, deviceIndex: 1))
        let feature = BrightnessControl(transport: transport, featureIndex: 20)
        let info = try #require(feature.info())
        #expect(info.maximum == 0x1234 && info.minimum == 10 && info.steps == 261)
        #expect(feature.setBrightness(0xABCD))
        #expect(Array(try #require(io.reports.last).prefix(7)) == [0x11, 1, 20, 0x28, 0xAB, 0xCD, 0])
        #expect(io.singleTransactionRequestCount == 1)
        #expect(BrightnessControl.Info(payload: [0, 100, 5]) == nil)
        #expect(BrightnessControl.Info(payload: [0, 0, 5, 0, 0, 0, 0]) == nil)
    }

    @available(macOS 13, *)
    @Test func staticColorUsesEachZonesOwnOrdinalAndOnlyVolatileStorage() throws {
        let io = MockHIDPPDevice()
        io.responseProvider = { report in
            let b = [UInt8](report)
            if b[4] == 255 { return self.reply(report, [255, 0, 2, 0, 0, 0, 0, 0]) }
            if b[5] == 255 { return self.reply(report, [b[4], 0, 0, 1, 2, 0, 0, 0]) }
            let id: UInt8 = b[4] == b[5] ? 1 : 0x0A
            return self.reply(report, [b[4], b[5], 0, id, 0, 0, 0, 0])
        }
        let transport = try #require(HIDPPTransport(device: io, deviceIndex: 1))
        let rgb = RGBEffects(transport: transport, featureIndex: 10)
        let zones = try #require(rgb.zones())
        #expect(zones.map(\.staticEffect) == [0, 1])
        #expect(zones.map(\.breathingEffect) == [1, 0])
        let parameters = try #require(RGBEffects.colorParameters(0x2080FF, zone: zones[1], breathing: false))
        #expect(parameters == [1, 1, 0x20, 0x80, 0xFF, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0])
        #expect(RGBEffects.colorParameters(0x1000000, zone: zones[0], breathing: false) == nil)
    }

    @available(macOS 13, *)
    @Test func incompleteZoneInventoryNeverClaimsControl() throws {
        let io = MockHIDPPDevice()
        io.responseProvider = { report in
            let b = [UInt8](report)
            if b[4] == 255 { return self.reply(report, [255, 0, 1, 0, 0, 0, 0, 0]) }
            if b[5] == 255 { return self.reply(report, [b[4], 0, 0, 1, 1, 0, 0, 0]) }
            return self.reply(report, [b[4], b[5], 0, 3, 0, 0, 0, 0]) // Cycle only.
        }
        let transport = try #require(HIDPPTransport(device: io, deviceIndex: 1))
        #expect(RGBEffects(transport: transport, featureIndex: 10).zones() == nil)
        #expect(io.reports.allSatisfy { $0[3] >> 4 == 0 })
        #expect(io.singleTransactionRequestCount == 0)
    }

    @available(macOS 13, *)
    @Test func nativePolicyPreservesUnknownFlagsAndDimming() throws {
        var policy = try #require(RGBEffects.PowerPolicy(payload: [0, 0xA5, 0xF0, 0, 120, 1, 44]))
        policy.offSeconds = 600
        #expect(policy.writeParameters == [1, 0xA5, 0xF0, 0, 120, 2, 88])
        #expect(RGBEffects.PowerPolicy(payload: [0, 0, 0, 0, 120]) == nil)
        #expect(RGBEffects.PowerPolicy(payload: [1, 0, 0, 0, 120, 0, 30]) == nil)
    }

    @available(macOS 13, *)
    @Test func softwareOwnershipRequiresExactAcknowledgement() throws {
        let io = MockHIDPPDevice()
        io.responseProvider = { report in self.reply(report, [0, 0, 0]) }
        let transport = try #require(HIDPPTransport(device: io, deviceIndex: 1))
        let rgb = RGBEffects(transport: transport, featureIndex: 10)
        var control = try #require(rgb.control())
        control.flags |= 1
        #expect(rgb.setControl(control) == false)
        io.responseProvider = { report in self.reply(report, Array(report[4...6])) }
        #expect(rgb.setControl(control))
    }
}
