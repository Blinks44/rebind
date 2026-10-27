import Foundation

/// User choices for one keyboard model. Nil color preserves its onboard colors.
nonisolated struct KeyboardLightingSettings: Codable, Hashable, Sendable {
    enum LowBattery: String, Codable, CaseIterable, Sendable { case keepColor, red, blinkingRed }
    /// Confirmed G915 TKL firmware levels. Zero is represented by the separate lighting switch.
    static let brightnessValues = [12, 25, 50, 100]

    var deviceKey: String
    var isEnabled = true
    var brightness = 50
    var color: UInt32?
    var lowBattery: LowBattery = .keepColor

    var isValid: Bool {
        !deviceKey.isEmpty && deviceKey.count <= 200 && Self.brightnessValues.contains(brightness)
            && color.map { $0 <= 0xFFFFFF } ?? true
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
