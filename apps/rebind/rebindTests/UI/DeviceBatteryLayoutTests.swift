import AppKit
import SwiftUI
import XCTest
@testable import rebind

/// Full-window fixture. Does not start discovery, CoreBluetooth, input capture or real settings.
@MainActor final class DeviceBatteryLayoutTests: XCTestCase {
    func testDevicesWithBluetoothAccessControlFitsAllLanguages() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: "RebindBatteryLayout-\(UUID())")
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = ConfigurationStore(url: directory.appending(path: "configuration.json"))
        var configuration = Configuration()
        configuration.hasCompletedSetup = true
        try store.save(configuration)
        let model = AppModel(store: store, readPermissions: { InputPermissions() },
            loginItem: LoginItemModel(service: LoginItemServiceStub(status: .off)))
        for language in ["en", "ru", "de", "fr", "es", "zh-Hans"] {
            for appearance in [ColorScheme.light, .dark] {
                let controller = NSHostingController(rootView: ContentView(model: model, initialDestination: .devices)
                    .environment(\.locale, Locale(identifier: language)).preferredColorScheme(appearance))
                let window = NSWindow(contentViewController: controller)
                window.styleMask.insert(.fullSizeContentView)
                window.titleVisibility = .hidden
                window.titlebarAppearsTransparent = true
                window.appearance = NSAppearance(named: appearance == .dark ? .darkAqua : .aqua)
                window.isReleasedWhenClosed = false
                defer { window.close() }
                window.setFrame(NSRect(x: 0, y: 0, width: 880, height: 600), display: false)
                controller.view.layoutSubtreeIfNeeded()
                try await Task.sleep(for: .milliseconds(60))
                controller.view.layoutSubtreeIfNeeded()
                XCTAssertEqual(controller.view.bounds.width, 880, accuracy: 1)
                XCTAssertEqual(controller.view.bounds.height, 600, accuracy: 1)
                try MainWindowLayoutAssertions.verifyRegions(in: controller.view, context: "Devices \(language) \(appearance)")
                XCTAssertTrue(model.mouseHardware.bluetoothBattery.batteries.isEmpty)
                if language == "ru" && appearance == .light || language == "de" && appearance == .dark {
                    let bitmap = try XCTUnwrap(controller.view.bitmapImageRepForCachingDisplay(in: controller.view.bounds))
                    controller.view.cacheDisplay(in: controller.view.bounds, to: bitmap)
                    let png = try XCTUnwrap(bitmap.representation(using: .png, properties: [:]))
                    try png.write(to: URL(filePath: "/private/tmp/rebind-multivendor-settings-\(language).png"))
                }
            }
        }
    }
}
