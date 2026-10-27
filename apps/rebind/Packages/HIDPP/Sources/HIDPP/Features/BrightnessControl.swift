// MIT License
// Copyright (c) 2026 Rebind

import Foundation

/// HID++ 0x8040 brightness. Independent illumination is not assumed from brightness support.
public struct BrightnessControl: HIDPPFeature {
    public static let featureID = HIDPPFeatureID.brightnessControl

    public struct Info: Equatable, Sendable {
        public let minimum: UInt16
        public let maximum: UInt16
        public let steps: UInt16
        public let capabilities: UInt8

        public init?(payload: [UInt8]) {
            guard payload.count >= 7 else { return nil }
            minimum = UInt16(payload[4]) << 8 | UInt16(payload[5])
            maximum = UInt16(payload[0]) << 8 | UInt16(payload[1])
            steps = UInt16(payload[6]) << 8 | UInt16(payload[2])
            capabilities = payload[3]
            guard maximum > minimum else { return nil }
        }
    }

    private let transport: HIDPPTransport
    private let featureIndex: UInt8

    public init(transport: HIDPPTransport, featureIndex: UInt8) {
        self.transport = transport
        self.featureIndex = featureIndex
    }

    public func info() -> Info? {
        transport.request(featureIndex: featureIndex, function: 0, parameters: [])
            .flatMap { Info(payload: $0.payload) }
    }

    public func brightness() -> UInt16? {
        guard let bytes = transport.request(featureIndex: featureIndex, function: 1, parameters: [])?.payload,
              bytes.count >= 2 else { return nil }
        return UInt16(bytes[0]) << 8 | UInt16(bytes[1])
    }

    /// One acknowledged transaction; the owner must read back before confirming a setting.
    public func setBrightness(_ value: UInt16) -> Bool {
        transport.requestOnce(featureIndex: featureIndex, function: 2,
                              parameters: [UInt8(value >> 8), UInt8(value & 0xFF), 0]) != nil
    }
}
