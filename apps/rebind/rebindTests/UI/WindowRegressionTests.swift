import AppKit
import SwiftUI
import Testing
@testable import rebind

/// Disposable native windows: no capture, hardware discovery or production configuration.
@MainActor @Suite(.serialized) struct WindowRegressionTests {
    @Test func geometrySurvivesWindowRecreationWithoutSceneRestoration() async throws {
        let name = "RebindWindowTest-\(UUID())"
        defer { NSWindow.removeFrame(usingName: name) }
        func makeWindow() -> NSWindow {
            let controller = NSHostingController(rootView: Color.clear.frame(minWidth: 880, minHeight: 600)
                .background { MainWindowPersistence(frameName: name) })
            let window = NSWindow(contentViewController: controller)
            window.isReleasedWhenClosed = false
            window.setFrame(NSRect(x: 100, y: 100, width: 1080, height: 720), display: false)
            return window
        }
        let first = makeWindow()
        try await Task.sleep(for: .milliseconds(150))
        first.setFrame(NSRect(x: 100, y: 100, width: 1190, height: 790), display: false)
        try await Task.sleep(for: .milliseconds(150))
        let expected = first.frame.size
        first.close()
        let second = makeWindow()
        defer { second.close() }
        try await Task.sleep(for: .milliseconds(150))
        #expect(abs(second.frame.width - expected.width) < 1)
        #expect(abs(second.frame.height - expected.height) < 1)
    }

