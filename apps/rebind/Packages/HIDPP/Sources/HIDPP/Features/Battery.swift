// MIT License
// Copyright (c) 2026 Rebind, following the feature pattern of LinearMouse.

import Foundation

/// The charge of a battery-powered device: HID++ feature 0x1004 (UNIFIED_BATTERY), found on
/// newer mice, or the older 0x1000 (BATTERY_STATUS).
public struct Battery {
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
    private let isUnified: Bool

    public init(transport: HIDPPTransport, featureIndex: UInt8, isUnified: Bool) {
        self.transport = transport
        self.featureIndex = featureIndex
        self.isUnified = isUnified
    }

    public func status() -> Status? {
        // UNIFIED_BATTERY: function 1 getStatus; BATTERY_STATUS: function 0 getBatteryLevelStatus.
        transport.request(featureIndex: featureIndex, function: isUnified ? 0x01 : 0x00, parameters: [])
            .flatMap { Self.status(from: $0.payload, isUnified: isUnified) }
    }

    /// Unified: [percentage, level flags, charging status (1 charging, 2 slow, 3 full)].
    /// Legacy: [percentage, next level, status (1–4 charging or full)].
    static func status(from payload: [UInt8], isUnified: Bool) -> Status? {
        guard payload.count >= 3, (1 ... 100).contains(payload[0]) else { return nil }
        let charging = isUnified ? (1 ... 3).contains(payload[2]) : (1 ... 4).contains(payload[2])
        return Status(percentage: Int(payload[0]), isCharging: charging)
    }
}
