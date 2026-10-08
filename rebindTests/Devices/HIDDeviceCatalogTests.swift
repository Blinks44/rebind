import Testing
@testable import rebind

struct HIDDeviceCatalogTests {
    @Test func identicalModelsRemainSeparateLiveInterfaces() {
        var catalog = HIDDeviceCatalog()
        catalog.connect(HIDDeviceInfo(id: 22, product: "USB Receiver", vendorID: 1133, productID: 50489))
        catalog.connect(HIDDeviceInfo(id: 11, product: "USB Receiver", vendorID: 1133, productID: 50489))
        #expect(catalog.devices.map(\.id) == [11, 22])
        catalog.disconnect(11)
        #expect(catalog.devices.map(\.id) == [22])
    }

    @Test func repeatedMatchUpdatesMetadataRatherThanDuplicatingRows() {
        var catalog = HIDDeviceCatalog()
        catalog.connect(HIDDeviceInfo(id: 1))
        catalog.connect(HIDDeviceInfo(id: 1, product: "Mouse", capabilities: HIDCapabilities(buttonUsages: [1, 8])))
        #expect(catalog.devices.count == 1)
        #expect(catalog.devices.first?.product == "Mouse")
        #expect(catalog.devices.first?.capabilities.buttonUsages == [1, 8])
    }

    @Test func reconnectWithNewIdDoesNotReuseAnOldPhysicalIdentity() {
        var catalog = HIDDeviceCatalog()
        catalog.connect(HIDDeviceInfo(id: 1, product: "Mouse"))
        catalog.disconnect(1)
        catalog.connect(HIDDeviceInfo(id: 2, product: "Mouse"))
        catalog.disconnect(1) // A late/duplicate old removal must not erase the new interface.
        #expect(catalog.devices.map(\.id) == [2])
    }

    @Test func clearingOnFailureCannotLeaveStaleConnectedDevices() {
        var catalog = HIDDeviceCatalog()
        catalog.connect(HIDDeviceInfo(id: 1))
        let snapshot = catalog.devices
        catalog.clear()
        #expect(catalog.devices.isEmpty)
        #expect(snapshot.map(\.id) == [1])
    }

    @Test func kindsUseHidUsagesAndPreserveCompositeInterfaces() {
        #expect(HIDDeviceInfo.kinds(usagePairs: [(1, 6), (1, 2)], declaresTrackpad: false) == [.keyboard, .mouse])
        #expect(HIDDeviceInfo.kinds(usagePairs: [(13, 5)], declaresTrackpad: false) == [.trackpad])
        #expect(HIDDeviceInfo.kinds(usagePairs: [(1, 2)], declaresTrackpad: true) == [.mouse, .trackpad])
        #expect(HIDDeviceInfo.kinds(usagePairs: [(65280, 1), (1, nil)], declaresTrackpad: false).isEmpty)
    }

    @Test func peripheralNamesAreBoundedAndDoNotContainControlCharacters() {
        #expect(HIDDeviceInfo.cleanedLabel("\nUSB\u{0} Receiver\t") == "USB Receiver")
        #expect(HIDDeviceInfo.cleanedLabel(" \n\t ") == nil)
        #expect(HIDDeviceInfo.cleanedLabel(nil) == nil)
        #expect(HIDDeviceInfo.cleanedLabel(String(repeating: "x", count: 1000))?.count == 200)
        #expect(HIDDeviceInfo.cleanedLabel("Logitech G603") == "Logitech G603")
    }
}
