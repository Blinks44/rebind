import Foundation
import IOKit.hid

/// Immutable references used on one battery session's serial queue, never the main actor/tap.
/// `@unchecked Sendable` is limited to IOKit's retained CF handles; all I/O is serialized by
/// that session. No input callback is installed for keyboards or generic HID battery reads.
nonisolated final class PeripheralBatteryReader: @unchecked Sendable {
    private let inputs: [IOHIDDevice]
    private let vendorDevice: IOHIDDevice?
    private let profile: VendorBatteryProtocol.Profile?

    init(inputs: [IOHIDDevice], vendorDevice: IOHIDDevice?, profile: VendorBatteryProtocol.Profile?) {
        self.inputs = inputs
        self.vendorDevice = vendorDevice
        self.profile = profile
    }

    func read() -> PeripheralBatteryReading? {
        for device in inputs {
            if let reading = Self.registryReading(device) { return reading }
            if let reading = Self.standardHIDReading(device) { return reading }
        }
        guard let vendorDevice, let profile else { return nil }
        switch profile.family {
        case .razer(let transaction): return Self.razerReading(vendorDevice, transaction: transaction)
        case .steelSeries, .rival:
            // Selected only for a known mouse's control interface, never a keyboard interface.
            guard let request = VendorBatteryProtocol.steelSeriesRequest(for: profile.family),
                  let io = HIDReportDevice(vendorDevice, receivesHIDPP: false) else { return nil }
            defer { io.close() }
            let length = io.maxOutputReportSize ?? 0
            guard length >= request.count, length <= 512 else { return nil }
            let report = Data(request + [UInt8](repeating: 0, count: min(length, 64) - request.count))
            let matches: (Data) -> Bool = {
                VendorBatteryProtocol.steelSeriesReading([UInt8]($0), family: profile.family) != nil
            }
            var response = io.performSynchronousOutputReportRequest(report, reportID: 0, timeout: 1, matching: matches)
            if response == nil, report.count > request.count {
                // Known firmware variants accept the short command rather than a padded report.
                response = io.performSynchronousOutputReportRequest(Data(request), reportID: 0, timeout: 1, matching: matches)
            }
            guard let reply = response else { return nil }
            return VendorBatteryProtocol.steelSeriesReading([UInt8](reply), family: profile.family)
        }
    }

    private static func registryReading(_ device: IOHIDDevice) -> PeripheralBatteryReading? {
        let service = IOHIDDeviceGetService(device)
        // Driver-provided percentages, including third-party Bluetooth HID drivers. Search only
        // this known input device's subtree, never the computer's power sources or a headset.
        guard let value = IORegistryEntrySearchCFProperty(service, kIOServicePlane, "BatteryPercent" as CFString,
                                                          kCFAllocatorDefault, IOOptionBits(kIORegistryIterateRecursively)),
              CFGetTypeID(value) == CFNumberGetTypeID(),
              let percentage = value as? Int, (0...100).contains(percentage) else { return nil }
        return PeripheralBatteryReading(percentage: percentage)
    }

    private static func standardHIDReading(_ device: IOHIDDevice) -> PeripheralBatteryReading? {
        let matching: [String: Int] = [kIOHIDElementUsagePageKey: kHIDPage_GenericDeviceControls,
                                      kIOHIDElementUsageKey: kHIDUsage_GenDevControls_BatteryStrength]
        guard let elements = IOHIDDeviceCopyMatchingElements(device, matching as CFDictionary, 0) as? [IOHIDElement],
              !elements.isEmpty, IOHIDDeviceOpen(device, 0) == kIOReturnSuccess else { return nil }
        defer { IOHIDDeviceClose(device, 0) }
        for element in elements where IOHIDElementGetType(element) == kIOHIDElementTypeFeature
            || IOHIDElementGetType(element) == kIOHIDElementTypeInput_Misc {
            let storage = UnsafeMutablePointer<Unmanaged<IOHIDValue>>.allocate(capacity: 1)
            defer { storage.deallocate() }
            guard IOHIDDeviceGetValue(device, element, storage) == kIOReturnSuccess else { continue }
            let value = storage.pointee.takeUnretainedValue()
            // Input elements can contain an uninitialized cached zero before the first report.
            if IOHIDElementGetType(element) != kIOHIDElementTypeFeature, IOHIDValueGetTimeStamp(value) == 0 { continue }
            if let reading = PeripheralBatteryReading.normalized(IOHIDValueGetIntegerValue(value),
                    minimum: IOHIDElementGetLogicalMin(element), maximum: IOHIDElementGetLogicalMax(element)) {
                return reading
            }
        }
        return nil
    }

    private static func razerReading(_ device: IOHIDDevice, transaction: UInt8) -> PeripheralBatteryReading? {
        guard IOHIDDeviceOpen(device, 0) == kIOReturnSuccess else { return nil }
        defer { IOHIDDeviceClose(device, 0) }
        func query(charging: Bool) -> UInt8? {
            let request = VendorBatteryProtocol.razerRequest(transaction: transaction, charging: charging)
            let sent = request.withUnsafeBufferPointer { bytes in
                guard let base = bytes.baseAddress else { return kIOReturnBadArgument }
                return IOHIDDeviceSetReport(device, kIOHIDReportTypeFeature, 0, base, bytes.count)
            }
            guard sent == kIOReturnSuccess else { return nil }
            // The firmware processes the read request between SET_REPORT and GET_REPORT.
            // This delay and synchronous IOKit calls run only on this device's utility queue.
            Thread.sleep(forTimeInterval: 0.1)
            var response = [UInt8](repeating: 0, count: 90)
            var count = response.count
            let received = response.withUnsafeMutableBufferPointer { bytes in
                guard let base = bytes.baseAddress else { return kIOReturnBadArgument }
                return IOHIDDeviceGetReport(device, kIOHIDReportTypeFeature, 0, base, &count)
            }
            guard received == kIOReturnSuccess, count == 90 else { return nil }
            return VendorBatteryProtocol.razerValue(response, transaction: transaction, charging: charging)
        }
        guard let level = query(charging: false) else { return nil }
        return PeripheralBatteryReading(percentage: Int(level) * 100 / 255, isCharging: query(charging: true) == 1)
    }

    /// The USB interface number lives on the USB ancestor, rather than a stable IOHID key.
    static func interfaceNumber(_ device: IOHIDDevice) -> Int? {
        IORegistryEntrySearchCFProperty(IOHIDDeviceGetService(device), kIOServicePlane, "bInterfaceNumber" as CFString,
            kCFAllocatorDefault, IOOptionBits(kIORegistryIterateRecursively | kIORegistryIterateParents))
            as? Int
    }
}
