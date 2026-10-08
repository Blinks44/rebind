import Foundation

/// ID identifies a live HID interface, not a persistent physical-device scope.
nonisolated struct HIDDeviceInfo: Identifiable, Equatable, Sendable {
    enum Kind: Hashable, Sendable { case keyboard, mouse, trackpad }
    enum Transport: Equatable, Sendable { case usb, bluetooth, builtIn, virtual, other }

    let id: UInt64
    var product: String?
    var manufacturer: String?
    var vendorID: UInt32?
    var productID: UInt32?
    var kinds: Set<Kind> = []
    var transport: Transport = .other
    var capabilities = HIDCapabilities()

    static func kinds(usagePairs: [(page: UInt16, usage: UInt16?)], declaresTrackpad: Bool) -> Set<Kind> {
        var result = Set<Kind>()
        for pair in usagePairs {
            switch (pair.page, pair.usage) {
            case (1, 6), (1, 7): result.insert(.keyboard)
            case (1, 1), (1, 2): result.insert(.mouse)
            case (13, 5): result.insert(.trackpad)
            default: break
            }
        }
        if declaresTrackpad { result.insert(.trackpad) }
        return result
    }

    static func cleanedLabel(_ label: String?) -> String? {
        guard let label else { return nil }
        let cleaned = String(label.unicodeScalars.filter { !CharacterSet.controlCharacters.contains($0) }
            .prefix(200)).trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? nil : cleaned
    }
}
