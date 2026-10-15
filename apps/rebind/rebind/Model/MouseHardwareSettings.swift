import Foundation

/// How a SmartShift wheel turns.
nonisolated enum WheelMode: String, Codable, CaseIterable, Hashable, Sendable {
    /// Clicks step by step and spins freely past the sensitivity threshold.
    case smartShift
    case alwaysClick
    case alwaysFreeSpin
}

/// Settings Rebind keeps for one mouse model: hardware values it writes to a Logitech mouse
/// whenever it connects (nil leaves the mouse as it is), and smooth scrolling, which works
/// for any mouse.
nonisolated struct MouseHardwareSettings: Codable, Hashable, Sendable {
    static let sensitivityRange = 1...50
    static let maximumDevices = 50

    /// Vendor and name of the mouse ("046d:MX Master 3S"); identical models share settings.
    var deviceKey: String
    var wheelMode: WheelMode?
    /// SmartShift speed threshold, larger means the wheel needs a faster spin to release.
    var smartShiftSensitivity: Int?
    var dpi: Int?
    /// Logitech high-resolution wheel: on reports fine steps (continuous scrolling), off clicks.
    var highResolutionWheel: Bool?
    /// Logitech gesture button as a trigger in bindings (diverted from the mouse to Rebind).
    var usesGestureButton: Bool?
    var smoothScrolling: Bool?
    /// Points per line of a wheel click (`SmoothScrollingDistance.range`).
    var smoothScrollingDistance: Int?
    var smoothScrollingGlide: SmoothScrollingGlide?

    var isValid: Bool {
        !deviceKey.isEmpty && deviceKey.count <= 200
            && smartShiftSensitivity.map(Self.sensitivityRange.contains) ?? true
            && dpi.map((1...Int(UInt16.max)).contains) ?? true
            && smoothScrollingDistance.map(SmoothScrollingDistance.range.contains) ?? true
    }

    /// Nothing that schema 39 added is set.
    var isSchema38: Bool {
        highResolutionWheel == nil && usesGestureButton == nil && smoothScrolling == nil
            && smoothScrollingDistance == nil && smoothScrollingGlide == nil
    }

    /// The glide for this mouse's wheel, or nil when smooth scrolling is off for it.
    var smoothScrollingSettings: SmoothScrollingSettings? {
        guard smoothScrolling == true else { return nil }
        return SmoothScrollingSettings(glide: smoothScrollingGlide ?? .standard,
                                       pointsPerLine: Double(smoothScrollingDistance ?? SmoothScrollingDistance.standard))
    }

    static func deviceKey(vendorID: Int, name: String) -> String {
        String(format: "%04x:", vendorID) + name
    }
}
