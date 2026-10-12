import AppKit
import SwiftUI
import XCTest
@testable import rebind

/// Permission fixtures never request grants or start input capture.
@MainActor final class PermissionSettingsLayoutTests: XCTestCase {
    func testPermissionStatesFitAndScrollInAllLanguagesAndAppearances() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: "RebindPermissionLayout-\(UUID())")
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = ConfigurationStore(url: directory.appending(path: "configuration.json"))
        var configuration = Configuration()
        configuration.hasCompletedSetup = true
        try store.save(configuration)
        let grants = [InputPermissions(), InputPermissions(accessibility: true),
                      InputPermissions(accessibility: true, posting: true)]
        let sizes = [NSSize(width: 600, height: 480), NSSize(width: 648, height: 600),
                     NSSize(width: 808, height: 640)]
        for (state, permissions) in grants.enumerated() {
            let model = AppModel(store: store, readPermissions: { permissions },
                loginItem: LoginItemModel(service: LoginItemServiceStub()),
                preferredLanguages: ["en"], languagePreferenceSaved: { _ in })
            for language in ["en", "ru", "de", "fr"] {
                for appearance in [ColorScheme.light, .dark] {
                    let controller = NSHostingController(rootView: SettingsView(model: model, selection: .constant(.permissions))
                        .environment(\.locale, Locale(identifier: language)).preferredColorScheme(appearance))
                    let window = NSWindow(contentViewController: controller)
                    window.isReleasedWhenClosed = false
                    window.appearance = NSAppearance(named: appearance == .dark ? .darkAqua : .aqua)
                    defer { window.close() }
                    for size in sizes {
                        window.setContentSize(size)
                        controller.view.layoutSubtreeIfNeeded()
                        try await Task.sleep(for: .milliseconds(50))
                        controller.view.layoutSubtreeIfNeeded()
                        let scroll = try XCTUnwrap(firstScrollView(in: controller.view))
                        let document = try XCTUnwrap(scroll.documentView)
                        let bounds = scroll.convert(scroll.bounds, to: controller.view)
                        let context = "grants=\(permissions), \(language), \(appearance), \(size)"
                        XCTAssertEqual(controller.view.bounds.width, size.width, accuracy: 1, context)
                        XCTAssertEqual(controller.view.bounds.height, size.height, accuracy: 1, context)
                        XCTAssertGreaterThan(bounds.height, 0, context)
                        XCTAssertGreaterThanOrEqual(bounds.minY, -1, context)
                        XCTAssertLessThanOrEqual(bounds.maxY, size.height + 1, context)
                        XCTAssertLessThanOrEqual(document.frame.width, scroll.contentView.bounds.width + 1, context)
                        // All guidance remains reachable when the content exceeds the viewport.
                        document.scrollToVisible(NSRect(x: 0,
                            y: document.isFlipped ? document.bounds.maxY - 1 : document.bounds.minY,
                            width: 1, height: 1))
                        XCTAssertGreaterThanOrEqual(document.visibleRect.maxY,
                            document.isFlipped ? document.bounds.maxY - 1 : 0, context)
                        document.scrollToVisible(NSRect(x: 0, y: document.isFlipped ? 0 : document.bounds.maxY - 1,
                                                        width: 1, height: 1))
                        if size.width == 808 && language == "de" || size.width == 600 && language == "ru" {
                            let bitmap = try XCTUnwrap(controller.view.bitmapImageRepForCachingDisplay(in: controller.view.bounds))
                            controller.view.cacheDisplay(in: controller.view.bounds, to: bitmap)
                            let png = try XCTUnwrap(bitmap.representation(using: .png, properties: [:]))
                            let attachment = XCTAttachment(data: png, uniformTypeIdentifier: "public.png")
                            attachment.name = "permissions-\(state)-\(language)-\(appearance)-\(Int(size.width))"
                            attachment.lifetime = .keepAlways
                            add(attachment)
                        }
                    }
                }
            }
        }
    }

    private func firstScrollView(in view: NSView) -> NSScrollView? {
        if let scroll = view as? NSScrollView { return scroll }
        return view.subviews.lazy.compactMap { self.firstScrollView(in: $0) }.first
    }
}
