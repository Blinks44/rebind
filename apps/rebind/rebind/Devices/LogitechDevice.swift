import Foundation
import HIDPP
import Synchronization

/// What a HID++ mouse or keyboard reports about the settings Rebind can change. A nil part means
/// the device lacks that feature, so its row is not shown. Keyboards may additionally expose supported lighting.
nonisolated struct LogitechDeviceState: Equatable, Sendable {
    var name: String?
    var isKeyboard = false
    var lighting: KeyboardLightingState?
    var lightingWriteFailed = false
    var wheelMode: WheelMode?
    var smartShiftSensitivity = 10
    var dpi: Int?
    var supportedDPI: [Int] = []
    var highResolutionWheel: Bool?
    /// The gesture button can be diverted to Rebind; whether it is, follows the stored setting.
    var hasGestureButton = false
    /// Battery charge in percent, and whether it is charging; nil without a battery feature.
    var batteryPercentage: Int?
    var batteryCharging = false
    /// A gaming mouse with onboard profiles, which G HUB manages while it runs.
    var hasOnboardProfiles = false

    var hasSettings: Bool { wheelMode != nil || dpi != nil || highResolutionWheel != nil || hasGestureButton }
}

/// One HID++ 2.0 mouse or keyboard, directly connected (Bluetooth, USB cable) or behind a receiver slot.
/// Every call blocks until the mouse answers, so it is used only on its session's queue in `MouseHardware`;
/// the main actor merely keeps the reference between calls (hence `@unchecked Sendable`).
nonisolated final class LogitechDevice: @unchecked Sendable {
    let slot: UInt8?
    let isKeyboard: Bool
    private let transport: HIDPPTransport
    /// Read once: it never changes while the device stays at this address, and reading it
    /// takes several requests.
    let name: String?
    private let smartShift: SmartShift?
    private let adjustableDPI: AdjustableDPI?
    private let hiResWheel: HiResWheel?
    private let battery: Battery?
    let controls: ReprogControls?
    private let onboardProfiles: OnboardProfiles?
    let lighting: KeyboardLighting?
    /// Asks the mouse about every control, one request each, so it waits until the stored
    /// pointer speed has been written.
    private var canDivertGestureButton: Bool {
        if let known = gestureButtonSupport.withLock({ $0 }) { return known }
        let found = controls?.canDivert(ReprogControls.gestureButton) ?? false
        gestureButtonSupport.withLock { $0 = found }
        return found
    }
    private let gestureButtonSupport = Mutex<Bool?>(nil)
    private let gestureOwnership: GestureButtonOwnership
    /// Connection-scoped ownership survives replacement of this feature adapter.
    var isGestureButtonDiverted: Bool { gestureOwnership.contains(slot ?? HIDPPConstants.receiverIndex) }

    /// Nil when nothing answers HID++ 2.0 at this address, or when it is neither a pointing device
    /// nor a keyboard with battery or supported lighting.
    init?(io: HIDPPDeviceIO, slot: UInt8?, gestureOwnership: GestureButtonOwnership = GestureButtonOwnership(),
          lightingOwnership: KeyboardLightingOwnership = KeyboardLightingOwnership()) {
        guard let transport = HIDPPTransport(device: io, deviceIndex: slot, requestTimeout: 1),
              let firstQuestion = HIDPPTransport(device: io, deviceIndex: slot, requestTimeout: 2.5) else { return nil }
        // One question first. A wireless device behind a receiver may need most of a second to wake
        // (the G915 TKL took 0.9 s), so it gets longer; an empty slot gets an error reply at once.
        // Without any answer the device is skipped instead of asking it every feature.
        guard let root = firstQuestion.request(featureIndex: 0x00, function: 0x00, parameters: HIDPPFeatureID.deviceName.bytes),
              let nameFeature = root.payload.first else { return nil }
        let nameIndex = nameFeature == 0 ? nil : nameFeature
        let name = nameIndex.map { DeviceName(transport: transport, featureIndex: $0) }
        let kind = name?.kind()
        // An unrecognised or unanswered type is not evidence of a mouse. Stop before
        // battery/settings queries when DEVICE_NAME exists but cannot classify the device.
        if nameIndex != nil, kind == nil { return nil }
        if let kind, ![.mouse, .trackball, .keyboard].contains(kind) { return nil }
        let isKeyboard = kind == .keyboard
        self.isKeyboard = isKeyboard
        let resolvedName = name?.name()
        // The first battery feature the device has, from the exact percentage to the voltage.
        let batterySources: [(HIDPPFeatureID, Battery.Source)] = [
            (.unifiedBattery, .unified), (.batteryStatus, .status), (.batteryVoltage, .voltage), (.adcMeasurement, .adcMeasurement)
        ]
        var foundBattery: Battery?
        for (feature, source) in batterySources {
            if let index = transport.featureIndex(for: feature) {
                foundBattery = Battery(transport: transport, featureIndex: index, source: source)
                break
            }
        }
        battery = foundBattery
        if isKeyboard, let brightness = transport.featureIndex(for: .brightnessControl),
           let rgb = transport.featureIndex(for: .rgbEffects), KeyboardLighting.supportsDevice(named: resolvedName) {
            lighting = KeyboardLighting(transport: transport, brightnessIndex: brightness, rgbIndex: rgb,
                                        ownership: lightingOwnership, slot: slot ?? HIDPPConstants.receiverIndex)
        } else { lighting = nil }
        // Keyboard key lists, diversion and onboard profile mode remain untouched.
        let mouseFeature = { (feature: HIDPPFeatureID) in isKeyboard ? nil : transport.featureIndex(for: feature) }
        if let index = mouseFeature(.smartShiftEnhanced) {
            smartShift = SmartShift(transport: transport, featureIndex: index, isEnhanced: true)
        } else if let index = mouseFeature(.smartShift) {
            smartShift = SmartShift(transport: transport, featureIndex: index, isEnhanced: false)
        } else {
            smartShift = nil
        }
        adjustableDPI = mouseFeature(.adjustableDPI).map { AdjustableDPI(transport: transport, featureIndex: $0) }
        hiResWheel = mouseFeature(.hiresWheel).map { HiResWheel(transport: transport, featureIndex: $0) }
        controls = mouseFeature(.reprogControlsV4).map { ReprogControls(transport: transport, featureIndex: $0) }
        onboardProfiles = mouseFeature(.onboardProfiles).map { OnboardProfiles(transport: transport, featureIndex: $0) }
        // A device without DEVICE_NAME is still a mouse when it has one of the settings;
        // a keyboard is listed for its battery or supported lighting.
        guard isKeyboard ? (battery != nil || lighting != nil) : (nameIndex != nil || smartShift != nil || adjustableDPI != nil) else { return nil }
        self.slot = slot
        self.gestureOwnership = gestureOwnership
        self.transport = transport
        self.name = resolvedName
    }

    /// A gaming mouse with onboard profiles, which G HUB manages while it runs.
    var hasOnboardProfiles: Bool { onboardProfiles != nil }

    func read() -> LogitechDeviceState {
        var state = LogitechDeviceState(name: name, isKeyboard: isKeyboard)
        if isKeyboard {
            (state.batteryPercentage, state.batteryCharging) = readBattery()
            state.lighting = lighting?.read()
            return state
        }
        if let mode = smartShift?.mode() {
            (state.wheelMode, state.smartShiftSensitivity) = Self.settings(for: mode, sensitivity: state.smartShiftSensitivity)
        }
        if let adjustableDPI {
            state.dpi = adjustableDPI.currentDPI()
            state.supportedDPI = adjustableDPI.supportedDPI
        }
        state.highResolutionWheel = hiResWheel?.isHighResolutionWheelEnabled()
        state.hasGestureButton = canDivertGestureButton
        state.hasOnboardProfiles = hasOnboardProfiles
        (state.batteryPercentage, state.batteryCharging) = readBattery()
        return state
    }

    func readBattery() -> (percentage: Int?, charging: Bool) {
        guard let status = battery?.status() else { return (nil, false) }
        return (status.percentage, status.isCharging)
    }

    /// Diverts the gesture button to Rebind or gives it back to the mouse.
    @discardableResult
    func divertGestureButton(_ diverted: Bool) -> Bool {
        guard canDivertGestureButton, let controls, diverted || isGestureButtonDiverted else { return false }
        let done = controls.setDiverted(ReprogControls.gestureButton, diverted)
        if done { gestureOwnership.setDiverted(diverted, at: slot ?? HIDPPConstants.receiverIndex, controls: controls) }
        return done
    }

    /// Writes the stored values the mouse supports, pointer speed first because a mouse that just
    /// connected moves at its own until then, and reads back what it now uses.
    func apply(_ settings: MouseHardwareSettings, canWrite: () -> Bool = { true }) -> LogitechDeviceState {
        guard !isKeyboard else { return read() }
        guard canWrite() else { return read() }
        if let adjustableDPI, let dpi = settings.dpi {
            // Read the value back and try once more: a gaming mouse in onboard mode (or one that just
            // woke) may keep its profile's DPI. Host mode makes the written value stay; after the
            // mouse reconnects, the receiver's notice brings it here again.
            let target = adjustableDPI.supportedDPI(nearestTo: dpi)
            for _ in 0 ..< 2 {
                guard canWrite() else { return read() }
                if let onboardProfiles, onboardProfiles.isHostMode() == false, canWrite() { onboardProfiles.setHostMode() }
                guard canWrite() else { return read() }
                _ = adjustableDPI.setDPI(dpi)
                if adjustableDPI.currentDPI() == target { break }
            }
        }
        if let smartShift, let mode = Self.mode(for: settings), canWrite() { smartShift.setMode(mode) }
        if let hiResWheel, let enabled = settings.highResolutionWheel, canWrite() {
            _ = hiResWheel.setHighResolutionWheelEnabled(enabled)
        }
        if canWrite() { divertGestureButton(settings.usesGestureButton == true) }
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
