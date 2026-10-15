import Foundation
import IOKit.hid

/// A connected mouse as Settings shows it.
nonisolated struct ConnectedMouse: Identifiable, Equatable, Sendable {
    enum Transport: Equatable, Sendable { case bluetooth, usb, receiver, other }

    /// Unique for this connection: the device's IOKit location plus its receiver slot.
    let id: String
    var name: String
    var manufacturer: String?
    var transport: Transport
    var vendorID: Int
    /// What a supported Logitech mouse reports; nil for every other mouse.
    var hardware: LogitechMouseState?

    var deviceKey: String { MouseHardwareSettings.deviceKey(vendorID: vendorID, name: name) }
}

/// Lists connected mice and keeps supported Logitech mice set as stored. Discovery runs on
/// the main run loop; HID++ requests run one at a time on `queue` because each one waits
/// for the mouse to answer.
@MainActor @Observable final class MouseHardware {
    nonisolated static let queue = DispatchQueue(label: "Rebind HID++", qos: .utility)

    private(set) var mice: [ConnectedMouse] = []
    @ObservationIgnored private var manager: IOHIDManager?
    @ObservationIgnored private var devices: [String: [IOHIDDevice]] = [:]
    /// Open HID++ endpoints and the mice found behind each, by IOKit location.
    @ObservationIgnored private var sessions: [String: Session] = [:]
    @ObservationIgnored private var rebuildScheduled = false
    /// The stored settings, written to a mouse of the same model whenever it connects.
    @ObservationIgnored var storedSettings: () -> [MouseHardwareSettings] = { [] }
    /// Whether Rebind may write to mice of a vendor now (no companion app controls them).
    @ObservationIgnored var canWrite: (Int) -> Bool = { _ in true }

    private final class Session {
        let io: HIDReportDevice
        var mice: [LogitechMouse] = []
        var probed = false
        init(io: HIDReportDevice) { self.io = io }
    }

    func start() {
        guard manager == nil else { return }
        let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        // Pointing devices, plus the vendor-defined interfaces that carry HID++ on receivers.
        let matching: [[String: Int]] = [
            [kIOHIDDeviceUsagePageKey: kHIDPage_GenericDesktop, kIOHIDDeviceUsageKey: kHIDUsage_GD_Mouse],
            [kIOHIDVendorIDKey: 0x046D, kIOHIDDeviceUsagePageKey: 0xFF00],
            [kIOHIDVendorIDKey: 0x046D, kIOHIDDeviceUsagePageKey: 0xFF43]
        ]
        IOHIDManagerSetDeviceMatchingMultiple(manager, matching as CFArray)
        let context = Unmanaged.passUnretained(self).toOpaque()
        IOHIDManagerRegisterDeviceMatchingCallback(manager, { context, _, _, device in
            guard let context else { return }
            MainActor.assumeIsolated { Unmanaged<MouseHardware>.fromOpaque(context).takeUnretainedValue().added(device) }
        }, context)
        IOHIDManagerRegisterDeviceRemovalCallback(manager, { context, _, _, device in
            guard let context else { return }
            MainActor.assumeIsolated { Unmanaged<MouseHardware>.fromOpaque(context).takeUnretainedValue().removed(device) }
        }, context)
        IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
        IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        self.manager = manager
    }

    func stop() {
        guard let manager else { return }
        IOHIDManagerUnscheduleFromRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
        IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        self.manager = nil
        sessions.values.forEach { $0.io.close() }
        sessions = [:]
        devices = [:]
        mice = []
    }

    /// Reads every supported mouse again and writes its stored settings: when Devices opens,
    /// after a configuration restore and when a companion app quits. A mouse behind a receiver
    /// that wakes from sleep is not noticed; it keeps its own settings anyway.
    func refresh() {
        for location in sessions.keys { probe(location) }
    }

