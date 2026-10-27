import AppKit
import SwiftUI
import XCTest
@testable import rebind

/// Full-window fixtures use an initial inventory; no discovery, global input or user data.
@MainActor final class KeyboardLightingLayoutTests: XCTestCase {
    func testLightingFitsFullDevicesWindowInAllLanguagesAndStates() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: "RebindLightingLayout-\(UUID())")
        defer { try? FileManager.default.removeItem(at: directory) }
        let device = ConnectedAccessory(id: "fixture#1", name: "G915 TKL", kind: .keyboard, vendorID: 0x046D)
        for mode in 0...4 {
            var configuration = Configuration()
            configuration.hasCompletedSetup = true
            configuration.keyboardLighting = [KeyboardLightingSettings(deviceKey: device.deviceKey, isEnabled: mode != 1,
                brightness: 50, color: 0x2080FF, lowBattery: mode == 2 ? .blinkingRed : .keepColor)]
            let store = ConfigurationStore(url: directory.appending(path: "\(mode)/configuration.json"))
            try store.save(configuration)
            let hardware = MouseHardware(accessories: [device],
                lighting: [device.id: KeyboardLightingState(brightness: mode == 1 ? 0 : 50, supportsBlinking: true)],
                batteries: [DeviceBattery(id: device.id, name: device.name, kind: .keyboard,
                                          percentage: mode == 2 ? 8 : 48, isCharging: false, vendorID: device.vendorID)],
                lightingErrors: mode == 3 ? [device.id] : [])
            let companion = CompanionAppMonitor(executablePaths: { [] },
                initiallyRunning: mode == 4 ? CompanionApp.known.filter { $0.name == "Logitech G HUB" } : [])
            let model = AppModel(store: store, readPermissions: { InputPermissions() },
                                 companionApps: companion, mouseHardware: hardware)
            for language in ["en", "ru", "de", "fr", "es", "zh-Hans"] {
                for appearance in [ColorScheme.light, .dark] {
                    let controller = NSHostingController(rootView: ContentView(model: model, initialDestination: .settings(.devices))
                        .environment(\.locale, Locale(identifier: language)).preferredColorScheme(appearance))
                    let window = NSWindow(contentViewController: controller)
                    window.styleMask.insert(.fullSizeContentView)
                    window.titleVisibility = .hidden
                    window.titlebarAppearsTransparent = true
                    window.appearance = NSAppearance(named: appearance == .dark ? .darkAqua : .aqua)
                    window.isReleasedWhenClosed = false
                    defer { window.close() }
                    for size in [NSSize(width: 880, height: 600), NSSize(width: 1080, height: 800)] {
                        window.setFrame(NSRect(origin: .zero, size: size), display: false)
                        controller.view.layoutSubtreeIfNeeded()
                        try await Task.sleep(for: .milliseconds(60))
                        controller.view.layoutSubtreeIfNeeded()
                        let context = "Lighting \(mode) \(language) \(appearance) \(size)"
                        XCTAssertEqual(controller.view.bounds.width, size.width, accuracy: 1, context)
                        XCTAssertEqual(controller.view.bounds.height, size.height, accuracy: 1, context)
                        try MainWindowLayoutAssertions.verifyRegions(in: controller.view, context: context)
                        if size.width == 1080, language == "en" || language == "ru" {
                            let bitmap = try XCTUnwrap(controller.view.bitmapImageRepForCachingDisplay(in: controller.view.bounds))
                            controller.view.cacheDisplay(in: controller.view.bounds, to: bitmap)
                            let png = try XCTUnwrap(bitmap.representation(using: .png, properties: [:]))
                            try png.write(to: URL(filePath: "/private/tmp/rebind-lighting-\(mode)-\(language)-\(appearance).png"))
                        }
                    }
                }
            }
        }
    }
}
