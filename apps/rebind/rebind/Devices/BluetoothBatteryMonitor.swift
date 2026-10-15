import AppKit
@preconcurrency import CoreBluetooth
import Observation

/// Standard Battery Service on already-connected HID peripherals. Does not scan, pair,
/// read HID input reports or write characteristics. Bluetooth access starts only on demand
/// or after this app has already been authorized by the user.
@MainActor @Observable final class BluetoothBatteryMonitor: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    private(set) var authorization = CBManager.authorization
    private(set) var batteries: [DeviceBattery] = []
    @ObservationIgnored var changed: () -> Void = {}
    @ObservationIgnored private var central: CBCentralManager?
    @ObservationIgnored private var reads: [UUID: Read] = [:]
    @ObservationIgnored private var cached: [UUID: DeviceBattery] = [:]
    @ObservationIgnored private var disconnecting: Set<UUID> = []
    private static let hid = CBUUID(string: "1812")
    private static let battery = CBUUID(string: "180F")
    private static let reportMap = CBUUID(string: "2A4B")
    private static let level = CBUUID(string: "2A19")

    private final class Read {
        let peripheral: CBPeripheral
        var kind: DeviceBattery.Kind?
        var level: CBCharacteristic?
        var readingLevel = false
        var timeout: Task<Void, Never>?
        init(_ peripheral: CBPeripheral) { self.peripheral = peripheral }
    }

    func startIfAuthorized() {
        authorization = CBManager.authorization
        guard authorization == .allowedAlways, central == nil else { return }
        requestAccess()
    }

    func requestAccess() {
        authorization = CBManager.authorization
        if authorization == .denied {
            if let url = URL(string: "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Bluetooth") {
                NSWorkspace.shared.open(url)
            }
            return
        }
        guard authorization != .restricted else { return }
        if central == nil {
            // nil queue delivers all delegate calls on the main queue.
            central = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: false])
        } else { refresh() }
    }

    func stop() {
        for id in Array(reads.keys) { finish(id) }
        central?.delegate = nil
        central = nil
        disconnecting = []
        cached = [:]
        publish()
    }

    func refresh() {
        authorization = CBManager.authorization
        guard let central, central.state == .poweredOn, authorization == .allowedAlways else { return }
        let connected = central.retrieveConnectedPeripherals(withServices: [Self.hid])
        let ids = Set(connected.map(\.identifier))
        cached = cached.filter { ids.contains($0.key) }
        for id in Array(reads.keys) where !ids.contains(id) { finish(id) }
        publish()
        for peripheral in connected where reads[peripheral.identifier] == nil && !disconnecting.contains(peripheral.identifier) {
            let read = Read(peripheral)
            reads[peripheral.identifier] = read
            peripheral.delegate = self
            let id = peripheral.identifier
            read.timeout = Task { [weak self, weak read] in
                do { try await Task.sleep(for: .seconds(5)) } catch { return }
                guard let self, let read, reads[id] === read else { return }
                finish(id)
            }
            central.connect(peripheral)
        }
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        guard self.central === central else { return }
        authorization = CBManager.authorization
        if central.state == .poweredOn { refresh() }
        else {
            for id in Array(reads.keys) { finish(id) }
            cached = [:]
            disconnecting = []
            publish()
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        guard self.central === central else { return }
        guard reads[peripheral.identifier]?.peripheral === peripheral else { return }
        peripheral.discoverServices([Self.hid, Self.battery])
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: (any Error)?) {
        guard self.central === central else { return }
        disconnecting.remove(peripheral.identifier)
        finish(peripheral.identifier)
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: (any Error)?) {
        guard self.central === central else { return }
        if disconnecting.remove(peripheral.identifier) != nil { return }
        cached[peripheral.identifier] = nil
        if reads[peripheral.identifier] != nil { finish(peripheral.identifier) }
        publish()
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: (any Error)?) {
        guard error == nil, reads[peripheral.identifier] != nil,
              let hid = peripheral.services?.first(where: { $0.uuid == Self.hid }),
              let battery = peripheral.services?.first(where: { $0.uuid == Self.battery }) else {
            finish(peripheral.identifier); return
        }
        peripheral.discoverCharacteristics([Self.reportMap], for: hid)
        peripheral.discoverCharacteristics([Self.level], for: battery)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: (any Error)?) {
        guard error == nil, let read = reads[peripheral.identifier] else { finish(peripheral.identifier); return }
        if service.uuid == Self.hid {
            guard let map = service.characteristics?.first(where: { $0.uuid == Self.reportMap }) else {
                finish(peripheral.identifier); return
            }
            peripheral.readValue(for: map)
        } else if service.uuid == Self.battery {
            guard let level = service.characteristics?.first(where: { $0.uuid == Self.level }) else {
                finish(peripheral.identifier); return
            }
            read.level = level
            readLevelIfIdentified(read)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: (any Error)?) {
        guard error == nil, let read = reads[peripheral.identifier], let data = characteristic.value else {
            finish(peripheral.identifier); return
        }
        if characteristic.uuid == Self.reportMap {
            guard let kind = HIDReportMap.inputKind(data) else {
                cached[peripheral.identifier] = nil
                finish(peripheral.identifier); publish(); return
            }
            read.kind = kind
            readLevelIfIdentified(read)
        } else if characteristic.uuid == Self.level {
            guard let kind = read.kind, data.count == 1, let level = data.first, level <= 100,
                  let name = peripheral.name, !name.isEmpty else { finish(peripheral.identifier); return }
            cached[peripheral.identifier] = DeviceBattery(id: "ble-\(peripheral.identifier)", name: name, kind: kind,
                percentage: Int(level), isCharging: false)
            finish(peripheral.identifier)
            publish()
        }
    }

    private func readLevelIfIdentified(_ read: Read) {
        guard read.kind != nil, let level = read.level, !read.readingLevel else { return }
        read.readingLevel = true
        read.peripheral.readValue(for: level)
    }

    private func finish(_ id: UUID) {
        guard let read = reads.removeValue(forKey: id) else { return }
        read.timeout?.cancel()
        read.peripheral.delegate = nil
        // Removes only this app's GATT connection; other clients (including macOS HID) retain theirs.
        if let central, read.peripheral.state != .disconnected {
            disconnecting.insert(id)
            central.cancelPeripheralConnection(read.peripheral)
        }
    }

    private func publish() {
        let list = cached.sorted { $0.key.uuidString < $1.key.uuidString }.map(\.value)
        guard list != batteries else { return }
        batteries = list
        changed()
    }
}