    /// Writes new settings to every connected mouse of this model.
    func apply(_ settings: MouseHardwareSettings) {
        for (location, session) in sessions where session.probed {
            for mouse in mice where mouse.deviceKey == settings.deviceKey && mouse.hardware != nil
                && mouse.id.hasPrefix(location + "#") && canWrite(mouse.vendorID) {
                let slot = Self.slot(of: mouse.id)
                let found = session.mice.first { $0.slot == slot }
                // Show the choice at once; the mouse's answer replaces it a moment later.
                update(id: mouse.id, state: Self.expected(mouse.hardware, after: settings))
                Self.queue.async { [weak self] in
                    guard let state = found?.apply(settings) else { return }
                    Task { @MainActor in self?.update(id: mouse.id, state: state) }
                }
            }
        }
    }

    private func added(_ device: IOHIDDevice) {
        let location = Self.location(of: device)
        devices[location, default: []].append(device)
        scheduleRebuild()
    }

    private func removed(_ device: IOHIDDevice) {
        let location = Self.location(of: device)
        devices[location]?.removeAll { $0 == device }
        if devices[location]?.isEmpty == true {
            devices[location] = nil
            sessions.removeValue(forKey: location)?.io.close()
        }
        scheduleRebuild()
    }

    /// Devices arrive one interface at a time; list them once the burst is over.
    private func scheduleRebuild() {
        guard !rebuildScheduled else { return }
        rebuildScheduled = true
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            rebuildScheduled = false
            rebuild()
        }
    }

    private func rebuild() {
        var list: [ConnectedMouse] = []
        for (location, interfaces) in devices.sorted(by: { $0.key < $1.key }) {
            guard let pointer = interfaces.first(where: Self.isMouse) else { continue }
            let vendorID = Self.property(pointer, kIOHIDVendorIDKey) as Int? ?? 0
            let base = ConnectedMouse(id: location, name: Self.property(pointer, kIOHIDProductKey) ?? "",
                                      manufacturer: Self.property(pointer, kIOHIDManufacturerKey),
                                      transport: Self.transport(of: pointer), vendorID: vendorID)
            if sessions[location] == nil, vendorID == 0x046D,
               let endpoint = interfaces.first(where: Self.carriesHIDPP), let io = HIDReportDevice(endpoint) {
                sessions[location] = Session(io: io)
                probe(location)
            }
            let found = mice.filter { $0.id.hasPrefix(location + "#") }
            list += found.isEmpty ? [base] : found
        }
        if list != mice { mice = list }
    }

    /// Finds the HID++ mice at a location: the device itself, or each paired receiver slot.
    private func probe(_ location: String) {
        guard let session = sessions[location] else { return }
        let io = session.io
        let stored = Dictionary(storedSettings().map { ($0.deviceKey, $0) }, uniquingKeysWith: { first, _ in first })
        let base = mice.first { $0.id == location || $0.id.hasPrefix(location + "#") }
        let vendorID = base?.vendorID ?? 0x046D
        let writable = canWrite(vendorID)
        let fallbackName = base?.name ?? ""
        Self.queue.async { [weak self] in
            var found: [LogitechMouse] = []
            var states: [(UInt8?, LogitechMouseState)] = []
            if let direct = LogitechMouse(io: io, slot: nil) {
                found = [direct]
            } else {
                found = (1...6).compactMap { LogitechMouse(io: io, slot: $0) }
            }
            for mouse in found {
                var state = mouse.read()
                let key = MouseHardwareSettings.deviceKey(vendorID: vendorID, name: state.name ?? fallbackName)
                if writable, let saved = stored[key] { state = mouse.apply(saved) }
                states.append((mouse.slot, state))
            }
            Task { @MainActor in self?.probed(location, io: io, found: found, states: states) }
        }
    }

    private func probed(_ location: String, io: HIDReportDevice, found logitech: [LogitechMouse],
                        states: [(UInt8?, LogitechMouseState)]) {
        guard let session = sessions[location], session.io === io else { return }
        session.mice = logitech
        session.probed = true
        guard let pointer = devices[location]?.first(where: Self.isMouse) else { return }
        let vendorID = Self.property(pointer, kIOHIDVendorIDKey) as Int? ?? 0
        let name = Self.property(pointer, kIOHIDProductKey) ?? ""
        let found = states.map { slot, state in
            ConnectedMouse(id: "\(location)#\(slot.map(String.init) ?? "direct")", name: state.name ?? name,
                           manufacturer: Self.property(pointer, kIOHIDManufacturerKey),
                           transport: slot == nil ? Self.transport(of: pointer) : .receiver, vendorID: vendorID,
                           hardware: state.hasSettings ? state : nil)
        }
        var list = mice.filter { $0.id != location && !$0.id.hasPrefix(location + "#") }
        list += found.isEmpty ? [ConnectedMouse(id: location, name: name, manufacturer: Self.property(pointer, kIOHIDManufacturerKey),
                                                transport: Self.transport(of: pointer), vendorID: vendorID)] : found
        list.sort { $0.id < $1.id }
        if list != mice { mice = list }
    }

    /// A read that got no answer (a mouse going to sleep or away) keeps the last known state;
    /// removal of the device clears it.
    private func update(id: String, state: LogitechMouseState?) {
        guard let state, state.hasSettings, let index = mice.firstIndex(where: { $0.id == id }),
              mice[index].hardware != state else { return }
        mice[index].hardware = state
    }

    /// What a mouse should report once these settings are written.
    nonisolated static func expected(_ state: LogitechMouseState?, after settings: MouseHardwareSettings) -> LogitechMouseState? {
        guard var state else { return nil }
        if state.wheelMode != nil, let mode = LogitechMouse.mode(for: settings) {
            (state.wheelMode, state.smartShiftSensitivity) = LogitechMouse.settings(for: mode, sensitivity: state.smartShiftSensitivity)
        }
        if state.dpi != nil, let dpi = settings.dpi {
            state.dpi = state.supportedDPI.min { abs($0 - dpi) < abs($1 - dpi) } ?? dpi
        }
        return state
    }

    // MARK: IOKit properties

    nonisolated static func slot(of id: String) -> UInt8? {
        id.split(separator: "#").last.flatMap { UInt8($0) }
    }

    private nonisolated static func property<T>(_ device: IOHIDDevice, _ key: String) -> T? {
        IOHIDDeviceGetProperty(device, key as CFString) as? T
    }

    /// Interfaces of one physical device share a location; a Bluetooth device has one interface.
    private nonisolated static func location(of device: IOHIDDevice) -> String {
        if let location: Int = property(device, kIOHIDLocationIDKey) { return String(location, radix: 16) }
        var entry: UInt64 = 0
        IORegistryEntryGetRegistryEntryID(IOHIDDeviceGetService(device), &entry)
        return "service-" + String(entry, radix: 16)
    }

    private nonisolated static func usagePairs(_ device: IOHIDDevice) -> [(page: Int, usage: Int)] {
        (property(device, kIOHIDDeviceUsagePairsKey) as [[String: Int]]? ?? []).map {
            ($0[kIOHIDDeviceUsagePageKey] ?? 0, $0[kIOHIDDeviceUsageKey] ?? 0)
        }
    }

    /// A mouse or trackball, not a trackpad (which reports a digitizer usage) or the built-in one.
    private nonisolated static func isMouse(_ device: IOHIDDevice) -> Bool {
        property(device, kIOHIDPrimaryUsagePageKey) == kHIDPage_GenericDesktop
            && property(device, kIOHIDPrimaryUsageKey) == kHIDUsage_GD_Mouse
            && property(device, kIOHIDBuiltInKey) != true
            && !usagePairs(device).contains { $0.page == kHIDPage_Digitizer }
    }

    /// The interface that can take HID++ output reports: a vendor-defined usage and room for one.
    private nonisolated static func carriesHIDPP(_ device: IOHIDDevice) -> Bool {
        (property(device, kIOHIDMaxOutputReportSizeKey) as Int? ?? 0) >= 7
            && usagePairs(device).contains { $0.page >= 0xFF00 }
    }

    private nonisolated static func transport(of device: IOHIDDevice) -> ConnectedMouse.Transport {
        let value: String = property(device, kIOHIDTransportKey) ?? ""
        if value.localizedStandardContains("Bluetooth") { return .bluetooth }
        if value == kIOHIDTransportUSBValue { return .usb }
        return .other
    }
}
