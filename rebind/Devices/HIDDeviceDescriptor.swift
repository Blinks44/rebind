import CoreHID
import IOKit.hid
import Foundation

nonisolated enum HIDDeviceDescriptor {
    @concurrent static func read(_ reference: HIDDeviceClient.DeviceReference) async -> HIDDeviceInfo {
        guard let client = HIDDeviceClient(deviceReference: reference) else { return HIDDeviceInfo(id: reference.deviceID) }
        let primary = await client.primaryUsage
        let usages = await client.deviceUsages
        // On the inventoried host CoreHID returned no individual elements;
        // registry metadata may likewise contain collection headers only.
        // Never open a device or subscribe to input just to fill this list.
        let registry = registryCapabilities(id: reference.deviceID)
        let inputElements = await client.elements.filter { $0.type == .input }
        let buttons: [UInt32]? = inputElements.isEmpty ? registry.buttonUsages : inputElements.compactMap {
            guard case .button(let usage) = $0.usage, let usage else { return nil }
            return UInt32(usage)
        }
        let capabilities = HIDCapabilities(buttonUsages: buttons, declaresTrackpad: registry.declaresTrackpad)
        let builtIn = await client.isBuiltIn
        let transport: HIDDeviceInfo.Transport
        switch await client.transport {
        case .usb: transport = .usb
        case .bluetooth, .bluetoothLowEnergy, .bluetoothAACP: transport = .bluetooth
        case .virtual: transport = .virtual
        default: transport = builtIn ? .builtIn : .other
        }
        return HIDDeviceInfo(
            id: reference.deviceID,
            product: HIDDeviceInfo.cleanedLabel(await client.product),
            manufacturer: HIDDeviceInfo.cleanedLabel(await client.manufacturer),
            vendorID: await client.vendorID, productID: await client.productID,
            kinds: HIDDeviceInfo.kinds(usagePairs: ([primary] + usages).map { ($0.page, $0.usage) },
                                       declaresTrackpad: capabilities.declaresTrackpad),
            transport: transport, capabilities: capabilities
        )
    }

    private static func registryCapabilities(id: UInt64) -> HIDCapabilities {
        guard let matching = IORegistryEntryIDMatching(id) else { return HIDCapabilities() }
        let service = IOServiceGetMatchingService(kIOMainPortDefault, matching)
        guard service != IO_OBJECT_NULL else { return HIDCapabilities() }
        defer { IOObjectRelease(service) }
        let property = IORegistryEntryCreateCFProperty(service, kIOHIDElementKey as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue()
        return HIDCapabilities(elementDescriptions: property as? [[String: Any]])
    }
}
