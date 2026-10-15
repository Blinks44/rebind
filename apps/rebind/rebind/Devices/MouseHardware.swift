import Foundation
import HIDPP
import IOKit.hid
import Synchronization

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
    var hardware: LogitechDeviceState?

    var deviceKey: String { MouseHardwareSettings.deviceKey(vendorID: vendorID, name: name) }
}

/// The charge of a connected mouse, keyboard or trackpad, for the Menu Bar item.
nonisolated struct DeviceBattery: Identifiable, Equatable, Sendable {
    enum Kind: Sendable { case mouse, keyboard, trackpad, other }
    let id: String
    var name: String
    var kind: Kind
    var percentage: Int
    var isCharging: Bool
    var vendorID: Int = 0

    var deviceKey: String { MouseHardwareSettings.deviceKey(vendorID: vendorID, name: name) }
}

/// Discovered keyboards and battery devices that have no mouse settings.
nonisolated struct ConnectedAccessory: Identifiable, Equatable, Sendable {
    let id: String
    var name: String
    var kind: DeviceBattery.Kind
    var vendorID: Int

    var deviceKey: String { MouseHardwareSettings.deviceKey(vendorID: vendorID, name: name) }
}

/// Lists connected mice and keeps supported Logitech mice set as stored. Discovery runs on
/// the main run loop; HID++ requests run one at a time on `queue` because each one waits
/// for the mouse to answer.
@MainActor @Observable final class MouseHardware {

    private(set) var mice: [ConnectedMouse] = []
    /// Charges of Logitech devices (mice and keyboards) and of devices macOS reports, by name.
    private(set) var batteries: [DeviceBattery] = []
    private var keyboards: [String: [ConnectedAccessory]] = [:]

    var accessories: [ConnectedAccessory] {
        let keyboards = keyboards.sorted { $0.key < $1.key }.flatMap(\.value)
        let known = Set(mice.map(\.deviceKey) + keyboards.map(\.deviceKey))
        // Devices is for input hardware; a macOS battery reading alone does not qualify
        // a headset or an unclassified accessory for a settings card.
        return keyboards + batteries.filter { $0.kind != .other && !known.contains($0.deviceKey) }.map {
            ConnectedAccessory(id: $0.id, name: $0.name, kind: $0.kind, vendorID: $0.vendorID)
        }
    }
    @ObservationIgnored private var logitechBatteries: [String: [DeviceBattery]] = [:]
    @ObservationIgnored private var batteryTimer: Timer?
    @ObservationIgnored private var manager: IOHIDManager?
    @ObservationIgnored private var devices: [String: [IOHIDDevice]] = [:]
    /// Open HID++ endpoints and the mice found behind each, by IOKit location.
    @ObservationIgnored private var sessions: [String: Session] = [:]
    @ObservationIgnored private var rebuildScheduled = false
    /// The stored settings, written to a mouse of the same model whenever it connects.
    @ObservationIgnored var storedSettings: () -> [MouseHardwareSettings] = { [] }
    /// Whether Rebind may write to mice of a vendor now (no companion app controls them).
    /// Arguments: vendor, and whether it is a gaming mouse with onboard profiles.
    @ObservationIgnored var canWrite: (Int, Bool) -> Bool = { _, _ in true }
    /// Receives presses (true) and releases of a diverted gesture button, on the HID report thread.
    @ObservationIgnored var gestureButtonChanged: @Sendable (Bool) -> Void = { _ in }
    /// Receives smooth scrolling per HID service that sends a mouse's wheel events.
    @ObservationIgnored var smoothScrollingChanged: ([UInt64: SmoothScrollingSettings]) -> Void = { _ in }

    /// One opened HID++ endpoint (a device or a receiver) and the devices found behind it. Its
    /// requests wait for answers, so each endpoint has its own serial queue: a sleeping keyboard
    /// never delays a mouse on another receiver.
    private final class Session {
        let io: HIDReportDevice
        let queue: DispatchQueue
        var mice: [LogitechDevice] = []
        var probed = false
        init(io: HIDReportDevice, location: String) {
            self.io = io
            queue = DispatchQueue(label: "Rebind HID++ \(location)", qos: .utility)
        }
    }

