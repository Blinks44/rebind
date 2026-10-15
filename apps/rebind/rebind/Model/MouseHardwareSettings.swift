import Foundation

/// How a SmartShift wheel turns.
nonisolated enum WheelMode: String, Codable, CaseIterable, Hashable, Sendable {
    /// Clicks step by step and spins freely past the sensitivity threshold.
    case smartShift
    case alwaysClick
    case alwaysFreeSpin
}

/// Settings Rebind keeps for one mouse and writes to it whenever it connects.
/// A nil value leaves that setting as the mouse has it.
nonisolated struct MouseHardwareSettings: Codable, Hashable, Sendable {
    static let sensitivityRange = 1...50
    static let maximumDevices = 50

    /// Vendor and name of the mouse ("046d:MX Master 3S"); identical models share settings.
    var deviceKey: String
    var wheelMode: WheelMode?
    /// SmartShift speed threshold, larger means the wheel needs a faster spin to release.
    var smartShiftSensitivity: Int?
    var dpi: Int?

    var isValid: Bool {
        !deviceKey.isEmpty && deviceKey.count <= 200
            && smartShiftSensitivity.map(Self.sensitivityRange.contains) ?? true
            && dpi.map((1...Int(UInt16.max)).contains) ?? true
    }

    static func deviceKey(vendorID: Int, name: String) -> String {
        String(format: "%04x:", vendorID) + name
    }
}
