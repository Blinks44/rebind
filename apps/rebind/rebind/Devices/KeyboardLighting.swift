import Foundation
import HIDPP
import Synchronization

nonisolated struct KeyboardLightingState: Equatable, Sendable {
    var brightness: Int
    var supportsBlinking: Bool
    var isExperimental = false
    var brightnessValues = KeyboardLightingSettings.brightnessValues
    var supportsPower = true
    var supportsLowBattery = true
    /// The native idle policy now on the device; nil hides the idle-timeout menu.
    var powerPolicy: RGBEffects.PowerPolicy?
    var isEnabled: Bool { brightness > 0 }
}

/// Connection-scoped claims survive a feature refresh and are released on the same serial I/O queue.
nonisolated final class KeyboardLightingOwnership: Sendable {
    private struct Claim: @unchecked Sendable {
        // Immutable feature handles are called only on the connection's serial queue.
        let rgb: RGBEffects
        let original: RGBEffects.Control
        var ownedFlags: UInt8
        var ownedEvents: UInt8 = 0
    }
    private let claims = Mutex<[UInt8: Claim]>([:])

    func claim(_ rgb: RGBEffects, slot: UInt8, canWrite: () -> Bool) -> Bool {
        guard canWrite(), var current = rgb.control() else { return false }
        let original: RGBEffects.Control
        if let own = claims.withLock({ $0[slot] }) {
            guard current.flags & ~own.ownedFlags == own.original.flags & ~own.ownedFlags else { return false }
            original = own.original
            current.flags = (current.flags & ~own.ownedFlags) | original.flags | 1 | (own.ownedFlags & 2)
        } else {
            // Do not take another application's software-controlled lighting.
            guard current.flags == 0 else { return false }
            original = current
            current.flags |= 1
        }
        // Keep a cleanup obligation even if a write applies but its acknowledgement is lost.
        claims.withLock { if $0[slot] == nil { $0[slot] = Claim(rgb: rgb, original: original, ownedFlags: 1) } }
        guard canWrite(), rgb.setControl(current) else { return false }
        claims.withLock { $0[slot]?.ownedFlags |= 1 }
        return true
    }

    /// An explicit UI change may wake lighting. A temporary power lease is always relinquished.
    func wake(_ rgb: RGBEffects, slot: UInt8, canWrite: () -> Bool) -> Bool {
        guard canWrite(), let current = rgb.control() else { return false }
        let previous = claims.withLock { $0[slot] }
        if let previous {
            guard current.flags & ~previous.ownedFlags == previous.original.flags & ~previous.ownedFlags else { return false }
        } else if current.flags != 0 { return false }
        var power = current
        power.flags |= 2
        claims.withLock {
            $0[slot] = Claim(rgb: rgb, original: previous?.original ?? current,
                            ownedFlags: (previous?.ownedFlags ?? 0) | 2, ownedEvents: previous?.ownedEvents ?? 0)
        }
        guard canWrite(), rgb.setControl(power), canWrite(), rgb.setPowerMode(1),
              canWrite(), rgb.setControl(current), rgb.powerMode() == 1 else { return false }
        claims.withLock { $0[slot] = previous }
        return true
    }

    /// The keyboard times inactivity; software must explicitly switch LEDs when it reports it.
    /// Request only timeout events while lit and only activity events while off.
    func configureIdle(_ rgb: RGBEffects, slot: UInt8, enabled: Bool, active: Bool = true, notifications: Bool = true,
                       canWrite: () -> Bool) -> Bool {
        let previous = claims.withLock { $0[slot] }
        if !enabled, (previous?.ownedFlags ?? 0) & 2 == 0 { return true }
        guard canWrite(), var current = rgb.control() else { return false }
        let original = previous?.original ?? current
        let ownedFlags = previous?.ownedFlags ?? 0
        guard current.flags & ~ownedFlags == original.flags & ~ownedFlags,
              previous != nil || current.flags == 0 else { return false }
        current.flags = enabled ? current.flags | 2 : (current.flags & ~2) | (original.flags & 2)
        let requestedEvents: UInt8 = notifications ? (active ? 4 : 2) : 0
        current.events = (current.events & ~6) | (enabled ? requestedEvents : original.events & 6)
        // Retain both masks until acknowledgement, including ambiguous write failures.
        claims.withLock {
            $0[slot] = Claim(rgb: rgb, original: original, ownedFlags: ownedFlags | 2,
                            ownedEvents: (previous?.ownedEvents ?? 0) | 6)
        }
        guard canWrite(), rgb.setControl(current) else { return false }
        claims.withLock {
            if enabled {
                $0[slot]?.ownedFlags |= 2
            } else if var claim = $0[slot] {
                claim.ownedFlags &= ~2
                claim.ownedEvents &= ~6
                $0[slot] = claim.ownedFlags == 0 && claim.ownedEvents == 0 ? nil : claim
            }
        }
        return true
    }

    /// Send a power transition only while this connection owns power control.
    func setPowerMode(_ mode: UInt8, slot: UInt8, canWrite: () -> Bool) -> Bool {
        guard let claim = claims.withLock({ $0[slot] }), claim.ownedFlags & 2 != 0,
              canWrite(), let current = claim.rgb.control(), current.flags & 2 != 0,
              current.flags & ~claim.ownedFlags == claim.original.flags & ~claim.ownedFlags,
              canWrite(), claim.rgb.setPowerMode(mode) else { return false }
        return true
    }

    func release(slot: UInt8, colorOnly: Bool = false, canWrite: () -> Bool) -> Bool {
        guard let claim = claims.withLock({ $0[slot] }) else { return true }
        guard canWrite(), var current = claim.rgb.control() else { return false }
        guard current.flags & ~claim.ownedFlags == claim.original.flags & ~claim.ownedFlags else { return false }
        let flags = colorOnly ? claim.ownedFlags & 1 : claim.ownedFlags
        let events: UInt8 = colorOnly ? 0 : claim.ownedEvents
        guard flags != 0 || events != 0 else { return true }
        current.flags = (current.flags & ~flags) | (claim.original.flags & flags)
        current.events = (current.events & ~events) | (claim.original.events & events)
        guard canWrite(), claim.rgb.setControl(current) else { return false }
        claims.withLock {
            var remaining = claim
            remaining.ownedFlags &= ~flags
            remaining.ownedEvents &= ~events
            $0[slot] = remaining.ownedFlags == 0 && remaining.ownedEvents == 0 ? nil : remaining
        }
        return true
    }

    func releaseAll(canWrite: () -> Bool) {
        for slot in claims.withLock({ Array($0.keys) }) { _ = release(slot: slot, canWrite: canWrite) }
    }
}