    func start() {
        guard manager == nil else { return }
        let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        // Pointing devices, Logitech keyboards (for their battery), and the vendor-defined interfaces
        // that carry HID++.
        let matching: [[String: Int]] = [
            [kIOHIDDeviceUsagePageKey: kHIDPage_GenericDesktop, kIOHIDDeviceUsageKey: kHIDUsage_GD_Mouse],
            [kIOHIDVendorIDKey: 0x046D, kIOHIDDeviceUsagePageKey: kHIDPage_GenericDesktop, kIOHIDDeviceUsageKey: kHIDUsage_GD_Keyboard],
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
        // Charges change slowly; a few reads every five minutes are enough for the Menu Bar.
        batteryTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.refreshBatteries() }
        }
        publishBatteries()
    }

    func stop() {
        guard let manager else { return }
        batteryTimer?.invalidate()
        batteryTimer = nil
        releaseGestureButtons()
        IOHIDManagerUnscheduleFromRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
        IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        self.manager = nil
        sessions.values.forEach { $0.io.close() }
        sessions = [:]
        devices = [:]
        mice = []
        keyboards = [:]
        logitechBatteries = [:]
        batteries = []
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
                && mouse.id.hasPrefix(location + "#")
                && canWrite(mouse.vendorID, mouse.hardware?.hasOnboardProfiles ?? false) {
                let slot = Self.slot(of: mouse.id)
                let found = session.mice.first { $0.slot == slot }
                // Show the choice at once; the mouse's answer replaces it a moment later.
                update(id: mouse.id, state: Self.expected(mouse.hardware, after: settings))
                session.queue.async { [weak self] in
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
            logitechBatteries[location] = nil
            keyboards[location] = nil
            publishBatteries()
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
            let pointer = interfaces.first(where: Self.isMouse)
            // A Logitech keyboard has no mouse interface but still reports its battery over HID++.
            let vendorID = (pointer ?? interfaces.first).flatMap { Self.property($0, kIOHIDVendorIDKey) as Int? } ?? 0
            // Only mice, keyboards and their receivers: a Logitech headset has a vendor interface too,
            // and asking it for HID++ devices only kept the queue waiting for seconds.
            if sessions[location] == nil,
               Self.allowsHIDPP(vendorID: vendorID, usages: interfaces.flatMap(Self.usagePairs)),
               let endpoint = interfaces.first(where: Self.carriesHIDPP), let io = HIDReportDevice(endpoint) {
                sessions[location] = Session(io: io, location: location)
                probe(location)
            }
            guard let pointer else { continue }
            if let known = sessions[location]?.mice, !known.isEmpty, known.allSatisfy(\.isKeyboard) { continue }
            let base = ConnectedMouse(id: location, name: Self.property(pointer, kIOHIDProductKey) ?? "",
                                      manufacturer: Self.property(pointer, kIOHIDManufacturerKey),
                                      transport: Self.transport(of: pointer), vendorID: vendorID)
            let found = mice.filter { $0.id.hasPrefix(location + "#") }
            list += found.isEmpty ? [base] : found
        }
        if list != mice { mice = list }
        publishSmoothScrolling()
    }

    /// Tells the event tap which mouse glides: a wheel event names the HID service that sent it,
    /// which sits below the mouse's device in the I/O Registry. Mice behind one receiver share
    /// its services, so the first of them with smooth scrolling on decides for all.
    func publishSmoothScrolling() {
        let stored = Dictionary(storedSettings().map { ($0.deviceKey, $0) }, uniquingKeysWith: { first, _ in first })
        var bySender: [UInt64: SmoothScrollingSettings] = [:]
        for (location, interfaces) in devices {
            let located = mice.filter { $0.id == location || $0.id.hasPrefix(location + "#") }
            guard let settings = located.lazy.compactMap({ stored[$0.deviceKey]?.smoothScrollingSettings }).first else { continue }
            for sender in interfaces.flatMap(Self.serviceIDs) { bySender[sender] = settings }
        }
        smoothScrollingChanged(bySender)
    }

    /// Finds the HID++ mice at a location: the device itself, or each paired receiver slot.
    private func probe(_ location: String) {
        guard let session = sessions[location] else { return }
        let io = session.io
        let stored = Dictionary(storedSettings().map { ($0.deviceKey, $0) }, uniquingKeysWith: { first, _ in first })
        let base = mice.first { $0.id == location || $0.id.hasPrefix(location + "#") }
        let vendorID = base?.vendorID ?? 0x046D
        let writable = canWrite(vendorID, false)
        let writableGaming = canWrite(vendorID, true)
        let fallbackName = base?.name ?? ""
        session.queue.async { [weak self] in
            var found: [LogitechDevice] = []
            var states: [(UInt8?, LogitechDeviceState)] = []
            if let direct = LogitechDevice(io: io, slot: nil) {
                found = [direct]
            } else if ReceiverNotifications.enable(on: io) != .silent {
                // A receiver: it now reports devices that connect again, and its slots are asked.
                found = (1...6).compactMap { LogitechDevice(io: io, slot: $0) }
            }
            for mouse in found {
                var state = mouse.read()
                let key = MouseHardwareSettings.deviceKey(vendorID: vendorID, name: state.name ?? fallbackName)
                if state.hasOnboardProfiles ? writableGaming : writable, let saved = stored[key] { state = mouse.apply(saved) }
                states.append((mouse.slot, state))
            }
            Task { @MainActor in self?.probed(location, io: io, found: found, states: states) }
        }
    }

    private func probed(_ location: String, io: HIDReportDevice, found logitech: [LogitechDevice],
                        states: [(UInt8?, LogitechDeviceState)]) {
        guard let session = sessions[location], session.io === io else { return }
        // A device that went to sleep does not answer; it keeps its place, its last battery reading
        // and its card until the receiver reports it again or the receiver goes away.
        let answered = Set(logitech.map(\.slot))
        session.mice = logitech + session.mice.filter { !answered.contains($0.slot) }
        session.probed = true
        listen(to: io, at: location, mice: logitech, states: states)
        let freshKeyboards = states.filter { $0.1.isKeyboard }.map { slot, state in
            ConnectedAccessory(id: "\(location)#\(slot.map(String.init) ?? "direct")", name: state.name ?? "",
                               kind: .keyboard, vendorID: 0x046D)
        }
        let answeredIDs = Set(states.map { "\(location)#\($0.0.map(String.init) ?? "direct")" })
        keyboards[location] = freshKeyboards + (keyboards[location] ?? []).filter { !answeredIDs.contains($0.id) }
        let fresh = states.compactMap { slot, state in
            state.batteryPercentage.map {
                DeviceBattery(id: "\(location)#\(slot.map(String.init) ?? "direct")", name: state.name ?? "",
                              kind: state.isKeyboard ? .keyboard : .mouse, percentage: $0, isCharging: state.batteryCharging,
                              vendorID: 0x046D)
            }
        }
        let freshIDs = Set(fresh.map(\.id))
        logitechBatteries[location] = fresh + (logitechBatteries[location] ?? []).filter { !freshIDs.contains($0.id) }
        publishBatteries()
        guard let pointer = devices[location]?.first(where: Self.isMouse) else { return }
        let vendorID = Self.property(pointer, kIOHIDVendorIDKey) as Int? ?? 0
        let name = Self.property(pointer, kIOHIDProductKey) ?? ""
        let found = states.filter { !$0.1.isKeyboard }.map { slot, state in
            ConnectedMouse(id: "\(location)#\(slot.map(String.init) ?? "direct")", name: state.name ?? name,
                           manufacturer: Self.property(pointer, kIOHIDManufacturerKey),
                           transport: slot == nil ? Self.transport(of: pointer) : .receiver, vendorID: vendorID,
                           hardware: state.hasSettings ? state : nil)
        }
        let foundIDs = Set(found.map(\.id))
        let asleep = mice.filter { $0.id.hasPrefix(location + "#") && !foundIDs.contains($0.id) }
        var list = mice.filter { $0.id != location && !$0.id.hasPrefix(location + "#") }
        list += found.isEmpty && asleep.isEmpty && !states.contains(where: { $0.1.isKeyboard })
            ? [ConnectedMouse(id: location, name: name, manufacturer: Self.property(pointer, kIOHIDManufacturerKey),
                              transport: Self.transport(of: pointer), vendorID: vendorID)]
            : found + asleep
        list.sort { $0.id < $1.id }
        if list != mice { mice = list }
        publishSmoothScrolling()
    }

    /// Reads the charge of every device again: Logitech devices over HID++, others from macOS.
    func refreshBatteries() {
        for (location, session) in sessions where session.probed {
            let devices = session.mice
            session.queue.async { [weak self] in
                let charges = devices.map { (slot: $0.slot, battery: $0.readBattery()) }
                Task { @MainActor in self?.updateBatteries(at: location, charges: charges) }
            }
        }
        publishBatteries()
    }

    private func updateBatteries(at location: String, charges: [(slot: UInt8?, battery: (percentage: Int?, charging: Bool))]) {
        guard var known = logitechBatteries[location] else { return }
        for charge in charges {
            let id = "\(location)#\(charge.slot.map(String.init) ?? "direct")"
            guard let index = known.firstIndex(where: { $0.id == id }), let percentage = charge.battery.percentage else { continue }
            known[index].percentage = percentage
            known[index].isCharging = charge.battery.charging
        }
        logitechBatteries[location] = known
        publishBatteries()
    }

    private func publishBatteries() {
        let logitech = logitechBatteries.sorted { $0.key < $1.key }.flatMap(\.value)
        let names = Set(logitech.map(\.name))
        let list = logitech + Self.systemBatteries().filter { !names.contains($0.name) }
        if list != batteries { batteries = list }
    }

    /// Devices whose charge macOS itself reports (Magic Mouse, Keyboard and Trackpad, and other
    /// Bluetooth devices handled by Apple's device management service).
    private nonisolated static func systemBatteries() -> [DeviceBattery] {
        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("AppleDeviceManagementHIDEventService"),
                                           &iterator) == KERN_SUCCESS else { return [] }
        defer { IOObjectRelease(iterator) }
        var list: [DeviceBattery] = []
        while case let service = IOIteratorNext(iterator), service != 0 {
            defer { IOObjectRelease(service) }
            func value<T>(_ key: String) -> T? {
                IORegistryEntryCreateCFProperty(service, key as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? T
            }
            guard let percentage: Int = value("BatteryPercent"), let name: String = value("Product") else { continue }
            var entry: UInt64 = 0
            IORegistryEntryGetRegistryEntryID(service, &entry)
            // Classify by HID usages, never by an editable Bluetooth product name. Unknown
            // services (including headsets) do not become mice just because they have a battery.
            let page: Int = value(kIOHIDPrimaryUsagePageKey) ?? 0
            let usage: Int = value(kIOHIDPrimaryUsageKey) ?? 0
            let kind = Self.batteryKind(page: page, usage: usage) ?? .other
            // Whether it charges is not read: the flags are undocumented.
            list.append(DeviceBattery(id: "system-\(entry)", name: name, kind: kind, percentage: percentage,
                                      isCharging: false, vendorID: value(kIOHIDVendorIDKey) ?? 0))
        }
        return list
    }

    /// Routes the mouse's own reports: gesture button presses of mice that divert it, and a
    /// receiver's notice that a mouse connected again, which needs the settings and the
    /// diversion once more (both reset when a mouse reconnects).
    private func listen(to io: HIDReportDevice, at location: String, mice logitech: [LogitechDevice],
                        states: [(UInt8?, LogitechDeviceState)]) {
        let stored = Dictionary(storedSettings().map { ($0.deviceKey, $0) }, uniquingKeysWith: { first, _ in first })
        let vendorID = mice.first { $0.id.hasPrefix(location + "#") }?.vendorID ?? 0x046D
        let diverted: [(index: UInt8, feature: UInt8)] = zip(logitech, states).compactMap { mouse, entry in
            let key = MouseHardwareSettings.deviceKey(vendorID: vendorID, name: entry.1.name ?? "")
            guard entry.1.hasGestureButton, stored[key]?.usesGestureButton == true,
                  canWrite(vendorID, entry.1.hasOnboardProfiles),
                  let feature = mouse.controls?.featureIndex else { return nil }
            return (mouse.slot ?? HIDPPConstants.receiverIndex, feature)
        }
        let pressed = Mutex(false)
        let changed = gestureButtonChanged
        io.setNotificationHandler { [weak self] report in
            if report[2] == 0x41 {
                // Bit 6 of the flags is set while the link is down.
                if report.count > 4, report[4] & 0x40 == 0 {
                    Task { @MainActor in self?.probe(location) }
                }
                return
            }
            for entry in diverted where report[1] == entry.index {
                guard let controls = ReprogControls.pressedControls(in: report, featureIndex: entry.feature) else { continue }
                let down = controls.contains(ReprogControls.gestureButton)
                if pressed.withLock({ let was = $0; $0 = down; return was != down }) { changed(down) }
            }
        }
    }

    /// Gives every diverted gesture button back to its mouse, for example when Rebind quits.
    func releaseGestureButtons() {
        let done = DispatchGroup()
        for session in sessions.values {
            let devices = session.mice
            session.queue.async(group: done) {
                for mouse in devices where mouse.isGestureButtonDiverted { mouse.divertGestureButton(false) }
            }
        }
        // Quitting never waits long for a busy queue or a mouse that does not answer; a button
        // left diverted is restored by the mouse itself when it next reconnects.
        _ = done.wait(timeout: .now() + 1.5)
    }

    /// A read that got no answer (a mouse going to sleep or away) keeps the last known state;
    /// removal of the device clears it.
    private func update(id: String, state: LogitechDeviceState?) {
        guard let state, state.hasSettings, let index = mice.firstIndex(where: { $0.id == id }),
              mice[index].hardware != state else { return }
        mice[index].hardware = state
    }

    /// What a mouse should report once these settings are written.
    nonisolated static func expected(_ state: LogitechDeviceState?, after settings: MouseHardwareSettings) -> LogitechDeviceState? {
        guard var state else { return nil }
        if state.wheelMode != nil, let mode = LogitechDevice.mode(for: settings) {
            (state.wheelMode, state.smartShiftSensitivity) = LogitechDevice.settings(for: mode, sensitivity: state.smartShiftSensitivity)
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

    /// The registry IDs of a device and every service below it, such as its HID event service.
    private nonisolated static func serviceIDs(of device: IOHIDDevice) -> [UInt64] {
        let service = IOHIDDeviceGetService(device)
        var ids: [UInt64] = []
        var entry: UInt64 = 0
        if IORegistryEntryGetRegistryEntryID(service, &entry) == KERN_SUCCESS { ids.append(entry) }
        var iterator: io_iterator_t = 0
        guard IORegistryEntryCreateIterator(service, kIOServicePlane, IOOptionBits(kIORegistryIterateRecursively),
                                            &iterator) == KERN_SUCCESS else { return ids }
        defer { IOObjectRelease(iterator) }
        while case let child = IOIteratorNext(iterator), child != 0 {
            if IORegistryEntryGetRegistryEntryID(child, &entry) == KERN_SUCCESS { ids.append(entry) }
            IOObjectRelease(child)
        }
        return ids
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

    nonisolated static func allowsHIDPP(vendorID: Int, usages: [(page: Int, usage: Int)]) -> Bool {
        vendorID == 0x046D && usages.contains {
            $0.page == kHIDPage_GenericDesktop && ($0.usage == kHIDUsage_GD_Mouse || $0.usage == kHIDUsage_GD_Keyboard)
        }
    }

    nonisolated static func batteryKind(page: Int, usage: Int) -> DeviceBattery.Kind? {
        if page == kHIDPage_GenericDesktop {
            if usage == kHIDUsage_GD_Keyboard { return .keyboard }
            if usage == kHIDUsage_GD_Mouse { return .mouse }
        }
        if page == kHIDPage_Digitizer && usage == kHIDUsage_Dig_TouchPad { return .trackpad }
        return nil
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
