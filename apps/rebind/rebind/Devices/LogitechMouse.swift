import Foundation
import HIDPP

/// What a HID++ mouse reports about the settings Rebind can change. A nil part means the
/// mouse lacks that feature, so its row is not shown.
nonisolated struct LogitechMouseState: Equatable, Sendable {
    var name: String?
    var wheelMode: WheelMode?
    var smartShiftSensitivity = 10
    var dpi: Int?
    var supportedDPI: [Int] = []

    var hasSettings: Bool { wheelMode != nil || dpi != nil }
}

/// One HID++ 2.0 mouse, directly connected (Bluetooth, USB cable) or behind a receiver slot.
/// Every call blocks until the mouse answers, so it is used only on `MouseHardware.queue`;
/// the main actor merely keeps the reference between calls (hence `@unchecked Sendable`).
nonisolated final class LogitechMouse: @unchecked Sendable {
    let slot: UInt8?
    private let transport: HIDPPTransport
    private let deviceName: DeviceName?
    private let smartShift: SmartShift?
    private let adjustableDPI: AdjustableDPI?

    /// Nil when nothing answers HID++ 2.0 at this address, or when it is not a pointing device.
    init?(io: HIDPPDeviceIO, slot: UInt8?) {
        guard let transport = HIDPPTransport(device: io, deviceIndex: slot, requestTimeout: 1) else { return nil }
        let nameIndex = transport.featureIndex(for: .deviceName)
        let name = nameIndex.map { DeviceName(transport: transport, featureIndex: $0) }
        if let kind = name?.kind(), ![.mouse, .trackball].contains(kind) { return nil }
        if let index = transport.featureIndex(for: .smartShiftEnhanced) {
            smartShift = SmartShift(transport: transport, featureIndex: index, isEnhanced: true)
        } else if let index = transport.featureIndex(for: .smartShift) {
            smartShift = SmartShift(transport: transport, featureIndex: index, isEnhanced: false)
        } else {
            smartShift = nil
        }
        adjustableDPI = transport.featureIndex(for: .adjustableDPI)
            .map { AdjustableDPI(transport: transport, featureIndex: $0) }
        // A device without DEVICE_NAME is still a mouse when it has one of the settings.
        guard nameIndex != nil || smartShift != nil || adjustableDPI != nil else { return nil }
        self.slot = slot
        self.transport = transport
        deviceName = name
    }

    func read() -> LogitechMouseState {
        var state = LogitechMouseState(name: deviceName?.name())
        if let mode = smartShift?.mode() {
            (state.wheelMode, state.smartShiftSensitivity) = Self.settings(for: mode, sensitivity: state.smartShiftSensitivity)
        }
        if let adjustableDPI {
            state.dpi = adjustableDPI.currentDPI()
            state.supportedDPI = adjustableDPI.supportedDPI
        }
        return state
    }

    /// Writes the stored values the mouse supports, then reads back what it now uses.
    func apply(_ settings: MouseHardwareSettings) -> LogitechMouseState {
        if let smartShift, let mode = Self.mode(for: settings) { smartShift.setMode(mode) }
        if let adjustableDPI, let dpi = settings.dpi { _ = adjustableDPI.setDPI(dpi) }
        return read()
    }

    /// The device mode for the stored choice; the sensitivity matters only for SmartShift.
    static func mode(for settings: MouseHardwareSettings) -> SmartShift.Mode? {
        switch settings.wheelMode {
        case .smartShift?:
            let sensitivity = settings.smartShiftSensitivity ?? 10
            let clamped = min(max(sensitivity, MouseHardwareSettings.sensitivityRange.lowerBound),
                              MouseHardwareSettings.sensitivityRange.upperBound)
            return .smartShift(threshold: UInt8(clamped))
        case .alwaysClick?: return .alwaysRatchet
        case .alwaysFreeSpin?: return .freeSpin
        case nil: return nil
        }
    }

    /// The shown choice for a device mode. A free-spin or always-click mouse keeps the last
    /// sensitivity, so switching back to SmartShift restores it.
    static func settings(for mode: SmartShift.Mode, sensitivity: Int) -> (WheelMode, Int) {
        switch mode {
        case let .smartShift(threshold):
            return (.smartShift, min(Int(threshold), MouseHardwareSettings.sensitivityRange.upperBound))
        case .alwaysRatchet: return (.alwaysClick, sensitivity)
        case .freeSpin: return (.alwaysFreeSpin, sensitivity)
        }
    }
}
