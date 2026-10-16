import Foundation
import Testing
@testable import rebind

struct PeripheralBatteryTests {
    @Test func aLaterBatteryReplyCanPopulateAnInitiallyUnknownDevice() {
        let device = ConnectedAccessory(id: "receiver#1", name: "Keyboard", kind: .keyboard, vendorID: 0x046D)
        let known = MouseHardware.refreshedBatteries([], inputs: [device], readings: [(device.id, 49, false)])
        #expect(known == [DeviceBattery(id: device.id, name: device.name, kind: .keyboard,
                                      percentage: 49, isCharging: false, vendorID: device.vendorID)])
        #expect(MouseHardware.refreshedBatteries(known, inputs: [device], readings: [(device.id, nil, false)]) == known)
        #expect(MouseHardware.refreshedBatteries(known, inputs: [device], readings: [(device.id, 101, false)]) == known)
        #expect(MouseHardware.refreshedBatteries([], inputs: [device], readings: [("old#1", 80, false)]).isEmpty)
    }

    @Test func standardHIDRangesAreNormalizedWithoutClampingUnknownValues() {
        #expect(PeripheralBatteryReading.normalized(128, minimum: 0, maximum: 255)?.percentage == 50)
        #expect(PeripheralBatteryReading.normalized(5, minimum: 0, maximum: 10)?.percentage == 50)
        #expect(PeripheralBatteryReading.normalized(0, minimum: 0, maximum: 100)?.percentage == 0)
        #expect(PeripheralBatteryReading.normalized(100, minimum: 0, maximum: 100)?.percentage == 100)
        #expect(PeripheralBatteryReading.normalized(255, minimum: 0, maximum: 100) == nil)
        #expect(PeripheralBatteryReading.normalized(-1, minimum: 0, maximum: 100) == nil)
        #expect(PeripheralBatteryReading.normalized(0, minimum: 0, maximum: 0) == nil)
        #expect(PeripheralBatteryReading.normalized(1, minimum: 0, maximum: Int.max) == nil)
    }

    @Test func inventoryIsVendorIndependentButRejectsBuiltInsAndHeadsets() {
        #expect(MouseHardware.inputKind(page: 1, usage: 6, usages: [(1, 6)], builtIn: false) == .keyboard)
        #expect(MouseHardware.inputKind(page: 1, usage: 2, usages: [(1, 2)], builtIn: false) == .mouse)
        #expect(MouseHardware.inputKind(page: 1, usage: 2, usages: [(1, 2), (13, 5)], builtIn: false) == .trackpad)
        #expect(MouseHardware.inputKind(page: 1, usage: 6, usages: [(1, 6)], builtIn: true) == nil)
        #expect(MouseHardware.inputKind(page: 12, usage: 1, usages: [(0xFF00, 1), (12, 1)], builtIn: false) == nil)
        #expect(MouseHardware.inputKind(page: 0xFF00, usage: 1, usages: [(0xFF00, 1)], builtIn: false) == nil)
    }
}

struct VendorBatteryProtocolTests {
    @Test func interruptBatteryRepliesNeverUseAMouseOrKeyboardInputCollection() throws {
        let profile = try #require(VendorBatteryProtocol.profile(vendorID: 0x1038, productID: 0x1838))
        #expect(profile.acceptsInterface(number: 3, usages: [(0xFF00, 1)], featureSize: 0, outputSize: 64))
        #expect(profile.acceptsInterface(number: 0, usages: [(0xFF00, 1)], featureSize: 0, outputSize: 64) == false)
        #expect(profile.acceptsInterface(number: nil, usages: [(0xFF00, 1)], featureSize: 0, outputSize: 64) == false)
        #expect(profile.acceptsInterface(number: 3, usages: [(1, 6), (0xFF00, 1)], featureSize: 0, outputSize: 64) == false)
        #expect(profile.acceptsInterface(number: 3, usages: [(1, 2), (0xFF00, 1)], featureSize: 0, outputSize: 64) == false)
        #expect(profile.acceptsInterface(number: 3, usages: [(12, 1)], featureSize: 0, outputSize: 64) == false)
    }

