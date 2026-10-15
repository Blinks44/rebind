import Foundation

/// A successfully read charge. Missing/invalid replies never become a zero or full battery.
nonisolated struct PeripheralBatteryReading: Equatable, Sendable {
    let percentage: Int
    var isCharging = false

    static func normalized(_ value: Int, minimum: Int, maximum: Int) -> Self? {
        guard minimum >= 0, maximum > minimum, maximum <= 65_535,
              (minimum...maximum).contains(value) else { return nil }
        return Self(percentage: Int((Double(value - minimum) * 100 / Double(maximum - minimum)).rounded()))
    }
}
