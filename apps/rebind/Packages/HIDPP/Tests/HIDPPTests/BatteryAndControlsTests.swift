// MIT License
// Copyright (c) 2026 Rebind

import Foundation
@testable import HIDPP
import XCTest

final class BatteryAndControlsTests: XCTestCase {
    func testReadsBothBatteryFeatures() {
        XCTAssertEqual(Battery.status(from: [80, 0x08, 0x00], isUnified: true), .init(percentage: 80, isCharging: false))
        XCTAssertEqual(Battery.status(from: [55, 0x04, 0x01], isUnified: true), .init(percentage: 55, isCharging: true))
        XCTAssertEqual(Battery.status(from: [30, 20, 0x00], isUnified: false), .init(percentage: 30, isCharging: false))
        XCTAssertEqual(Battery.status(from: [90, 50, 0x03], isUnified: false), .init(percentage: 90, isCharging: true))
        XCTAssertNil(Battery.status(from: [0, 0, 0], isUnified: true))
        XCTAssertNil(Battery.status(from: [50], isUnified: false))
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
}