    @Test func unknownProductsAndHeadsetIDsHaveNoVendorCommands() {
        #expect(VendorBatteryProtocol.profile(vendorID: 0x1532, productID: 0xFFFF) == nil)
        #expect(VendorBatteryProtocol.profile(vendorID: 0x1038, productID: 0xFFFF) == nil)
        #expect(VendorBatteryProtocol.profile(vendorID: 0x046D, productID: 0x0ADF) == nil)
        #expect(VendorBatteryProtocol.profile(vendorID: 0x1532, productID: 0x0520) == nil)
        #expect(VendorBatteryProtocol.profile(vendorID: 0x1038, productID: 0x12AD) == nil)
        #expect(VendorBatteryProtocol.profile(vendorID: 0x1532, productID: 0x00A6)?.family == .razer(transaction: 0x1F))
        #expect(VendorBatteryProtocol.profile(vendorID: 0x1038, productID: 0x1838)?.interface == 3)
    }

    private func razerReply(value: UInt8, charging: Bool = false) -> [UInt8] {
        var reply = VendorBatteryProtocol.razerRequest(transaction: 0x1F, charging: charging)
        reply[0] = 2
        reply[9] = value
        reply[88] = reply[2..<88].reduce(0, ^)
        return reply
    }

    @Test func razerRepliesRequireSuccessfulStatusChecksumCommandAndTransaction() {
        let reply = razerReply(value: 128)
        #expect(VendorBatteryProtocol.razerValue(reply, transaction: 0x1F) == 128)
        #expect(VendorBatteryProtocol.razerValue(reply, transaction: 0x3F) == nil)
        #expect(VendorBatteryProtocol.razerValue(reply, transaction: 0x1F, charging: true) == nil)
        #expect(VendorBatteryProtocol.razerValue(Array(reply.dropLast()), transaction: 0x1F) == nil)
        var corrupt = reply
        corrupt[9] = 255
        #expect(VendorBatteryProtocol.razerValue(corrupt, transaction: 0x1F) == nil)
        for status: UInt8 in [0, 1, 3, 4, 5] {
            corrupt = reply
            corrupt[0] = status
            #expect(VendorBatteryProtocol.razerValue(corrupt, transaction: 0x1F) == nil)
        }
        #expect(VendorBatteryProtocol.razerValue(razerReply(value: 1, charging: true), transaction: 0x1F, charging: true) == 1)
        #expect(VendorBatteryProtocol.razerValue(razerReply(value: 5, charging: true), transaction: 0x1F, charging: true) == nil)
    }

    @Test func aeroxRepliesKeepTheFirmwareScaleAndChargingFlag() {
        let coarse = VendorBatteryProtocol.Family.steelSeries(command: 0xD2, directPercentage: false)
        #expect(VendorBatteryProtocol.steelSeriesReading([0xD2, 11], family: coarse) == PeripheralBatteryReading(percentage: 50))
        #expect(VendorBatteryProtocol.steelSeriesReading([0, 0xD2, 0, 0x95], family: coarse)
                == PeripheralBatteryReading(percentage: 100, isCharging: true))
        #expect(VendorBatteryProtocol.steelSeriesReading([0x92, 11], family: coarse) == nil)
        #expect(VendorBatteryProtocol.steelSeriesReading([0xD2, 0], family: coarse) == nil)
        #expect(VendorBatteryProtocol.steelSeriesReading([0xD2, 127], family: coarse) == nil)
        let direct = VendorBatteryProtocol.Family.steelSeries(command: 0xD2, directPercentage: true)
        #expect(VendorBatteryProtocol.steelSeriesReading([0xD2, 55], family: direct)?.percentage == 55)
        #expect(VendorBatteryProtocol.steelSeriesReading([0xD2, 127], family: direct) == nil)
    }

    @Test func rivalSupportsKnownEchoAndDirectRepliesWithoutTreatingSilenceAsFull() {
        #expect(VendorBatteryProtocol.steelSeriesReading([0xAA, 1, 65, 1], family: .rival)
                == PeripheralBatteryReading(percentage: 65, isCharging: true))
        #expect(VendorBatteryProtocol.steelSeriesReading([0, 0xAA, 1, 65, 0], family: .rival)?.percentage == 65)
        #expect(VendorBatteryProtocol.steelSeriesReading([65, 0, 0], family: .rival)?.percentage == 65)
        #expect(VendorBatteryProtocol.steelSeriesReading([0, 65, 0, 0], family: .rival)?.percentage == 65)
        #expect(VendorBatteryProtocol.steelSeriesReading([0, 0, 0], family: .rival) == nil)
        #expect(VendorBatteryProtocol.steelSeriesReading([255, 0, 0], family: .rival) == nil)
        #expect(VendorBatteryProtocol.steelSeriesReading([65, 0, 5], family: .rival) == nil)
        #expect(VendorBatteryProtocol.steelSeriesReading([], family: .rival) == nil)
    }
}

