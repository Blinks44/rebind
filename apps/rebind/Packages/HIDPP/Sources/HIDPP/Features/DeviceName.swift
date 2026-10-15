// MIT License
// Copyright (c) 2026 Rebind, following the feature pattern of LinearMouse.

import Foundation

/// HID++ feature 0x0005 (DEVICE_NAME): the marketing name and kind of a device,
/// which a receiver slot does not expose through IOKit.
public struct DeviceName: HIDPPFeature {
    public static let featureID = HIDPPFeatureID.deviceName

    /// The device kinds of feature 0x0005 that move a pointer.
    public enum Kind: UInt8, Sendable {
        case keyboard = 0, remoteControl, numpad, mouse, trackpad, trackball, presenter, receiver
    }

    private let transport: HIDPPTransport
    private let featureIndex: UInt8

    public init(transport: HIDPPTransport, featureIndex: UInt8) {
        self.transport = transport
        self.featureIndex = featureIndex
    }

    public func name() -> String? {
        guard let count = transport.request(featureIndex: featureIndex, function: 0x00, parameters: [])?
            .payload.first, count > 0 else { return nil }
        var bytes = [UInt8]()
        while bytes.count < Int(count) {
            guard let chunk = transport.request(featureIndex: featureIndex, function: 0x01,
                                                parameters: [UInt8(bytes.count)])?.payload,
                  !chunk.isEmpty else { return nil }
            bytes.append(contentsOf: chunk.prefix(Int(count) - bytes.count))
        }
        return Self.decodeName(bytes)
    }

    public func kind() -> Kind? {
        transport.request(featureIndex: featureIndex, function: 0x02, parameters: [])?
            .payload.first.flatMap(Kind.init(rawValue:))
    }

    /// UTF-8 bytes padded with zeros at the end of the last report.
    static func decodeName(_ bytes: [UInt8]) -> String? {
        let name = String(decoding: bytes.prefix { $0 != 0 }, as: UTF8.self)
            .trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? nil : name
    }
}
