import AppKit
import SwiftUI
import XCTest
@testable import rebind

/// Isolated views only: no live discovery, input capture or user configuration.
@MainActor final class DeviceNamesLayoutTests: XCTestCase {
    func testKeyboardIdentityAndNamingSheetFitAllLanguages() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: "RebindDeviceLayout-\(UUID())")
        defer { try? FileManager.default.removeItem(at: directory) }
        let model = AppModel(store: ConfigurationStore(url: directory.appending(path: "configuration.json")),
                             loadConfiguration: false, readPermissions: { InputPermissions() })
        let original = "G915 TKL LIGHTSPEED Wireless RGB Mechanical Gaming Keyboard"
        for language in ["en", "ru", "de", "fr", "es", "zh-Hans"] {
            for appearance in [ColorScheme.light, .dark] {
                let identity = DeviceIdentityView(name: "G915", original: original, subtitle: "", kind: .keyboard,
                    battery: DeviceBattery(id: "fixture", name: original, kind: .keyboard, percentage: 48,
                                           isCharging: false), rename: {})
                let views = [AnyView(Card { identity }.padding(20).background { ThemeCanvas() }),
                             AnyView(DeviceNameEditor(model: model, deviceKey: "046d:G915", original: original))]
                for (index, view) in views.enumerated() {
                    let controller = NSHostingController(rootView: view
                        .environment(\.locale, Locale(identifier: language)).preferredColorScheme(appearance))
                    let window = NSWindow(contentViewController: controller)
                    window.appearance = NSAppearance(named: appearance == .dark ? .darkAqua : .aqua)
                    window.isReleasedWhenClosed = false
                    defer { window.close() }
                    let width: CGFloat = index == 0 ? 560 : 440
                    window.setContentSize(NSSize(width: width, height: controller.view.fittingSize.height))
                    controller.view.layoutSubtreeIfNeeded()
                    try await Task.sleep(for: .milliseconds(30))
                    controller.view.layoutSubtreeIfNeeded()
                    XCTAssertEqual(controller.view.bounds.width, width, accuracy: 1)
                    XCTAssertLessThanOrEqual(controller.sizeThatFits(in: NSSize(width: width, height: 1000)).width, width + 1)
                    if language == "ru" && appearance == .light || language == "de" && appearance == .dark {
                        let bitmap = try XCTUnwrap(controller.view.bitmapImageRepForCachingDisplay(in: controller.view.bounds))
                        controller.view.cacheDisplay(in: controller.view.bounds, to: bitmap)
                        let png = try XCTUnwrap(bitmap.representation(using: .png, properties: [:]))
                        try png.write(to: URL(filePath: "/private/tmp/rebind-device-\(index)-\(language).png"))
                    }
                }
            }
        }
    }
}
