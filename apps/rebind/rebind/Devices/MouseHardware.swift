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
    let bluetoothBattery = BluetoothBatteryMonitor()
    private var logitechAccessories: [String: [ConnectedAccessory]] = [:]
    private var otherInputs: [ConnectedAccessory] = []

    var accessories: [ConnectedAccessory] {
        let listed = logitechAccessories.sorted { $0.key < $1.key }.flatMap(\.value) + otherInputs
        let known = Set(mice.map(\.deviceKey) + listed.map(\.deviceKey))
        // Devices is for input hardware; a macOS battery reading alone does not qualify
        // a headset or an unclassified accessory for a settings card.
        return listed + batteries.filter { $0.kind != .other && !known.contains($0.deviceKey) }.map {
            ConnectedAccessory(id: $0.id, name: $0.name, kind: $0.kind, vendorID: $0.vendorID)
        }
    }
    @ObservationIgnored private var logitechBatteries: [String: [DeviceBattery]] = [:]
    @ObservationIgnored private var batteryTimer: Timer?
    @ObservationIgnored private var manager: IOHIDManager?
    @ObservationIgnored private var devices: [String: [IOHIDDevice]] = [:]
    /// Open HID++ endpoints and the mice found behind each, by IOKit location.
    @ObservationIgnored private var sessions: [String: Session] = [:]
    @ObservationIgnored private var batterySessions: [String: BatterySession] = [:]
    @ObservationIgnored private var peripheralBatteries: [String: DeviceBattery] = [:]
    @ObservationIgnored private var rebuildScheduled = false
    /// The stored settings, written to a mouse of the same model whenever it connects.
    @ObservationIgnored var storedSettings: () -> [MouseHardwareSettings] = { [] }
    /// Whether Rebind may write to mice of a vendor now (no companion app controls them).
    /// Arguments: vendor, and whether it is a gaming mouse with onboard profiles.
    @ObservationIgnored var canWrite: (Int, Bool) -> Bool = { _, _ in true }
    /// Receives presses (true) and releases of a diverted gesture button, on the HID report thread.
    @ObservationIgnored var gestureButtonChanged: @Sendable (Bool) -> Void = { _ in }
    @ObservationIgnored private let gestureButtonInput = GestureButtonInput()
    /// Receives smooth scrolling per HID service that sends a mouse's wheel events.
    @ObservationIgnored var smoothScrollingChanged: ([UInt64: SmoothScrollingSettings]) -> Void = { _ in }

    /// One opened HID++ endpoint (a device or a receiver) and the devices found behind it. Its
    /// requests wait for answers, so each endpoint has its own serial queue: a sleeping keyboard
    /// never delays a mouse on another receiver.
    private final class Session {
        let id = UUID()
        let io: HIDReportDevice
        let queue: DispatchQueue
        let writeAccess = DeviceWriteAccess()
        let gestureOwnership = GestureButtonOwnership()
        var mice: [LogitechDevice] = []
        var probed = false
        var isProbing = false
        var needsProbe = false
        var isReadingBattery = false
        var applying: Set<String> = []
        var pendingSettings: [String: MouseHardwareSettings] = [:]
        init(io: HIDReportDevice, location: String) {
            self.io = io
            queue = DispatchQueue(label: "Rebind HID++ \(location)", qos: .utility)
        }
    }

    /// One in-flight read per physical location; late results are rejected by session identity.
    private final class BatterySession {
        let reader: PeripheralBatteryReader
        let queue: DispatchQueue
        let device: ConnectedAccessory
        let interfaceIDs: Set<UInt64>
        var isReading = false
        init(reader: PeripheralBatteryReader, device: ConnectedAccessory, interfaceIDs: Set<UInt64>) {
            self.reader = reader
            self.device = device
            self.interfaceIDs = interfaceIDs
            queue = DispatchQueue(label: "Rebind battery \(device.id)", qos: .utility)
        }
    }

    func start() {
        guard manager == nil else { return }
        // Discovery does not open/schedule every matched interface (including vendor-only
        // headset interfaces). Each positively identified reader manages its own device.
        let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOHIDManagerOptions.independentDevices.rawValue)
        let matching: [[String: Int]] = [
            [kIOHIDDeviceUsagePageKey: kHIDPage_GenericDesktop, kIOHIDDeviceUsageKey: kHIDUsage_GD_Mouse],
            [kIOHIDDeviceUsagePageKey: kHIDPage_GenericDesktop, kIOHIDDeviceUsageKey: kHIDUsage_GD_Keyboard],
            [kIOHIDDeviceUsagePageKey: kHIDPage_Digitizer, kIOHIDDeviceUsageKey: kHIDUsage_Dig_TouchPad],
            [kIOHIDVendorIDKey: 0x046D, kIOHIDDeviceUsagePageKey: 0xFF00],
            [kIOHIDVendorIDKey: 0x046D, kIOHIDDeviceUsagePageKey: 0xFF43],
            [kIOHIDVendorIDKey: 0x1532],
            [kIOHIDVendorIDKey: 0x1038]
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
        bluetoothBattery.changed = { [weak self] in self?.publishBatteries() }
        bluetoothBattery.startIfAuthorized()
        // Charges change slowly; a few reads every five minutes are enough for the Menu Bar.
        batteryTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.refreshBatteries() }
        }
        publishBatteries()
    }

    func stop() {
        gestureButtonInput.removeAll(changed: gestureButtonChanged)
        bluetoothBattery.stop()
        guard let manager else { return }
        batteryTimer?.invalidate()
        batteryTimer = nil
        sessions.values.forEach { $0.writeAccess.update(standard: false, gaming: false) }
        releaseGestureButtons()
        IOHIDManagerUnscheduleFromRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
        IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        self.manager = nil
        sessions.values.forEach { $0.io.close() }
        sessions = [:]
        devices = [:]
        mice = []
        logitechAccessories = [:]
        otherInputs = []
        logitechBatteries = [:]
        batterySessions = [:]
        peripheralBatteries = [:]
        batteries = []
    }

    /// Reads every supported mouse again and writes its stored settings: when Devices opens,
    /// after a configuration restore and when a companion app quits. A mouse behind a receiver
    /// that wakes from sleep is not noticed; it keeps its own settings anyway.
    func refresh() {
        guard manager != nil else { return }
        for (location, session) in sessions {
            session.writeAccess.invalidate()
            session.pendingSettings = [:]
            probe(location)
        }
        refreshBatteries()
    }

    /// Writes new settings to every connected mouse of this model.
    func apply(_ settings: MouseHardwareSettings) {
        for (location, session) in sessions where session.probed {
            for mouse in mice where mouse.deviceKey == settings.deviceKey && mouse.hardware != nil
                && mouse.id.hasPrefix(location + "#")
                && canWrite(mouse.vendorID, mouse.hardware?.hasOnboardProfiles ?? false) {
                apply(settings, to: mouse, at: location, session: session)
            }
        }
    }

    private func apply(_ settings: MouseHardwareSettings, to mouse: ConnectedMouse, at location: String, session: Session) {
        let gaming = mouse.hardware?.hasOnboardProfiles ?? false
        session.writeAccess.update(standard: canWrite(mouse.vendorID, false), gaming: canWrite(mouse.vendorID, true))
        guard session.writeAccess.allows(gaming: gaming), let found = session.mice.first(where: { $0.slot == Self.slot(of: mouse.id) }) else { return }
        update(id: mouse.id, state: Self.expected(mouse.hardware, after: settings))
        guard session.applying.insert(mouse.id).inserted else {
            session.pendingSettings[mouse.id] = settings
            return
        }
        let io = session.io, access = session.writeAccess
        let revision = access.revision
        session.queue.async { [weak self] in
            let state = found.apply(settings, canWrite: { access.allows(gaming: gaming, revision: revision) })
            Task { @MainActor in
                guard let self, let current = self.sessions[location], current.io === io else { return }
                current.applying.remove(mouse.id)
                if let pending = current.pendingSettings.removeValue(forKey: mouse.id),
                   let mouse = self.mice.first(where: { $0.id == mouse.id }) {
                    self.apply(pending, to: mouse, at: location, session: current)
                } else if access.revision == revision { self.update(id: mouse.id, state: state) }
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
            logitechAccessories[location] = nil
            batterySessions[location] = nil
            peripheralBatteries[location] = nil
            bluetoothBattery.refresh()
            publishBatteries()
            if let session = sessions.removeValue(forKey: location) {
                gestureButtonInput.remove(connection: session.id, changed: gestureButtonChanged)
                session.writeAccess.update(standard: false, gaming: false)
                session.io.close()
            }
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
        var accessories: [ConnectedAccessory] = []
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
            let inputs = interfaces.filter { Self.inputKind(of: $0) != nil }
            if let input = pointer ?? inputs.first, let kind = Self.inputKind(of: input) {
                let identity = ConnectedAccessory(id: location, name: Self.property(input, kIOHIDProductKey) ?? "",
                                                   kind: kind, vendorID: vendorID)
                let interfaceIDs = Set(interfaces.map { device -> UInt64 in
                    var id: UInt64 = 0
                    IORegistryEntryGetRegistryEntryID(IOHIDDeviceGetService(device), &id)
                    return id
                })
                if batterySessions[location]?.interfaceIDs != interfaceIDs {
                    let productID: Int = Self.property(input, kIOHIDProductIDKey) ?? 0
                    let isUSB = (Self.property(input, kIOHIDTransportKey) as String?) == kIOHIDTransportUSBValue
                    let profile = kind == .mouse && isUSB
                        ? VendorBatteryProtocol.profile(vendorID: vendorID, productID: productID) : nil
                    let endpoint = profile.flatMap { profile in interfaces.first {
                        let usages = Self.usagePairs($0)
                        // No raw input callback is ever installed on a keyboard control interface.
                        return profile.acceptsInterface(number: PeripheralBatteryReader.interfaceNumber($0), usages: usages,
                            featureSize: Self.property($0, kIOHIDMaxFeatureReportSizeKey) ?? 0,
                            outputSize: Self.property($0, kIOHIDMaxOutputReportSizeKey) ?? 0)
                    } }
                    batterySessions[location] = BatterySession(reader: PeripheralBatteryReader(inputs: inputs,
                        vendorDevice: endpoint, profile: profile), device: identity, interfaceIDs: interfaceIDs)
                    readPeripheralBattery(at: location)
                }
                // Receiver keyboard interfaces can represent the mouse's macros. A named HID++
                // device replaces that placeholder; only genuine non-mouse inputs need a card.
                if pointer == nil, sessions[location]?.mice.isEmpty != false { accessories.append(identity) }
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
        if accessories != otherInputs { otherInputs = accessories }
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
        session.writeAccess.update(standard: canWrite(0x046D, false), gaming: canWrite(0x046D, true))
        guard !session.isProbing else { session.needsProbe = true; return }
        session.isProbing = true
        let io = session.io
        let gestureOwnership = session.gestureOwnership
        let stored = Dictionary(storedSettings().map { ($0.deviceKey, $0) }, uniquingKeysWith: { first, _ in first })
        let base = mice.first { $0.id == location || $0.id.hasPrefix(location + "#") }
        let vendorID = base?.vendorID ?? 0x046D
        let access = session.writeAccess
        let revision = access.revision
        let fallbackName = base?.name ?? ""
        session.queue.async { [weak self] in
            var found: [LogitechDevice] = []
            var states: [(UInt8?, LogitechDeviceState)] = []
            if let direct = LogitechDevice(io: io, slot: nil, gestureOwnership: gestureOwnership) {
                found = [direct]
            } else if ReceiverNotifications.enable(on: io) != .silent {
                // A receiver: it now reports devices that connect again, and its slots are asked.
                found = (1...6).compactMap { LogitechDevice(io: io, slot: $0, gestureOwnership: gestureOwnership) }
            }
            for mouse in found {
                var state = mouse.read()
                let key = MouseHardwareSettings.deviceKey(vendorID: vendorID, name: state.name ?? fallbackName)
                if let saved = stored[key] {
                    let gaming = state.hasOnboardProfiles
                    state = mouse.apply(saved, canWrite: { access.allows(gaming: gaming, revision: revision) })
                }
                states.append((mouse.slot, state))
            }
            Task { @MainActor in self?.probed(location, io: io, found: found, states: states) }
        }
    }

    private func probed(_ location: String, io: HIDReportDevice, found logitech: [LogitechDevice],
                        states: [(UInt8?, LogitechDeviceState)]) {
        guard let session = sessions[location], session.io === io else { return }
        session.isProbing = false
        defer {
            if session.needsProbe { session.needsProbe = false; probe(location) }
        }
        // A device that went to sleep does not answer; it keeps its place, its last battery reading
        // and its card until the receiver reports it again or the receiver goes away.
        let answered = Set(logitech.map(\.slot))
        session.mice = logitech + session.mice.filter { !answered.contains($0.slot) }
        session.probed = true
        listen(to: io, at: location, mice: logitech, states: states)
        let batteryOnly = devices[location]?.contains(where: Self.isMouse) != true
        let freshAccessories = states.filter { $0.1.isKeyboard || batteryOnly }.map { slot, state in
            ConnectedAccessory(id: "\(location)#\(slot.map(String.init) ?? "direct")", name: state.name ?? "",
                               kind: state.isKeyboard ? .keyboard : .mouse, vendorID: 0x046D)
        }
        let answeredIDs = Set(states.map { "\(location)#\($0.0.map(String.init) ?? "direct")" })
        logitechAccessories[location] = freshAccessories + (logitechAccessories[location] ?? []).filter { !answeredIDs.contains($0.id) }
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
        rebuild()
    }

    /// Reads the charge of every device again: Logitech devices over HID++, others from macOS.
    func refreshBatteries() {
        guard manager != nil else { return }
        bluetoothBattery.startIfAuthorized()
        bluetoothBattery.refresh()
        for location in batterySessions.keys { readPeripheralBattery(at: location) }
        for (location, session) in sessions where session.probed && !session.isReadingBattery {
            session.isReadingBattery = true
            let devices = session.mice
            let io = session.io
            session.queue.async { [weak self] in
                let charges = devices.map { (slot: $0.slot, battery: $0.readBattery()) }
                Task { @MainActor in self?.updateBatteries(at: location, io: io, charges: charges) }
            }
        }
        publishBatteries()
    }

    private func readPeripheralBattery(at location: String) {
        guard let session = batterySessions[location], !session.isReading else { return }
        session.isReading = true
        let reader = session.reader
        let device = session.device
        session.queue.async { [weak self, weak session] in
            let reading = reader.read()
            Task { @MainActor in
                guard let self, let session, self.batterySessions[location] === session else { return }
                session.isReading = false
                if let reading {
                    self.peripheralBatteries[location] = DeviceBattery(id: device.id, name: device.name, kind: device.kind,
                        percentage: reading.percentage, isCharging: reading.isCharging, vendorID: device.vendorID)
                    self.publishBatteries()
                }
            }
        }
    }

    private func updateBatteries(at location: String, io: HIDReportDevice,
                                 charges: [(slot: UInt8?, battery: (percentage: Int?, charging: Bool))]) {
        guard sessions[location]?.io === io else { return }
        sessions[location]?.isReadingBattery = false
        let inputs = mice.map { ConnectedAccessory(id: $0.id, name: $0.name, kind: .mouse, vendorID: $0.vendorID) }
            + (logitechAccessories[location] ?? [])
        let readings = charges.map { charge in
            (id: "\(location)#\(charge.slot.map(String.init) ?? "direct")",
             percentage: charge.battery.percentage, charging: charge.battery.charging)
        }
        logitechBatteries[location] = Self.refreshedBatteries(logitechBatteries[location] ?? [], inputs: inputs, readings: readings)
        publishBatteries()
    }

    nonisolated static func refreshedBatteries(_ previous: [DeviceBattery], inputs: [ConnectedAccessory],
                                              readings: [(id: String, percentage: Int?, charging: Bool)]) -> [DeviceBattery] {
        var known = previous
        for reading in readings {
            guard let percentage = reading.percentage, (0...100).contains(percentage),
                  let input = inputs.first(where: { $0.id == reading.id }) else { continue }
            let battery = DeviceBattery(id: input.id, name: input.name, kind: input.kind,
                                        percentage: percentage, isCharging: reading.charging, vendorID: input.vendorID)
            if let index = known.firstIndex(where: { $0.id == input.id }) { known[index] = battery }
            else { known.append(battery) }
        }
        return known
    }

    private func publishBatteries() {
        let logitech = logitechBatteries.sorted { $0.key < $1.key }.flatMap(\.value)
        let peripheral = peripheralBatteries.sorted { $0.key < $1.key }.filter { location, _ in
            !(logitechBatteries[location]?.isEmpty == false)
        }.map(\.value)
        let preferred = logitech + peripheral
        let inputs = mice.map { ConnectedAccessory(id: $0.id, name: $0.name, kind: .mouse, vendorID: $0.vendorID) }
            + logitechAccessories.sorted { $0.key < $1.key }.flatMap(\.value) + otherInputs
        let bluetooth = Self.bluetoothBatteries(bluetoothBattery.batteries, matching: inputs)
        let preferredIDs = Set(preferred.map(\.id))
        let combined = preferred + bluetooth.filter { !preferredIDs.contains($0.id) }
        let names = Set(combined.map(\.name))
        let list = combined + Self.systemBatteries().filter { !names.contains($0.name) }
        if list != batteries { batteries = list }
    }

    /// Match only a unique known input identity. Never attribute one BLE reading to two
    /// identically named devices; the existing alias key and card ID stay unchanged.
    nonisolated static func bluetoothBatteries(_ batteries: [DeviceBattery], matching inputs: [ConnectedAccessory]) -> [DeviceBattery] {
        batteries.compactMap { battery in
            guard battery.kind != .other else { return nil }
            let matches = inputs.filter { $0.name == battery.name && $0.kind == battery.kind }
            if matches.count > 1 { return nil }
            guard let input = matches.first else { return battery }
            let matched = DeviceBattery(id: input.id, name: input.name, kind: input.kind, percentage: battery.percentage,
                                    isCharging: battery.isCharging, vendorID: input.vendorID)
            return matched
        }
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
            guard let percentage: Int = value("BatteryPercent"), (0...100).contains(percentage),
                  let name: String = value("Product") else { continue }
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
        let changed = gestureButtonChanged
        guard let session = sessions[location], session.io === io else { return }
        let input = gestureButtonInput, connection = session.id
        let generation = input.configure(connection: connection, indices: Set(diverted.map(\.index)), changed: changed)
        io.setNotificationHandler { [weak self, weak io] report in
            if ReceiverNotifications.isConnectionNotification(report) {
                // Bit 6 of the flags is set while the link is down.
                if report[4] & 0x40 == 0 {
                    Task { @MainActor in
                        guard let self, let io, self.sessions[location]?.io === io else { return }
                        self.probe(location)
                    }
                } else {
                    input.receive(connection: connection, generation: generation, index: report[1], down: false, changed: changed)
                }
                return
            }
            for entry in diverted where report[1] == entry.index {
                guard let controls = ReprogControls.pressedControls(in: report, featureIndex: entry.feature) else { continue }
                let down = controls.contains(ReprogControls.gestureButton)
                input.receive(connection: connection, generation: generation, index: entry.index, down: down, changed: changed)
            }
        }
    }

    /// Gives every diverted gesture button back to its mouse, for example when Rebind quits.
    func releaseGestureButtons() {
        let done = DispatchGroup()
        for session in sessions.values {
            let ownership = session.gestureOwnership
            session.queue.async(group: done) {
                ownership.releaseAll()
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
        if let location: Int = property(device, kIOHIDLocationIDKey), location != 0 { return String(location, radix: 16) }
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

    private nonisolated static func inputKind(of device: IOHIDDevice) -> DeviceBattery.Kind? {
        let page: Int = property(device, kIOHIDPrimaryUsagePageKey) ?? 0
        let usage: Int = property(device, kIOHIDPrimaryUsageKey) ?? 0
        return inputKind(page: page, usage: usage, usages: usagePairs(device),
                         builtIn: property(device, kIOHIDBuiltInKey) == true)
    }

    nonisolated static func inputKind(page: Int, usage: Int, usages: [(page: Int, usage: Int)],
                                     builtIn: Bool) -> DeviceBattery.Kind? {
        guard !builtIn else { return nil }
        if usages.contains(where: { $0.page == kHIDPage_Digitizer && $0.usage == kHIDUsage_Dig_TouchPad }) { return .trackpad }
        return batteryKind(page: page, usage: usage)
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
