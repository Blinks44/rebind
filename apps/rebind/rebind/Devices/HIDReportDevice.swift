import Foundation
import HIDPP
import IOKit.hid
import Synchronization

/// The thread whose run loop receives input reports of opened HID++ devices. Requests
/// wait on `MouseHardware.queue` instead, so neither this thread nor the main thread
/// ever blocks, and the main run loop does not wake for every report of a moving mouse.
nonisolated enum HIDReportThread {
    /// Only thread-safe CFRunLoop calls (scheduling, perform-block, wake-up) touch it from
    /// other threads, which is why the reference itself may be shared.
    nonisolated(unsafe) static let runLoop: CFRunLoop = {
        let ready = DispatchSemaphore(value: 0)
        let loop = Mutex<CFRunLoop?>(nil)
        let thread = Thread {
            loop.withLock { $0 = CFRunLoopGetCurrent() }
            // A port keeps the run loop alive while no device is scheduled on it.
            RunLoop.current.add(NSMachPort(), forMode: .default)
            ready.signal()
            while true { RunLoop.current.run() }
        }
        thread.name = "Rebind HID reports"
        thread.qualityOfService = .utility
        thread.start()
        ready.wait()
        return loop.withLock { $0! }
    }()
}

/// One opened IOHIDDevice as HID++ report I/O. Opening without seizing leaves the
/// device working for macOS; Rebind only adds its own output reports.
///
/// `@unchecked Sendable`: the device reference and sizes never change, replies pass
/// through a Mutex, and the report buffer and callback registration belong to
/// `HIDReportThread` (set up before scheduling, torn down on that thread).
nonisolated final class HIDReportDevice: HIDPPDeviceIO, @unchecked Sendable {
    /// HID++ reports received while a request waits; the requester picks its reply.
    private struct Inbox {
        var arrived: DispatchSemaphore?
        var reports: [Data] = []
    }

    let maxOutputReportSize: Int?
    private let device: IOHIDDevice
    private let buffer: UnsafeMutablePointer<UInt8>
    private let bufferLength: Int
    private let inbox = Mutex(Inbox())
    /// Called on the report thread with each unsolicited HID++ report (software ID 0), such as a
    /// diverted button press. It must stay short: it runs between the mouse's reports.
    private let notifications = Mutex<(@Sendable ([UInt8]) -> Void)?>(nil)
    private let closed = Mutex(false)

    init?(_ device: IOHIDDevice) {
        guard IOHIDDeviceOpen(device, IOOptionBits(kIOHIDOptionsTypeNone)) == kIOReturnSuccess else { return nil }
        self.device = device
        maxOutputReportSize = IOHIDDeviceGetProperty(device, kIOHIDMaxOutputReportSizeKey as CFString) as? Int
        let input = IOHIDDeviceGetProperty(device, kIOHIDMaxInputReportSizeKey as CFString) as? Int ?? 0
        bufferLength = max(input, HIDPPConstants.longReportLength)
        buffer = .allocate(capacity: bufferLength)
        let context = Unmanaged.passRetained(self).toOpaque()
        IOHIDDeviceRegisterInputReportCallback(device, buffer, bufferLength, { context, _, _, _, _, report, length in
            guard let context else { return }
            Unmanaged<HIDReportDevice>.fromOpaque(context).takeUnretainedValue().receive(report, length: length)
        }, context)
        IOHIDDeviceScheduleWithRunLoop(device, HIDReportThread.runLoop, CFRunLoopMode.defaultMode.rawValue)
    }

    /// Ends report delivery on the report thread, then releases the device and this object.
    func close() {
        guard closed.withLock({ let was = $0; $0 = true; return !was }) else { return }
        inbox.withLock { $0.arrived?.signal() }
        notifications.withLock { $0 = nil }
        let runLoop = HIDReportThread.runLoop
        CFRunLoopPerformBlock(runLoop, CFRunLoopMode.defaultMode.rawValue) { [self] in
            IOHIDDeviceRegisterInputReportCallback(device, buffer, bufferLength, nil, nil)
            IOHIDDeviceUnscheduleFromRunLoop(device, runLoop, CFRunLoopMode.defaultMode.rawValue)
            IOHIDDeviceClose(device, IOOptionBits(kIOHIDOptionsTypeNone))
            buffer.deallocate()
            Unmanaged.passUnretained(self).release()
        }
        CFRunLoopWakeUp(runLoop)
    }

    private func receive(_ report: UnsafeMutablePointer<UInt8>, length: CFIndex) {
        // Every pointer report of the mouse arrives here too; only HID++ replies matter.
        guard length >= HIDPPConstants.shortReportLength,
              report[0] == HIDPPConstants.shortReportID || report[0] == HIDPPConstants.longReportID else { return }
        // Software ID 0 marks a HID++ 2.0 event; sub-ID 0x41 a receiver's device connection.
        if report[3] & 0x0F == 0 || report[2] == 0x41, let notify = notifications.withLock({ $0 }) {
            notify(Array(UnsafeBufferPointer(start: report, count: length)))
            return
        }
        let data = Data(bytes: report, count: length)
        inbox.withLock {
            guard let arrived = $0.arrived, $0.reports.count < 64 else { return }
            $0.reports.append(data)
            arrived.signal()
        }
    }

    func setNotificationHandler(_ handler: (@Sendable ([UInt8]) -> Void)?) {
        notifications.withLock { $0 = handler }
    }

    func performSynchronousOutputReportRequest(_ report: Data, timeout: TimeInterval,
                                               matching: @escaping (Data) -> Bool) -> Data? {
        guard !report.isEmpty, !closed.withLock({ $0 }) else { return nil }
        let arrived = DispatchSemaphore(value: 0)
        inbox.withLock { $0 = Inbox(arrived: arrived) }
        defer { inbox.withLock { $0 = Inbox() } }
        let result = report.withUnsafeBytes { bytes -> IOReturn in
            guard let base = bytes.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return kIOReturnBadArgument }
            return IOHIDDeviceSetReport(device, kIOHIDReportTypeOutput, CFIndex(report[0]), base, report.count)
        }
        guard result == kIOReturnSuccess else { return nil }
        let deadline = DispatchTime.now() + timeout
        // Notifications and other replies can arrive first; wait until the matching one.
        while !closed.withLock({ $0 }) {
            let reports = inbox.withLock { inbox in
                defer { inbox.reports = [] }
                return inbox.reports
            }
            if let reply = reports.first(where: matching) { return reply }
            guard arrived.wait(timeout: deadline) == .success else { return nil }
        }
        return nil
    }
}
