import Foundation
import HIDPP

/// User choices for one RGB input-device model. Nil color preserves its onboard colors.
nonisolated struct KeyboardLightingSettings: Codable, Hashable, Sendable {
    enum LowBattery: String, Codable, CaseIterable, Sendable { case keepColor, red, blinkingRed }
    /// Confirmed G915 TKL firmware levels. Zero is represented by the separate lighting switch.
    static let brightnessValues = [12, 25, 50, 100]
    /// Idle-off presets in seconds. Firmware zero is not Never, so Never is not offered.
    static let idleTimeouts = [30, 60, 120, 300, 600]

    var deviceKey: String
    var isEnabled = true
    var brightness = 50
    var color: UInt32?
    var lowBattery: LowBattery = .keepColor
    /// Seconds without activity before the device's native timer turns lighting off; nil keeps its own policy.
    var idleTimeout: Int?
    /// The device policy captured before the first idle-timeout write; Device default restores it.
    var devicePowerPolicy: RGBEffects.PowerPolicy?

    var isValid: Bool {
        !deviceKey.isEmpty && deviceKey.count <= 200 && (1...100).contains(brightness)
            && color.map { $0 <= 0xFFFFFF } ?? true
            && idleTimeout.map { Self.idleTimeouts.contains($0) && devicePowerPolicy != nil } ?? true
    }

    /// Native policy that turns lighting off after `seconds`. Measured on G915: a zero off delay
    /// switches off when the power-save delay expires, so the dim stage carries the whole wait.
    static func idlePolicy(_ seconds: Int, from policy: RGBEffects.PowerPolicy) -> RGBEffects.PowerPolicy {
        var result = policy
        result.dimSeconds = UInt16(seconds)
        result.offSeconds = 0
        return result
    }

    /// A missing charge is unknown, not an empty battery. Charging and recovery restore the preference.
    func output(percentage: Int?, charging: Bool, supportsBlinking: Bool) -> Output {
        let low = isEnabled && percentage.map { (0..<10).contains($0) } == true && !charging && lowBattery != .keepColor
        return Output(brightness: isEnabled ? (low ? min(brightness, 25) : brightness) : 0,
                      color: low ? 0xFF0000 : color,
                      breathing: low && lowBattery == .blinkingRed && supportsBlinking)
    }

    struct Output: Equatable, Sendable {
        var brightness: Int
        var color: UInt32?
        var breathing: Bool
    }
}