    @Test func settingsRequestIsConsumedInTheMainWindowBeforeAndAfterAttachment() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: "RebindRouteTest-\(UUID())")
        defer { try? FileManager.default.removeItem(at: directory) }
        let model = AppModel(store: ConfigurationStore(url: directory.appending(path: "configuration.json")),
                             loadConfiguration: false, readPermissions: { InputPermissions() })
        model.requestedSettingsSection = .input
        let controller = NSHostingController(rootView: ContentView(model: model, persistsWindowSelection: false))
        let window = NSWindow(contentViewController: controller)
        window.isReleasedWhenClosed = false
        defer { window.close() }
        window.setContentSize(NSSize(width: 1080, height: 720))
        try await Task.sleep(for: .milliseconds(150))
        #expect(model.requestedSettingsSection == nil)
        #expect(model.settingsSection == .input)
        // Devices is requested with the window already alive, including repeated menu actions.
        for _ in 0..<2 {
            model.requestedSettingsSection = .devices
            try await Task.sleep(for: .milliseconds(100))
            #expect(model.requestedSettingsSection == nil)
            #expect(model.settingsSection == .devices)
        }
    }

    @Test func longRuleListKeepsItsViewportBelowTheProfileRowWhenScrolled() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: "RebindScrollTest-\(UUID())")
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = ConfigurationStore(url: directory.appending(path: "configuration.json"))
        var configuration = Configuration(isEnabled: true, bindings: (3..<23).map {
            rebind.Binding(scope: .allMice, trigger: .mouseButton(UInt32($0)), modifiers: [], action: .doNothing)
        })
        configuration.hasCompletedSetup = true
        try store.save(configuration)
        let model = AppModel(store: store, readPermissions: { InputPermissions(accessibility: true, posting: true) })
        model.mailbox.configure(configuration)
        model.mailbox.state.withLock { $0.status = .active }
        model.refresh()
        let controller = NSHostingController(rootView: BindingsView(model: model, scope: .allMice,
            add: {}, edit: { _ in }, duplicate: { _ in }, delete: { _ in }, manageProfiles: {}, openPermissions: {})
            .environment(\.locale, Locale(identifier: "en")))
        let window = NSWindow(contentViewController: controller)
        window.isReleasedWhenClosed = false
        defer { window.close() }
        window.setContentSize(NSSize(width: 840, height: 650))
        try await Task.sleep(for: .milliseconds(150))
        controller.view.layoutSubtreeIfNeeded()
        let scroll = try #require(descendants(controller.view).compactMap { $0 as? NSScrollView }.first)
        let document = try #require(scroll.documentView)
        let initial = scroll.convert(scroll.bounds, to: controller.view)
        let top = controller.view.isFlipped ? initial.minY : controller.view.bounds.maxY - initial.maxY
        // Header/profile ends around 180 pt; the viewport must retain the source's 24 pt gap.
        #expect(top >= 204)
        #expect(top < 216)
        let bottom = controller.view.isFlipped ? controller.view.bounds.maxY - initial.maxY : initial.minY
        #expect(abs(bottom - 8) < 1)
        #expect(document.bounds.height > scroll.contentView.bounds.height)
        document.scroll(NSPoint(x: 0, y: document.bounds.height - scroll.contentView.bounds.height))
        scroll.reflectScrolledClipView(scroll.contentView)
        try await Task.sleep(for: .milliseconds(100))
        #expect(scroll.contentView.bounds.origin.y > 0)
        #expect(scroll.convert(scroll.bounds, to: controller.view) == initial)
        let bitmap = try #require(controller.view.bitmapImageRepForCachingDisplay(in: controller.view.bounds))
        controller.view.cacheDisplay(in: controller.view.bounds, to: bitmap)
        let png = try #require(bitmap.representation(using: .png, properties: [:]))
        try png.write(to: URL(filePath: "/private/tmp/rebind-rule-gap.png"))
    }

    @Test func ruleCardFitsItsRowsOrAlignsWithSidebarInTheFullWindow() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: "RebindCardTest-\(UUID())")
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = ConfigurationStore(url: directory.appending(path: "configuration.json"))
        for count in [2, 20] {
            var configuration = Configuration(isEnabled: true, bindings: (3..<(3 + count)).map {
                rebind.Binding(scope: .allMice, trigger: .mouseButton(UInt32($0)), modifiers: [], action: .doNothing)
            })
            configuration.hasCompletedSetup = true
            try store.save(configuration)
            let model = AppModel(store: store, readPermissions: { InputPermissions(accessibility: true, posting: true) })
            model.mailbox.configure(configuration)
            model.mailbox.state.withLock { $0.status = .active }
            model.refresh()
            for (language, appearance) in [("en", ColorScheme.light), ("ru", .dark)] {
                let controller = NSHostingController(rootView: ContentView(model: model,
                    initialDestination: .input(.allMice), persistsWindowSelection: false)
                    .environment(\.locale, Locale(identifier: language)).preferredColorScheme(appearance))
                let window = NSWindow(contentViewController: controller)
                window.styleMask.insert(.fullSizeContentView)
                window.titleVisibility = .hidden
                window.titlebarAppearsTransparent = true
                window.isReleasedWhenClosed = false
                defer { window.close() }
                for size in [NSSize(width: 880, height: 600), NSSize(width: 1080, height: 720)] {
                    window.setFrame(NSRect(origin: window.frame.origin, size: size), display: false)
                    try await Task.sleep(for: .milliseconds(150))
                    controller.view.layoutSubtreeIfNeeded()
                    let scroll = try #require(descendants(controller.view).compactMap { $0 as? NSScrollView }.first)
                    let document = try #require(scroll.documentView)
                    let frame = scroll.convert(scroll.bounds, to: controller.view)
                    if count == 2 {
                        #expect(abs(frame.height - 2 * Theme.rowHeight) < 1)
                        #expect(document.bounds.height <= scroll.contentView.bounds.height + 1)
                    } else {
                        let bottom = controller.view.isFlipped ? controller.view.bounds.maxY - frame.maxY : frame.minY
                        #expect(abs(bottom - 8) < 1)
                        document.scroll(NSPoint(x: 0, y: document.bounds.height - scroll.contentView.bounds.height))
                        scroll.reflectScrolledClipView(scroll.contentView)
                        try await Task.sleep(for: .milliseconds(50))
                        #expect(scroll.convert(scroll.bounds, to: controller.view) == frame)
                    }
                    let bitmap = try #require(controller.view.bitmapImageRepForCachingDisplay(in: controller.view.bounds))
                    controller.view.cacheDisplay(in: controller.view.bounds, to: bitmap)
                    let png = try #require(bitmap.representation(using: .png, properties: [:]))
                    try png.write(to: URL(filePath: "/private/tmp/rebind-card-\(count)-\(language)-\(Int(size.width)).png"))
                }
            }
        }
    }

    private func descendants(_ view: NSView) -> [NSView] {
        view.subviews.flatMap { [$0] + descendants($0) }
    }
}
