nonisolated struct HIDDeviceCatalog: Sendable {
    private var connected: [UInt64: HIDDeviceInfo] = [:]

    var devices: [HIDDeviceInfo] { connected.values.sorted { $0.id < $1.id } }

    mutating func connect(_ device: HIDDeviceInfo) { connected[device.id] = device }
    mutating func disconnect(_ id: UInt64) { connected.removeValue(forKey: id) }
    mutating func clear() { connected.removeAll() }
}