struct HIDReportMapTests {
    @Test func onlyInputApplicationCollectionsQualify() {
        #expect(HIDReportMap.inputKind(Data([0x05, 1, 0x09, 2, 0xA1, 1, 0xC0])) == .mouse)
        #expect(HIDReportMap.inputKind(Data([0x05, 1, 0x09, 6, 0xA1, 1, 0xC0])) == .keyboard)
        #expect(HIDReportMap.inputKind(Data([0x05, 13, 0x09, 5, 0xA1, 1, 0xC0])) == .trackpad)
        #expect(HIDReportMap.inputKind(Data([0x05, 12, 0x09, 1, 0xA1, 1, 0xC0])) == nil)
        #expect(HIDReportMap.inputKind(Data([0x05, 1, 0x09, 5, 0xA1, 1, 0xC0])) == nil)
        #expect(HIDReportMap.inputKind(Data([0x05, 1, 0x09, 6])) == nil)
    }

    @Test func extendedUsagesAndGlobalPushPopKeepTheirPage() {
        #expect(HIDReportMap.inputKind(Data([0x0B, 6, 0, 1, 0, 0xA1, 1, 0xC0])) == .keyboard)
        #expect(HIDReportMap.inputKind(Data([0x05, 1, 0xA4, 0x05, 12, 0xB4, 0x09, 2, 0xA1, 1, 0xC0])) == .mouse)
    }

    @Test func truncatedUnbalancedAndOversizedDescriptorsFailClosed() {
        for data in [Data(), Data([0x05]), Data([0xB4]), Data([0xC0]), Data([0xFE, 3, 0, 0]),
                     Data([0x05, 1, 0x09, 6, 0xA1, 1]), Data(repeating: 0, count: 4097)] {
            #expect(HIDReportMap.inputKind(data) == nil)
        }
    }
}

struct BluetoothBatteryIdentityTests {
    private let reading = DeviceBattery(id: "ble-fixture", name: "Keyboard", kind: .keyboard, percentage: 70, isCharging: false)

    @Test func anExistingInputKeepsItsCardAndAliasIdentity() throws {
        let keyboard = ConnectedAccessory(id: "native-fixture", name: "Keyboard", kind: .keyboard, vendorID: 0x1532)
        let matched = try #require(MouseHardware.bluetoothBatteries([reading], matching: [keyboard]).first)
        #expect(matched.id == keyboard.id && matched.deviceKey == keyboard.deviceKey && matched.percentage == 70)
    }

    @Test func duplicateNamesAreNotAttributedToTheWrongPhysicalDevice() {
        let first = ConnectedAccessory(id: "a", name: "Keyboard", kind: .keyboard, vendorID: 0x1532)
        let second = ConnectedAccessory(id: "b", name: "Keyboard", kind: .keyboard, vendorID: 0x1532)
        #expect(MouseHardware.bluetoothBatteries([reading], matching: [first, second]).isEmpty)
        #expect(MouseHardware.bluetoothBatteries([reading], matching: []) == [reading])
    }
}
