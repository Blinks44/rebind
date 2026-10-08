import CoreHID
import Observation

@MainActor @Observable final class HIDDeviceDiscovery {
    enum Status { case stopped, monitoring, failed }
    private var catalog = HIDDeviceCatalog()
    var devices: [HIDDeviceInfo] { catalog.devices }
    private(set) var status: Status = .stopped
    @ObservationIgnored private var task: Task<Void, Never>?
    @ObservationIgnored private var generation: UInt64 = 0

    func start() {
        guard task == nil else { return }
        generation &+= 1
        let generation = generation
        status = .monitoring
        // Owned application-lifetime task: discovery must outlive the window.
        // No HID input subscription, report requests, device seize or event tap.
        task = Task { [weak self] in
            let manager = HIDDeviceManager()
            let criteria: [HIDDeviceManager.DeviceMatchingCriteria] = [
                .init(deviceUsages: [.genericDesktop(.keyboard)]),
                .init(deviceUsages: [.genericDesktop(.keypad)]),
                .init(deviceUsages: [.genericDesktop(.mouse)]),
                .init(deviceUsages: [.genericDesktop(.pointer)]),
                .init(deviceUsages: [.digitizers(.touchPad)])
            ]
            do {
                for try await notification in await manager.monitorNotifications(matchingCriteria: criteria) {
                    try Task.checkCancellation()
                    switch notification {
                    case .deviceMatched(let reference):
                        let device = await HIDDeviceDescriptor.read(reference)
                        try Task.checkCancellation()
                        self?.receive(device, generation: generation)
                    case .deviceRemoved(let reference):
                        self?.remove(reference.deviceID, generation: generation)
                    @unknown default: break
                    }
                }
                if !Task.isCancelled { self?.failed(generation: generation) }
            } catch {
                if !Task.isCancelled { self?.failed(generation: generation) }
            }
        }
    }

    func stop() {
        generation &+= 1
        task?.cancel()
        task = nil
        catalog.clear()
        status = .stopped
    }

    func restart() { stop(); start() }

    private func receive(_ device: HIDDeviceInfo, generation: UInt64) {
        guard generation == self.generation else { return }
        catalog.connect(device)
    }

    private func remove(_ id: UInt64, generation: UInt64) {
        guard generation == self.generation else { return }
        catalog.disconnect(id)
    }

    private func failed(generation: UInt64) {
        guard generation == self.generation else { return }
        catalog.clear() // A failed stream cannot establish that old entries are connected.
        status = .failed
        task = nil
    }

    deinit { task?.cancel() }
}
