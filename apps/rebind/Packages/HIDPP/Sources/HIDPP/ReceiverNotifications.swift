// MIT License
// Copyright (c) 2026 Rebind

import Foundation

/// A Unifying, Bolt or Lightspeed receiver tells the host when one of its devices connects
/// (HID++ 1.0 notification 0x41) only while "wireless notifications" are on in its register
/// 0x00. The host needs that notice to write its settings again after a device was switched
/// off or reset. Logitech's own software and Solaar turn the flag on in the same way.
public enum ReceiverNotifications {
    private static let setRegister: UInt8 = 0x80
    private static let getRegister: UInt8 = 0x81
    private static let notificationsRegister: UInt8 = 0x00
    /// Bit 8 of the 24-bit flags: wireless (device connection) notifications.
    private static let wirelessFlag: UInt8 = 0x01

    public enum Outcome: Equatable, Sendable {
        /// The flag is on now.
        case enabled
        /// A receiver answered but refused the register.
        case refused
        /// Nothing answered: this is not a receiver.
        case silent
    }

    /// HID++ 1.0 connection notices use the short report. A long report can have a
    /// HID++ 2.0 feature at index 0x41, which is unrelated to receiver connection state.
    public static func isConnectionNotification(_ report: [UInt8]) -> Bool {
        report.count >= HIDPPConstants.shortReportLength
            && report[0] == HIDPPConstants.shortReportID && report[2] == 0x41
    }

    /// Turns the flag on, keeping the receiver's other flags.
    @discardableResult
    public static func enable(on device: HIDPPDeviceIO, timeout: TimeInterval = 1) -> Outcome {
        guard (device.maxOutputReportSize ?? 0) >= HIDPPConstants.shortReportLength else { return .silent }
        switch registerRequest(device, subID: getRegister, flags: [0, 0, 0], timeout: timeout) {
        case .none: return .silent
        case .some(nil): return .refused
        case .some(let current?):
            guard current[1] & wirelessFlag == 0 else { return .enabled }
            guard case .some(.some) = registerRequest(device, subID: setRegister, flags: enabling(current), timeout: timeout) else {
                return .refused
            }
            return .enabled
        }
    }

    static func enabling(_ flags: [UInt8]) -> [UInt8] {
        [flags[0], flags[1] | wirelessFlag, flags[2]]
    }

    /// A short register request to the receiver itself (index 0xFF): nil without any answer,
    /// .some(nil) for an error reply, otherwise its three flag bytes.
    private static func registerRequest(_ device: HIDPPDeviceIO, subID: UInt8, flags: [UInt8],
                                        timeout: TimeInterval) -> [UInt8]?? {
        let report = Data([HIDPPConstants.shortReportID, HIDPPConstants.receiverIndex, subID, notificationsRegister] + flags)
        let reply = device.performSynchronousOutputReportRequest(report, timeout: timeout) { data in
            let bytes = [UInt8](data)
            guard bytes.count >= HIDPPConstants.shortReportLength, bytes[1] == HIDPPConstants.receiverIndex else { return false }
            // The reply repeats the sub-ID and register; an error reply (0x8F) names them after it.
            return (bytes[2] == subID && bytes[3] == notificationsRegister)
                || (bytes[2] == 0x8F && bytes[3] == subID && bytes[4] == notificationsRegister)
        }
        guard let bytes = reply.map(Array.init) else { return nil }
        return bytes[2] == subID ? Array(bytes[4 ..< 7]) : .some(nil)
    }
}
