// MIT License
// Copyright (c) 2026 Rebind, following the feature pattern of LinearMouse.

import Foundation

/// HID++ feature 0x1B04 (REPROG_CONTROLS_V4): a diverted control stops acting on its own and
/// reports presses to the host as notifications instead. Diversion lasts until the device
/// is reset or reconnects, so the host diverts again when it finds the device.
public struct ReprogControls {
    /// The gesture (thumb) button of MX Master mice.
    public static let gestureButton: UInt16 = 0x00C3
    private static let divertableFlag: UInt8 = 0x20

    private let transport: HIDPPTransport
    public let featureIndex: UInt8

    public init(transport: HIDPPTransport, featureIndex: UInt8) {
        self.transport = transport
        self.featureIndex = featureIndex
    }

    /// Whether the device has this control and allows diverting it.
    public func canDivert(_ control: UInt16) -> Bool {
        guard let count = transport.request(featureIndex: featureIndex, function: 0x00, parameters: [])?.payload.first else {
            return false
        }
        for index in 0 ..< count {
            guard let info = transport.request(featureIndex: featureIndex, function: 0x01, parameters: [index])?.payload,
                  info.count >= 5 else { continue }
            if UInt16(info[0]) << 8 | UInt16(info[1]) == control { return info[4] & Self.divertableFlag != 0 }
        }
        return false
    }

    @discardableResult
    public func setDiverted(_ control: UInt16, _ diverted: Bool) -> Bool {
        transport.requestOnce(featureIndex: featureIndex, function: 0x03,
                              parameters: Self.reportingParameters(control, diverted: diverted)) != nil
    }

    /// setCidReporting: the control, then flags: divert (bit 0) with its valid bit (bit 1).
    static func reportingParameters(_ control: UInt16, diverted: Bool) -> [UInt8] {
        [UInt8(control >> 8), UInt8(control & 0xFF), diverted ? 0x03 : 0x02]
    }

    /// The diverted controls held down, from a divertedButtonsEvent notification of this
    /// feature (function 0, software ID 0), or nil when the report is something else.
    public static func pressedControls(in report: [UInt8], featureIndex: UInt8) -> [UInt16]? {
        guard report.count >= HIDPPConstants.shortReportLength,
              report[0] == HIDPPConstants.shortReportID || report[0] == HIDPPConstants.longReportID,
              report[2] == featureIndex, report[3] == 0x00 else { return nil }
        var controls: [UInt16] = []
        var index = 4
        while index + 1 < report.count, controls.count < 4 {
            let control = UInt16(report[index]) << 8 | UInt16(report[index + 1])
            if control == 0 { break }
            controls.append(control)
            index += 2
        }
        return controls
    }
}
