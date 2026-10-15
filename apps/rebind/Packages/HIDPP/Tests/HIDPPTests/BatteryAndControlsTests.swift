// MIT License
// Copyright (c) 2026 Rebind

import Foundation
@testable import HIDPP
import XCTest

final class BatteryAndControlsTests: XCTestCase {
    func testReadsEveryBatteryFeature() {
        XCTAssertEqual(Battery.status(from: [80, 0x08, 0x00], source: .unified), .init(percentage: 80, isCharging: false))
        XCTAssertEqual(Battery.status(from: [55, 0x04, 0x01], source: .unified), .init(percentage: 55, isCharging: true))
        XCTAssertEqual(Battery.status(from: [30, 20, 0x00], source: .status), .init(percentage: 30, isCharging: false))
        XCTAssertEqual(Battery.status(from: [90, 50, 0x03], source: .status), .init(percentage: 90, isCharging: true))
        XCTAssertNil(Battery.status(from: [0, 0, 0], source: .unified))
        XCTAssertNil(Battery.status(from: [50], source: .status))
        // 3,900 mV (0x0F3C) is about 62 %; bit 7 of the flags means external power.
        XCTAssertEqual(Battery.status(from: [0x0F, 0x3C, 0x00], source: .voltage), .init(percentage: 62, isCharging: false))
        XCTAssertEqual(Battery.status(from: [0x10, 0x68, 0x80], source: .voltage), .init(percentage: 100, isCharging: true))
        XCTAssertEqual(Battery.percentage(millivolts: 3400), 0)
        XCTAssertEqual(Battery.percentage(millivolts: 3860), 54)
    }

    func testDivertsTheGestureButtonOnlyWhenTheDeviceAllowsIt() throws {
        let device = MockHIDPPDevice()
        // Two controls: 0x0050 (left button, not divertable) and 0x00C3 (gesture, divertable).
        device.responseProvider = { report in
            let bytes = [UInt8](report)
            var reply: [UInt8] = [0x11, 0xFF, bytes[2], bytes[3]]
            switch bytes[3] >> 4 {
            case 0: reply.append(2)
            case 1: reply += bytes[4] == 0 ? [0x00, 0x50, 0x00, 0x38, 0x01] : [0x00, 0xC3, 0x00, 0xC4, 0x30]
            case 3: reply += Array(bytes[4 ... 6])
            default: return nil
            }
            return Data(reply + [UInt8](repeating: 0, count: 20 - reply.count))
        }
        let transport = try XCTUnwrap(HIDPPTransport(device: device, deviceIndex: nil))
        let controls = ReprogControls(transport: transport, featureIndex: 0x09)

        XCTAssertTrue(controls.canDivert(ReprogControls.gestureButton))
        XCTAssertFalse(controls.canDivert(0x0050))
        XCTAssertTrue(controls.setDiverted(ReprogControls.gestureButton, true))
        XCTAssertEqual(Array(try XCTUnwrap(device.reports.last).prefix(7)), [0x11, 0xFF, 0x09, 0x38, 0x00, 0xC3, 0x03])
        XCTAssertTrue(controls.setDiverted(ReprogControls.gestureButton, false))
        XCTAssertEqual(Array(try XCTUnwrap(device.reports.last).prefix(7)), [0x11, 0xFF, 0x09, 0x38, 0x00, 0xC3, 0x02])
    }

    func testParsesPressedControlsFromNotifications() {
        let pressed: [UInt8] = [0x11, 0x01, 0x09, 0x00, 0x00, 0xC3] + [UInt8](repeating: 0, count: 14)
        let released: [UInt8] = [0x11, 0x01, 0x09, 0x00] + [UInt8](repeating: 0, count: 16)
        XCTAssertEqual(ReprogControls.pressedControls(in: pressed, featureIndex: 0x09), [0x00C3])
        XCTAssertEqual(ReprogControls.pressedControls(in: released, featureIndex: 0x09), [])
        // A reply to Rebind's own request (software ID 8) or another feature is not an event.
        XCTAssertNil(ReprogControls.pressedControls(in: [0x11, 0x01, 0x09, 0x08] + pressed.dropFirst(4), featureIndex: 0x09))
        XCTAssertNil(ReprogControls.pressedControls(in: pressed, featureIndex: 0x0A))
    }

    func testSwitchesOnboardProfilesToHostMode() throws {
        let device = MockHIDPPDevice()
        device.responseProvider = { report in
            let bytes = [UInt8](report)
            let payload: [UInt8] = bytes[3] >> 4 == 2 ? [0x01] : []
            return Data([0x11, bytes[1], bytes[2], bytes[3]] + payload + [UInt8](repeating: 0, count: 16 - payload.count))
        }
        let transport = try XCTUnwrap(HIDPPTransport(device: device, deviceIndex: 1))
        let profiles = OnboardProfiles(transport: transport, featureIndex: 0x0C)
        XCTAssertEqual(profiles.isHostMode(), false)
        XCTAssertTrue(profiles.setHostMode())
        XCTAssertEqual(Array(try XCTUnwrap(device.reports.last).prefix(5)), [0x11, 0x01, 0x0C, 0x18, 0x02])
    }
}

final class ReceiverNotificationsTests: XCTestCase {
    func testTurnsOnWirelessNotificationsAndKeepsOtherFlags() {
        let device = MockHIDPPDevice()
        device.responseProvider = { report in
            let bytes = [UInt8](report)
            return Data([0x10, 0xFF, bytes[2], 0x00, 0x00, bytes[2] == 0x81 ? 0x08 : bytes[5], 0x00])
        }
        XCTAssertEqual(ReceiverNotifications.enable(on: device), .enabled)
        XCTAssertEqual(Array(try XCTUnwrap(device.reports.last)), [0x10, 0xFF, 0x80, 0x00, 0x00, 0x09, 0x00])
    }

    func testAnErrorMeansAReceiverAndSilenceMeansNone() {
        let refusing = MockHIDPPDevice()
        refusing.responseProvider = { _ in Data([0x10, 0xFF, 0x8F, 0x81, 0x00, 0x02, 0x00]) }
        XCTAssertEqual(ReceiverNotifications.enable(on: refusing), .refused)
        XCTAssertEqual(ReceiverNotifications.enable(on: MockHIDPPDevice()), .silent)
    }
}
