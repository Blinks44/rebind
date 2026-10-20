import AppKit
import SwiftUI
import XCTest
@testable import rebind

/// Isolated native fixtures never start the input worker or load user configuration.
@MainActor final class MouseLayoutTests: XCTestCase {
    func testMouseDetailFitsFullMainWindowInAllLanguages() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: "RebindMouseLayout-\(UUID())")
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = ConfigurationStore(url: directory.appending(path: "configuration.json"))
        for hasRules in [false, true] {
            var configuration = Configuration(bindings: hasRules ? fixtures : [])
            configuration.hasCompletedSetup = true
            try store.save(configuration)
            for hasAccess in [false, true] {
                let model = AppModel(store: store,
                    readPermissions: { InputPermissions(accessibility: hasAccess, posting: hasAccess) })
                for language in AppLanguage.allCases.map(\.rawValue) {
                    for appearance in [ColorScheme.light, .dark] {
                        let controller = NSHostingController(rootView: ContentView(model: model,
                            initialDestination: .input(.allMice))
                            .environment(\.locale, Locale(identifier: language)).preferredColorScheme(appearance))
                        let window = NSWindow(contentViewController: controller)
                        window.styleMask.insert(.fullSizeContentView)
                        window.titleVisibility = .hidden
                        window.titlebarAppearsTransparent = true
                        window.isReleasedWhenClosed = false
                        window.appearance = NSAppearance(named: appearance == .light ? .aqua : .darkAqua)
                        defer { window.close() }
                        try await Task.sleep(for: .milliseconds(100))
                        for size in [NSSize(width: 880, height: 600), NSSize(width: 1040, height: 640)] {
                            window.setFrame(NSRect(origin: window.frame.origin, size: size), display: false)
                            try await Task.sleep(for: .milliseconds(100))
                            controller.view.layoutSubtreeIfNeeded()
                            let context = "\(language), \(appearance), rules=\(hasRules), access=\(hasAccess), \(size)"
                            XCTAssertEqual(controller.view.bounds.size.width, size.width, accuracy: 1, context)
                            XCTAssertEqual(controller.view.bounds.size.height, size.height, accuracy: 1, context)
                            try MainWindowLayoutAssertions.verifyRegions(in: controller.view, context: context)
                            if language == "ru" && size.width == 1040 && hasRules && hasAccess {
                                try attach(controller.view, name: "mouse-list-\(appearance)")
                            }
                        }
                    }
                }
            }
        }
    }

    func testLocalizedMouseEditorsFitCompactNativeWindows() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: "RebindMouseEditor-\(UUID())")
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = ConfigurationStore(url: directory.appending(path: "configuration.json"))
        for language in AppLanguage.allCases.map(\.rawValue) {
            for appearance in [ColorScheme.light, .dark] {
                for existing in fixtures.map(Optional.some) + [nil] {
                    var configuration = Configuration(bindings: existing.map { [$0] } ?? [])
                    configuration.hasCompletedSetup = true
                    try store.save(configuration)
                    let model = AppModel(store: store,
                        readPermissions: { InputPermissions(accessibility: true, posting: true) })
                    let controller = NSHostingController(rootView: BindingEditor(model: model, scope: .allMice,
                        existing: existing).environment(\.locale, Locale(identifier: language))
                        .preferredColorScheme(appearance))
                    let window = NSWindow(contentViewController: controller)
                    window.isReleasedWhenClosed = false
                    window.appearance = NSAppearance(named: appearance == .light ? .aqua : .darkAqua)
                    defer { window.close() }
                    for height in [600.0, 760.0] {
                        window.setContentSize(NSSize(width: 520, height: height))
                        try await Task.sleep(for: .milliseconds(100))
                        controller.view.layoutSubtreeIfNeeded()
                        let context = "\(language), \(appearance), \(String(describing: existing?.trigger)), \(height)"
                        XCTAssertEqual(controller.view.bounds.height, height, accuracy: 1, context)
                        XCTAssertEqual(controller.view.bounds.width, 520, accuracy: 1, context)
                        if language == "de" && height == 600 && existing?.activation == .hold {
                            try attach(controller.view, name: "mouse-hold-de-\(appearance)")
                        }
                    }
                }
            }
        }
    }

    private var fixtures: [rebind.Binding] {
        let action = RebindAction.shortcut(KeyboardShortcut(keyCode: 13, modifiers: .command))
        return [
            rebind.Binding(scope: .allMice, trigger: .mouseButton(3), modifiers: .control, action: action),
            rebind.Binding(scope: .allMice, trigger: .mouseButton(8), modifiers: [], action: .media(.playPause),
                activation: .hold, holdDurationMilliseconds: 1500),
            rebind.Binding(scope: .allMice, trigger: .scroll(.up), modifiers: .control, action: .system(.volumeUp)),
            rebind.Binding(scope: .allMice, trigger: .mouseGesture(button: 99, direction: .right), modifiers: [],
                action: action, isEnabled: false)
        ]
    }

    private func attach(_ view: NSView, name: String) throws {
        let bitmap = try XCTUnwrap(view.bitmapImageRepForCachingDisplay(in: view.bounds))
        view.cacheDisplay(in: view.bounds, to: bitmap)
        let png = try XCTUnwrap(bitmap.representation(using: .png, properties: [:]))
        let attachment = XCTAttachment(data: png, uniformTypeIdentifier: "public.png")
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
