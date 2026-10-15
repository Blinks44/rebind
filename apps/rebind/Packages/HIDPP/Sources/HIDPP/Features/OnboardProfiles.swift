// MIT License
// Copyright (c) 2026 Rebind, following the feature pattern of LinearMouse.

import Foundation

/// HID++ feature 0x8100 (ONBOARD_PROFILES) of gaming mice. In onboard mode the mouse applies
/// its stored profile and replaces a DPI the host writes; in host mode the host's values stay
/// (until the mouse is reset). G HUB switches to host mode the same way.
public struct OnboardProfiles {
    private enum Mode: UInt8 {
        case onboard = 0x01
        case host = 0x02
    }

    private let transport: HIDPPTransport
    private let featureIndex: UInt8

    public init(transport: HIDPPTransport, featureIndex: UInt8) {
        self.transport = transport
        self.featureIndex = featureIndex
    }

    public func isHostMode() -> Bool? {
        transport.request(featureIndex: featureIndex, function: 0x02, parameters: [])?.payload.first
            .map { $0 == Mode.host.rawValue }
    }

    /// Function 1 setOnboardMode.
    @discardableResult
    public func setHostMode() -> Bool {
        transport.requestOnce(featureIndex: featureIndex, function: 0x01, parameters: [Mode.host.rawValue]) != nil
    }
}
