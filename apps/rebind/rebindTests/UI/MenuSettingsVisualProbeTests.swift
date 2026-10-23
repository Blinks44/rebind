import AppKit
import Testing
@testable import rebind

@MainActor @Suite(.serialized) struct MenuSettingsVisualProbeTests {
    @Test func renderActualMenuWithBatteryAndPointerSpeed() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: "RebindMenuProbe-\(UUID())")
        defer { try? FileManager.default.removeItem(at: directory) }
        let model = AppModel(store: ConfigurationStore(url: directory.appending(path: "configuration.json")),
                             loadConfiguration: false, readPermissions: { InputPermissions() })
        let controller = MenuBarController(model: model)
        let menu = NSMenu()
        menu.autoenablesItems = false
        controller.menuNeedsUpdate(menu)
        let insertion = menu.items.count - 3
        menu.insertItem(.separator(), at: insertion)
        menu.insertItem(.sectionHeader(title: "Battery"), at: insertion + 1)
        let battery = DeviceBattery(id: "fixture", name: "MX Master 3S", kind: .mouse, percentage: 20, isCharging: false)
        let row = try #require(MenuBarController.batteryItems([(battery: battery, name: battery.name)], language: .en).first)
        menu.insertItem(row, at: insertion + 2)
        menu.insertItem(.separator(), at: insertion + 3)
        menu.insertItem(.sectionHeader(title: "Pointer speed"), at: insertion + 4)
        let speed = NSMenuItem()
        speed.view = MenuPointerSpeedView(name: "MX Master 3S", dpi: 1000, values: [400, 1000, 1600], enabled: true,
                                         accessibilityLabel: "Pointer speed", valueText: { "\($0) DPI" }, commit: { _ in })
        menu.insertItem(speed, at: insertion + 5)
        let settings = try #require(menu.items.first { $0.keyEquivalent == "," })
        #expect(settings.image != nil)
        if #available(macOS 27, *) { #expect(settings.preferredImageVisibility == .visible) }
    }
}
