// MIT License
// Copyright (c) 2026 Rebind

import Foundation

/// The bounded static-zone subset of HID++ 0x8071. No onboard-profile or EEPROM writes.
public struct RGBEffects: HIDPPFeature {
    public static let featureID = HIDPPFeatureID.rgbEffects

    public enum Activity: UInt8, Sendable { case idle = 0, active = 1 }

    /// Decode only this feature's unsolicited user-activity notification, not replies or key data.
    public static func activity(in report: [UInt8], featureIndex: UInt8) -> Activity? {
        guard report.count >= HIDPPConstants.shortReportLength,
              report[0] == HIDPPConstants.shortReportID || report[0] == HIDPPConstants.longReportID,
              report[2] == featureIndex, report[3] == 0x10 else { return nil }
        return Activity(rawValue: report[4])
    }

    public struct Zone: Equatable, Sendable {
        public let index: UInt8
        public let staticEffect: UInt8
        public let breathingEffect: UInt8?
        public let disabledEffect: UInt8?
    }

    public struct Control: Equatable, Sendable {
        public var flags: UInt8
        public var events: UInt8

        public init?(payload: [UInt8]) {
            guard payload.count >= 3, payload[0] == 0 else { return nil }
            flags = payload[1]
            events = payload[2]
        }
    }

    public struct PowerPolicy: Codable, Equatable, Hashable, Sendable {
        public var flags: UInt16
        public var dimSeconds: UInt16
        public var offSeconds: UInt16

        public init?(payload: [UInt8]) {
            guard payload.count >= 7, payload[0] == 0 else { return nil }
            flags = UInt16(payload[1]) << 8 | UInt16(payload[2])
            dimSeconds = UInt16(payload[3]) << 8 | UInt16(payload[4])
            offSeconds = UInt16(payload[5]) << 8 | UInt16(payload[6])
        }

        public var writeParameters: [UInt8] {
            [1, UInt8(flags >> 8), UInt8(flags & 0xFF), UInt8(dimSeconds >> 8), UInt8(dimSeconds & 0xFF),
             UInt8(offSeconds >> 8), UInt8(offSeconds & 0xFF)]
        }
    }

    private let transport: HIDPPTransport
    public let featureIndex: UInt8

    public init(transport: HIDPPTransport, featureIndex: UInt8) {
        self.transport = transport
        self.featureIndex = featureIndex
    }

    /// Require a complete, bounded inventory and static support in every zone before claiming it.
    public func zones() -> [Zone]? {
        guard let info = transport.request(featureIndex: featureIndex, function: 0, parameters: [255, 255, 0])?.payload,
              info.count >= 8, info[0] == 255, info[6] & 8 == 0,
              (1...8).contains(info[2]) else { return nil }
        var zones: [Zone] = []
        for index in 0..<info[2] {
            guard let bytes = transport.request(featureIndex: featureIndex, function: 0, parameters: [index, 255, 0])?.payload,
                  bytes.count >= 8, bytes[0] == index, (1...32).contains(bytes[4]) else { return nil }
            var fixed: UInt8?
            var breathing: UInt8?
            var disabled: UInt8?
            for effect in 0..<bytes[4] {
                guard let detail = transport.request(featureIndex: featureIndex, function: 0,
                                                     parameters: [index, effect, 0])?.payload,
                      detail.count >= 8, detail[0] == index, detail[1] == effect else { return nil }
                let id = UInt16(detail[2]) << 8 | UInt16(detail[3])
                if id == 1 { fixed = effect }
                if id == 0x0A { breathing = effect }
                if id == 0 { disabled = effect }
            }
            guard let fixed else { return nil }
            zones.append(Zone(index: index, staticEffect: fixed, breathingEffect: breathing, disabledEffect: disabled))
        }
        return zones
    }

    public func control() -> Control? {
        transport.request(featureIndex: featureIndex, function: 5, parameters: [0])
            .flatMap { Control(payload: $0.payload) }
    }

    public func setControl(_ control: Control) -> Bool {
        let bytes: [UInt8] = [1, control.flags, control.events]
        guard let reply = transport.requestOnce(featureIndex: featureIndex, function: 5, parameters: bytes) else { return false }
        return Array(reply.payload.prefix(3)) == bytes
    }

    public func powerPolicy() -> PowerPolicy? {
        transport.request(featureIndex: featureIndex, function: 7, parameters: [0])
            .flatMap { PowerPolicy(payload: $0.payload) }
    }

    public func setPowerPolicy(_ policy: PowerPolicy) -> Bool {
        transport.requestOnce(featureIndex: featureIndex, function: 7, parameters: policy.writeParameters) != nil
    }

    public func powerMode() -> UInt8? {
        guard let bytes = transport.request(featureIndex: featureIndex, function: 8, parameters: [0])?.payload,
              bytes.count >= 2, bytes[0] == 0, (1...3).contains(bytes[1]) else { return nil }
        return bytes[1]
    }

    /// Requires a power-control lease, which the owner must release after this transaction.
    public func setPowerMode(_ mode: UInt8) -> Bool {
        guard (1...3).contains(mode) else { return false }
        return transport.requestOnce(featureIndex: featureIndex, function: 8, parameters: [1, mode, 0]) != nil
    }

    public func setColor(_ color: UInt32, in zone: Zone, breathing: Bool = false) -> Bool {
        guard let parameters = Self.colorParameters(color, zone: zone, breathing: breathing) else { return false }
        return transport.requestOnce(featureIndex: featureIndex, function: 1, parameters: parameters) != nil
    }

    /// Switch off a zone only when its own inventory advertises the disabled effect.
    public func disable(_ zone: Zone) -> Bool {
        guard let effect = zone.disabledEffect else { return false }
        return transport.requestOnce(featureIndex: featureIndex, function: 1,
            parameters: [zone.index, effect] + Array(repeating: 0, count: 10) + [1, 0, 0, 0]) != nil
    }

    public static func colorParameters(_ color: UInt32, zone: Zone, breathing: Bool) -> [UInt8]? {
        guard color <= 0xFFFFFF, let effect = breathing ? zone.breathingEffect : zone.staticEffect else { return nil }
        var parameters: [UInt8] = [zone.index, effect, UInt8((color >> 16) & 0xFF), UInt8((color >> 8) & 0xFF), UInt8(color & 0xFF)]
        // Breathe: RGB, period BE (1 s), waveform, intensity. Static uses zero parameters.
        parameters += breathing ? [0x03, 0xE8, 0, 100, 0, 0, 0] : Array(repeating: 0, count: 7)
        return parameters + [1, 0, 0, 0] // Volatile, full-power target only.
    }
}
