// MIT License
// Copyright (c) 2026 Rebind, following the AdjustableDPI pattern of LinearMouse.

import Foundation

/// The ratchet of a SmartShift wheel: HID++ feature 0x2110 (SMART_SHIFT) or its
/// enhanced variant 0x2111 found on the MX Master 3 and later. Both carry the same
/// three-byte payload `[wheelMode, autoDisengage, autoDisengageDefault]`; the enhanced
/// variant adds a capabilities function first, which moves get and set by one.
public struct SmartShift {
    /// What the wheel does. The threshold is the scroll speed, in device units
    /// (1...254), at which a ratcheting wheel releases into free spin.
    public enum Mode: Equatable, Sendable {
        case smartShift(threshold: UInt8)
        case alwaysRatchet
        case freeSpin
    }

    private enum Constants {
        static let freeSpin: UInt8 = 0x01
        static let ratchet: UInt8 = 0x02
        static let neverDisengage: UInt8 = 0xFF
    }

    public static let thresholdRange: ClosedRange<UInt8> = 1 ... 254

    private let transport: HIDPPTransport
    private let featureIndex: UInt8
    private let isEnhanced: Bool

    public init(transport: HIDPPTransport, featureIndex: UInt8, isEnhanced: Bool) {
        self.transport = transport
        self.featureIndex = featureIndex
        self.isEnhanced = isEnhanced
    }

    private var getFunction: UInt8 { isEnhanced ? 0x01 : 0x00 }
    private var setFunction: UInt8 { isEnhanced ? 0x02 : 0x01 }

    public func mode() -> Mode? {
        transport.request(featureIndex: featureIndex, function: getFunction, parameters: [])
            .flatMap { Self.mode(from: $0.payload) }
    }

    @discardableResult
    public func setMode(_ mode: Mode) -> Bool {
        transport.requestOnce(featureIndex: featureIndex, function: setFunction,
                              parameters: Self.parameters(for: mode)) != nil
    }

    /// The set request: a zero default leaves the device's own default untouched.
    public static func parameters(for mode: Mode) -> [UInt8] {
        switch mode {
        case let .smartShift(threshold):
            let clamped = min(max(threshold, thresholdRange.lowerBound), thresholdRange.upperBound)
            return [Constants.ratchet, clamped, 0x00]
        case .alwaysRatchet:
            return [Constants.ratchet, Constants.neverDisengage, 0x00]
        case .freeSpin:
            return [Constants.freeSpin, 0x00, 0x00]
        }
    }

    public static func mode(from payload: [UInt8]) -> Mode? {
        guard payload.count >= 2 else { return nil }
        switch payload[0] {
        case Constants.freeSpin:
            return .freeSpin
        case Constants.ratchet:
            return thresholdRange.contains(payload[1]) ? .smartShift(threshold: payload[1]) : .alwaysRatchet
        default:
            return nil
        }
    }
}