/// All methods run on the owning HID endpoint's serial queue. No UI, global input or host idle timer.
nonisolated final class KeyboardLighting {
    /// Admit the measured firmware family; feature presence alone does not establish brightness semantics.
    static func supportsDevice(named name: String?) -> Bool {
        name?.hasPrefix("G915 TKL LIGHTSPEED ") == true
    }
    private let brightness: BrightnessControl?
    private let info: BrightnessControl.Info?
    private let isExperimental: Bool
    let rgb: RGBEffects
    let brightnessFeature: UInt8?
    private let zones: [RGBEffects.Zone]
    private let ownership: KeyboardLightingOwnership
    private let slot: UInt8
    private var lastOutput: KeyboardLightingSettings.Output?
    private var managesIdlePower = false
    private var isIdleOff = false
    var usesIdleNotifications: Bool { managesIdlePower }

    /// Firmware-advertised halving levels include zero; continuous ranges advertise no steps.
    private var rawBrightnessValues: [UInt16] {
        guard let info, (2...16).contains(info.steps) else { return [] }
        return Set((0..<Int(info.steps - 1)).map { info.maximum >> $0 }
            .filter { $0 > 0 && $0 >= info.minimum }).sorted()
    }

    private func percentage(_ raw: UInt16, maximum: UInt16) -> Int {
        max(1, Int((Double(raw) * 100 / Double(maximum)).rounded()))
    }

    init?(transport: HIDPPTransport, brightnessIndex: UInt8?, rgbIndex: UInt8,
          ownership: KeyboardLightingOwnership, slot: UInt8, isExperimental: Bool = false) {
        let brightness = brightnessIndex.map { BrightnessControl(transport: transport, featureIndex: $0) }
        let rgb = RGBEffects(transport: transport, featureIndex: rgbIndex)
        let info = brightness?.info()
        guard let zones = rgb.zones(), !zones.isEmpty else { return nil }
        if !isExperimental {
            guard let info, info.minimum == 0, info.maximum == 100, info.steps == 5 else { return nil }
        }
        // A malformed brightness feature must not prevent an independent static-color engine.
        let usableBrightness = info.map { ($0.minimum == 0 || $0.capabilities & 4 != 0) && $0.steps <= 16 } == true
        self.brightness = usableBrightness ? brightness : nil
        self.info = usableBrightness ? info : nil
        self.isExperimental = isExperimental
        self.rgb = rgb
        self.zones = zones
        self.ownership = ownership
        self.slot = slot
        brightnessFeature = usableBrightness ? brightnessIndex : nil
    }

    func read() -> KeyboardLightingState? {
        let value: Int
        if let brightness, let info {
            guard let raw = brightness.brightness(), raw <= info.maximum else { return nil }
            if info.capabilities & 4 != 0 {
                guard let enabled = brightness.illumination() else { return nil }
                value = enabled ? percentage(raw, maximum: info.maximum) : 0
            } else { value = Int((Double(raw) * 100 / Double(info.maximum)).rounded()) }
        } else { value = lastOutput?.brightness ?? 100 }
        return KeyboardLightingState(brightness: value,
            supportsBlinking: zones.allSatisfy { $0.breathingEffect != nil }, isExperimental: isExperimental,
            brightnessValues: brightness == nil ? [] : (rawBrightnessValues.isEmpty ? Array(1...100)
                : Array(Set(rawBrightnessValues.map { percentage($0, maximum: info?.maximum ?? 100) })).sorted()),
            supportsPower: brightness != nil || zones.allSatisfy { $0.disabledEffect != nil },
            supportsLowBattery: !isExperimental || rgb.powerMode() != nil,
            // The zero-off timer mapping is measured on G915 only.
            powerPolicy: isExperimental ? nil : rgb.powerPolicy())
    }

    func apply(_ settings: KeyboardLightingSettings, percentage: Int?, charging: Bool,
               background: Bool = false, deferIdleNotifications: Bool = false, canWrite: () -> Bool) -> Bool {
        guard settings.isValid, canWrite() else { return false }
        if !isExperimental, !KeyboardLightingSettings.brightnessValues.contains(settings.brightness) { return false }
        let supportsBlinking = zones.allSatisfy { $0.breathingEffect != nil }
        guard settings.lowBattery != .blinkingRed || supportsBlinking else { return false }
        let output = settings.output(percentage: percentage, charging: charging, supportsBlinking: supportsBlinking)
        // Battery refresh never wakes dimmed/off lighting. A connection/wake reprobe applies the pending preference.
        if background {
            if isIdleOff { return true }
            if percentage == nil, !charging, settings.lowBattery != .keepColor { return true }
            guard output != lastOutput else { return true }
            guard rgb.powerMode() == 1 else { return true }
        }
        let previousBrightness = brightness?.brightness()
        let previousIllumination = info.map { $0.capabilities & 4 != 0 } == true ? brightness?.illumination() : nil
        var completed = false
        var attemptedBrightness = false
        defer {
            if !completed {
                managesIdlePower = false
            }
            if !completed, canWrite() {
                _ = ownership.release(slot: slot, canWrite: canWrite)
                if attemptedBrightness, let previousBrightness, canWrite() { _ = brightness?.setBrightness(previousBrightness) }
                if attemptedBrightness, let previousIllumination, canWrite() { _ = brightness?.setIllumination(previousIllumination) }
            }
        }
        if !background, output.brightness > 0 {
            // Some RGB engines do not implement power modes. They can still set a static color.
            if let mode = rgb.powerMode(), mode != 1 {
                guard ownership.wake(rgb, slot: slot, canWrite: canWrite) else { return false }
            }
        }
        if output.brightness == 0, brightness == nil {
            guard zones.allSatisfy({ $0.disabledEffect != nil }), ownership.claim(rgb, slot: slot, canWrite: canWrite) else { return false }
            for zone in zones {
                guard canWrite(), rgb.disable(zone) else { return false }
            }
        } else if output.brightness > 0 {
            if let color = output.color {
                guard ownership.claim(rgb, slot: slot, canWrite: canWrite) else { return false }
                for zone in zones {
                    guard canWrite(), rgb.setColor(color, in: zone, breathing: output.breathing) else { return false }
                }
            } else {
                guard ownership.release(slot: slot, colorOnly: true, canWrite: canWrite) else { return false }
            }
        }
        if let brightness, let info {
            let illumination = info.capabilities & 4 != 0
            guard canWrite() else { return false }
            attemptedBrightness = true
            if illumination {
                guard brightness.setIllumination(output.brightness > 0), canWrite(),
                      brightness.illumination() == (output.brightness > 0) else { return false }
            }
            if output.brightness > 0 || !illumination {
                let requested = max(info.minimum, UInt16((Double(output.brightness) * Double(info.maximum) / 100).rounded()))
                let raw = output.brightness == 0 ? 0 : (rawBrightnessValues.min {
                    abs(Int($0) - Int(requested)) < abs(Int($1) - Int(requested))
                } ?? requested)
                guard canWrite(), brightness.setBrightness(raw), brightness.brightness() == raw, canWrite() else { return false }
            }
        }
        if !background, !isExperimental, let original = settings.devicePowerPolicy {
            guard let current = rgb.powerPolicy() else { return false }
            let target = settings.idleTimeout.map { KeyboardLightingSettings.idlePolicy($0, from: current) } ?? original
            if current != target {
                guard canWrite(), rgb.setPowerPolicy(target), rgb.powerPolicy() == target else { return false }
            }
        }
        if !background, !isExperimental {
            let enabled = settings.idleTimeout != nil && output.brightness > 0
            guard ownership.configureIdle(rgb, slot: slot, enabled: enabled, notifications: !deferIdleNotifications,
                                          canWrite: canWrite) else { return false }
            managesIdlePower = enabled
            isIdleOff = false
        }
        lastOutput = output
        completed = true
        return true
    }

    /// Re-arm after the notification handler is installed; an already-idle device may report immediately.
    func armIdleNotifications(canWrite: () -> Bool) -> Bool {
        guard managesIdlePower else { return true }
        guard ownership.configureIdle(rgb, slot: slot, enabled: true, active: !isIdleOff, canWrite: canWrite) else {
            managesIdlePower = false
            _ = ownership.release(slot: slot, canWrite: canWrite)
            return false
        }
        return true
    }

    /// Called only on the endpoint queue, from native RGB activity notifications (never key data).
    func handleActivity(_ activity: RGBEffects.Activity, canWrite: () -> Bool) -> Bool {
        guard managesIdlePower else { return true }
        let active = activity == .active
        guard active == isIdleOff else { return true }
        guard ownership.configureIdle(rgb, slot: slot, enabled: true, active: active, canWrite: canWrite),
              ownership.setPowerMode(active ? 1 : 3, slot: slot, canWrite: canWrite) else {
            managesIdlePower = false
            _ = ownership.release(slot: slot, canWrite: canWrite)
            return false
        }
        isIdleOff = !active
        return true
    }
}
