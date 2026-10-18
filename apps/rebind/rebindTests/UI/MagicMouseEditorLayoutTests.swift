import AppKit
import SwiftUI
import Synchronization
import XCTest
@testable import rebind

/// Isolated fixtures never start capture, execute actions or read the real configuration.
@MainActor final class MagicMouseEditorLayoutTests: XCTestCase {
    func testTapPresetsAndWarningsFitAllLanguages() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: "MagicMouseLayout-\(UUID())")
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = ConfigurationStore(url: directory.appending(path: "configuration.json"))
        for preset in MagicMousePreset.allCases {
            let rule = rebind.Binding(scope: .magicMouse, trigger: preset.trigger, modifiers: .option,
                                      action: .shortcut(.init(keyCode: 13, modifiers: .command)))
            try store.save(Configuration(bindings: [rule]))
            let model = AppModel(store: store, readPermissions: { InputPermissions(accessibility: true, posting: true) })
            for language in AppLanguage.allCases {
                for scheme in [ColorScheme.light, .dark] {
                    let controller = NSHostingController(rootView: BindingEditor(model: model, scope: .magicMouse, existing: rule)
                        .environment(\.locale, Locale(identifier: language.rawValue)).preferredColorScheme(scheme))
                    let window = NSWindow(contentViewController: controller)
                    window.isReleasedWhenClosed = false
                    defer { window.close() }
                    for height in [488.0, 640.0] {
                        window.setContentSize(NSSize(width: 520, height: height))
                        try await Task.sleep(for: .milliseconds(80))
                        controller.view.layoutSubtreeIfNeeded()
                        let scroll = try XCTUnwrap(findScroll(controller.view))
                        let bounds = scroll.convert(scroll.bounds, to: controller.view)
                        XCTAssertEqual(controller.view.bounds.width, 520, accuracy: 1)
                        XCTAssertEqual(controller.view.bounds.height, height, accuracy: 1)
                        XCTAssertGreaterThan(bounds.height, 0)
                        XCTAssertGreaterThanOrEqual(bounds.minY, -1)
                        XCTAssertLessThanOrEqual(bounds.maxY, height + 1)
                        XCTAssertLessThanOrEqual(scroll.documentView?.frame.width ?? 0, scroll.contentView.bounds.width + 1)
                    }
                }
            }
        }
    }

    func testCategoryStatesFitTheMainWindow() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: "MagicMouseMain-\(UUID())")
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = ConfigurationStore(url: directory.appending(path: "configuration.json"))
        var configuration = Configuration(isEnabled: true, bindings: [
            rebind.Binding(scope: .magicMouse, trigger: .magicMouseTap(fingers: 1), modifiers: [], action: .doNothing)
        ])
        configuration.hasCompletedSetup = true
        try store.save(configuration)
        let model = AppModel(store: store, readPermissions: { InputPermissions(accessibility: true, posting: true) })
        model.mailbox.configure(configuration)
        for status in [TrackpadCaptureStatus.active, .unavailable, .failed] {
            model.mailbox.state.withLock { $0.status = .active; $0.magicMouseStatus = status }
            model.refresh()
            for language in AppLanguage.allCases {
                let controller = NSHostingController(rootView: ContentView(model: model, initialDestination: .input(.magicMouse))
                    .environment(\.locale, Locale(identifier: language.rawValue)))
                let window = NSWindow(contentViewController: controller)
                window.styleMask.insert(.fullSizeContentView)
                window.titleVisibility = .hidden
                window.titlebarAppearsTransparent = true
                window.isReleasedWhenClosed = false
                defer { window.close() }
                window.setFrame(NSRect(x: 0, y: 0, width: 880, height: 600), display: false)
                try await Task.sleep(for: .milliseconds(100))
                controller.view.layoutSubtreeIfNeeded()
                try MainWindowLayoutAssertions.verifyRegions(in: controller.view, context: "magic mouse \(status) \(language)")
            }
        }
    }

    private func findScroll(_ view: NSView) -> NSScrollView? {
        if let scroll = view as? NSScrollView { return scroll }
        return view.subviews.lazy.compactMap(findScroll).first
    }
}
