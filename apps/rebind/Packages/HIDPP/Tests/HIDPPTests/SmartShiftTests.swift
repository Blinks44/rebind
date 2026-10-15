// MIT License
// Copyright (c) 2026 Rebind

import Foundation
@testable import HIDPP
import XCTest

final class SmartShiftTests: XCTestCase {
    func testEncodesEachWheelMode() {
        XCTAssertEqual(SmartShift.parameters(for: .smartShift(threshold: 12)), [0x02, 12, 0x00])
        XCTAssertEqual(SmartShift.parameters(for: .alwaysRatchet), [0x02, 0xFF, 0x00])
        XCTAssertEqual(SmartShift.parameters(for: .freeSpin), [0x01, 0x00, 0x00])
        XCTAssertEqual(SmartShift.parameters(for: .smartShift(threshold: 0)), [0x02, 1, 0x00])
    }

    func testDecodesDeviceReplies() {
        XCTAssertEqual(SmartShift.mode(from: [0x02, 30, 10]), .smartShift(threshold: 30))
        XCTAssertEqual(SmartShift.mode(from: [0x02, 0xFF, 10]), .alwaysRatchet)
        XCTAssertEqual(SmartShift.mode(from: [0x01, 30, 10]), .freeSpin)
        XCTAssertNil(SmartShift.mode(from: [0x00, 30, 10]))
        XCTAssertNil(SmartShift.mode(from: [0x02]))
    }

    func testEnhancedFeatureUsesShiftedFunctions() throws {
        let device = MockHIDPPDevice()
        device.responseProvider = { report in
            let bytes = [UInt8](report)
            return Data([0x11, 0xFF, bytes[2], bytes[3], 0x02, 0x14, 0x0A])
        }
        let transport = try XCTUnwrap(HIDPPTransport(device: device, deviceIndex: nil))
        let plain = SmartShift(transport: transport, featureIndex: 0x0E, isEnhanced: false)
        let enhanced = SmartShift(transport: transport, featureIndex: 0x0F, isEnhanced: true)

        XCTAssertEqual(plain.mode(), .smartShift(threshold: 20))
        XCTAssertEqual(Array(try XCTUnwrap(device.reports.last).prefix(4)), [0x11, 0xFF, 0x0E, 0x08])
        XCTAssertEqual(enhanced.mode(), .smartShift(threshold: 20))
        XCTAssertEqual(Array(try XCTUnwrap(device.reports.last).prefix(4)), [0x11, 0xFF, 0x0F, 0x18])

        XCTAssertTrue(plain.setMode(.freeSpin))
        XCTAssertEqual(Array(try XCTUnwrap(device.reports.last).prefix(7)), [0x11, 0xFF, 0x0E, 0x18, 0x01, 0x00, 0x00])
        XCTAssertTrue(enhanced.setMode(.alwaysRatchet))
        XCTAssertEqual(Array(try XCTUnwrap(device.reports.last).prefix(7)), [0x11, 0xFF, 0x0F, 0x28, 0x02, 0xFF, 0x00])
        XCTAssertEqual(device.singleTransactionRequestCount, 2)
    }

    func testReceiverSlotErrorFailsWithoutWaiting() throws {
        let device = MockHIDPPDevice()
        device.responseProvider = { report in
            let bytes = [UInt8](report)
            return Data([0x10, bytes[1], 0x8F, bytes[2], bytes[3], 0x09, 0x00])
        }
        let transport = try XCTUnwrap(HIDPPTransport(device: device, deviceIndex: 2))

        XCTAssertNil(transport.featureIndex(for: .adjustableDPI))
        XCTAssertEqual(device.regularRequestCount, 1)
    }

    func testReadsDeviceNameAcrossReports() throws {
        let device = MockHIDPPDevice()
        let name = Array("Wireless Mouse MX Master 3S".utf8)
        device.responseProvider = { report in
            let bytes = [UInt8](report)
            var reply: [UInt8] = [0x11, 0xFF, bytes[2], bytes[3]]
            switch bytes[3] >> 4 {
            case 0: reply.append(UInt8(name.count))
            case 1: reply += name.dropFirst(Int(bytes[4])).prefix(16)
            case 2: reply.append(3)
            default: return nil
            }
            return Data(reply + [UInt8](repeating: 0, count: 20 - reply.count))
        }
        let transport = try XCTUnwrap(HIDPPTransport(device: device, deviceIndex: nil))
        let feature = DeviceName(transport: transport, featureIndex: 0x03)

        XCTAssertEqual(feature.name(), "Wireless Mouse MX Master 3S")
        XCTAssertEqual(feature.kind(), .mouse)
    }
}
