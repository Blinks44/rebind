// MIT License
// Copyright (c) 2026 Rebind, following the feature pattern of LinearMouse.

import Foundation

/// The charge of a battery-powered device. Newer devices report a percentage through 0x1004
/// (UNIFIED_BATTERY) or 0x1000 (BATTERY_STATUS); many gaming devices, such as the G915 TKL,
/// report only the cell voltage through 0x1001 (BATTERY_VOLTAGE) or 0x1F20 (ADC_MEASUREMENT),
/// which is turned into an approximate percentage.
public struct Battery {
    public enum Source: Sendable { case unified, status, voltage, adcMeasurement }

    public struct Status: Equatable, Sendable {
        public let percentage: Int
        public let isCharging: Bool

        public init(percentage: Int, isCharging: Bool) {
            self.percentage = percentage
            self.isCharging = isCharging
        }
    }

    private let transport: HIDPPTransport
    private let featureIndex: UInt8
    private let source: Source

    public init(transport: HIDPPTransport, featureIndex: UInt8, source: Source) {
        self.transport = transport
        self.featureIndex = featureIndex
        self.source = source
    }

    public func status() -> Status? {
        // UNIFIED_BATTERY reads with function 1 (getStatus); the others with function 0.
        transport.request(featureIndex: featureIndex, function: source == .unified ? 0x01 : 0x00, parameters: [])
            .flatMap { Self.status(from: $0.payload, source: source) }
    }

    /// Unified: [percentage, level flags, charging status (1 charging, 2 slow, 3 full)].
    /// Status: [percentage, next level, status (1–4 charging or full)].
    /// Voltage and ADC: [millivolts high, low, flags (bit 7: external power)].
    static func status(from payload: [UInt8], source: Source) -> Status? {
        guard payload.count >= 3 else { return nil }
        switch source {
        case .unified, .status:
            guard (1 ... 100).contains(payload[0]) else { return nil }
            let charging = source == .unified ? (1 ... 3).contains(payload[2]) : (1 ... 4).contains(payload[2])
            return Status(percentage: Int(payload[0]), isCharging: charging)
        case .voltage, .adcMeasurement:
            let millivolts = Int(payload[0]) << 8 | Int(payload[1])
            guard millivolts > 0 else { return nil }
            return Status(percentage: percentage(millivolts: millivolts), isCharging: payload[2] & 0x80 != 0)
        }
    }

    /// An approximate charge of a single lithium-ion cell from its voltage under light load.
    static func percentage(millivolts: Int) -> Int {
        let curve: [(millivolts: Int, percent: Int)] = [
            (4150, 100), (4050, 90), (3970, 78), (3900, 62), (3820, 45), (3750, 28), (3680, 12), (3600, 4), (3500, 0)
        ]
        guard millivolts < curve[0].millivolts else { return 100 }
        for (upper, lower) in zip(curve, curve.dropFirst()) where millivolts >= lower.millivolts {
            let fraction = Double(millivolts - lower.millivolts) / Double(upper.millivolts - lower.millivolts)
            return lower.percent + Int((fraction * Double(upper.percent - lower.percent)).rounded())
        }
        return 0
    }
}
