import Foundation
import Testing
@testable import rebind

struct DeviceNamesTests {
    private let original = "G915 TKL LIGHTSPEED Wireless RGB Mechanical Gaming Keyboard"
    private var key: String { MouseHardwareSettings.deviceKey(vendorID: 0x046D, name: original) }

    @Test func localNamesSurviveFullBackupWithoutChangingHardwareIdentity() throws {
        var configuration = Configuration(isEnabled: true)
        configuration.mouseHardware = [MouseHardwareSettings(deviceKey: key, dpi: 1450)]
        let hardware = configuration.mouseHardware
        try configuration.renameDevice(key: key, original: original, name: "  G915  ")
        let restored = try ConfigurationBackup(data: ConfigurationBackup(configuration: configuration).encoded()).configuration
        let reconnected = DeviceBattery(id: "different-port#1", name: original, kind: .keyboard,
                                        percentage: 48, isCharging: false, vendorID: 0x046D)
        #expect(restored.deviceName(for: reconnected.deviceKey, original: reconnected.name) == "G915")
        #expect(restored.mouseHardware == hardware && restored.isEnabled)
        #expect(try restored.exportingProfile(restored.selectedProfileID).deviceNames.isEmpty)
        #expect(restored.deviceName(for: "another-model", original: "Other") == "Other")
    }

    @Test(arguments: ["", "  \n  ", "G915 TKL LIGHTSPEED Wireless RGB Mechanical Gaming Keyboard"])
    func clearingOrUsingOriginalNameRemovesOverride(_ name: String) throws {
        var configuration = Configuration()
        try configuration.renameDevice(key: key, original: original, name: "G915")
        try configuration.renameDevice(key: key, original: original, name: name)
        #expect(configuration.deviceNames.isEmpty)
        #expect(configuration.deviceName(for: key, original: original) == original)
    }

    @Test(arguments: [String(repeating: "x", count: 61), "Keyboard\nMouse", "G\u{0}915"])
    func invalidNamesLeaveConfigurationUnchanged(_ name: String) throws {
        var configuration = Configuration()
        let before = configuration
        #expect(throws: ConfigurationError.invalid) { try configuration.renameDevice(key: key, original: original, name: name) }
        #expect(configuration == before)
    }

    @Test func unicodeNamesAndSchema40Migration() throws {
        var configuration = Configuration()
        try configuration.renameDevice(key: key, original: original, name: "Клавиатура 键盘 ⌨️")
        #expect(try ConfigurationBackup(data: ConfigurationBackup(configuration: configuration).encoded()).configuration == configuration)
        configuration.schemaVersion = 40
        #expect(throws: ConfigurationError.invalid) { try configuration.migrated() }
        configuration.deviceNames = [:]
        let data = try JSONEncoder().encode(configuration)
        let migrated = try JSONDecoder().decode(Configuration.self, from: data).migrated()
        #expect(migrated.schemaVersion == Configuration.currentSchemaVersion && migrated.deviceNames.isEmpty)
    }
}

struct DeviceClassificationTests {
    @Test func theConnectedG435IsNotAHIDPPInputDevice() {
        // Agent-observed descriptors: vendor FF00/1 plus Consumer 0C/1, no GD mouse/keyboard.
        #expect(MouseHardware.allowsHIDPP(vendorID: 0x046D, usages: [(0xFF00, 1), (0x0C, 1)]) == false)
        #expect(MouseHardware.allowsHIDPP(vendorID: 0x046D, usages: [(0xFF00, 1)]) == false)
        #expect(MouseHardware.allowsHIDPP(vendorID: 0x046D, usages: []) == false)
    }

    @Test func receiverInputInterfacesQualifyButOtherVendorsDoNot() {
        #expect(MouseHardware.allowsHIDPP(vendorID: 0x046D, usages: [(1, 2), (1, 6), (0xFF00, 1)]))
        #expect(MouseHardware.allowsHIDPP(vendorID: 0x046D, usages: [(1, 6), (0xFF00, 1)]))
        #expect(MouseHardware.allowsHIDPP(vendorID: 0x1234, usages: [(1, 2), (0xFF00, 1)]) == false)
    }

    @Test func batteryKindUsesHIDUsagesInsteadOfProductName() {
        #expect(MouseHardware.batteryKind(page: 1, usage: 6) == .keyboard)
        #expect(MouseHardware.batteryKind(page: 1, usage: 2) == .mouse)
        #expect(MouseHardware.batteryKind(page: 0x0D, usage: 5) == .trackpad)
        #expect(MouseHardware.batteryKind(page: 0x0C, usage: 1) == nil)
        #expect(MouseHardware.batteryKind(page: 0xFF00, usage: 1) == nil)
    }
}

@MainActor struct DeviceNameSaveTests {
    @Test func savingANameDoesNotCancelPendingInputOrWriteHardwareSettings() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: "RebindNameSave-\(UUID())")
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = ConfigurationStore(url: directory.appending(path: "configuration.json"))
        var configuration = Configuration(isEnabled: true)
        configuration.mouseHardware = [MouseHardwareSettings(deviceKey: "046d:G603", dpi: 1450)]
        try store.save(configuration)
        let model = AppModel(store: store, readPermissions: { InputPermissions() })
        let shortcut = KeyboardShortcut(keyCode: 0, modifiers: .command)
        model.mailbox.state.withLock { $0.status = .active; $0.pending = [.shortcut(shortcut)] }
        #expect(model.renameDevice(key: "046d:G603", original: "G603", name: "Mouse"))
        #expect(model.mailbox.state.withLock { $0.status } == .active)
        #expect(model.mailbox.state.withLock { $0.pending } == [.shortcut(shortcut)])
        #expect(model.configuration.mouseHardware == configuration.mouseHardware)
        #expect(try store.load().deviceNames == ["046d:G603": "Mouse"])
    }

    @Test func protectedStorageRefusesARename() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: "RebindNameLocked-\(UUID())")
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appending(path: "configuration.json")
        let original = Data("invalid protected original".utf8)
        try original.write(to: url)
        let model = AppModel(store: ConfigurationStore(url: url), readPermissions: { InputPermissions() })
        #expect(model.renameDevice(key: "046d:G915", original: "G915", name: "Keyboard") == false)
        #expect(try Data(contentsOf: url) == original)
    }
}
