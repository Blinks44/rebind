import AppKit
import SwiftUI
import XCTest
@testable import rebind

@MainActor final class InputLanguageLayoutTests: XCTestCase {
    func testDevicesAndLanguageFitInAllLocales() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: "RebindStandardSettings-\(UUID())")
        defer { try? FileManager.default.removeItem(at: directory) }
        let model = AppModel(store: ConfigurationStore(url: directory.appending(path: "configuration.json")),
            readPermissions: { InputPermissions() }, loginItem: LoginItemModel(service: LoginItemServiceStub()))
        for language in AppLanguage.allCases.map(\.rawValue) {
            for appearance in [ColorScheme.light, .dark] {
                try await check(DevicesView(model: model), name: "devices", language: language, appearance: appearance,
                    sizes: [NSSize(width: 640, height: 480), NSSize(width: 760, height: 600)])
                try await check(SettingsView(model: model, selection: .constant(.language)),
                    name: "standard-language", language: language, appearance: appearance,
                    sizes: [NSSize(width: 600, height: 480), NSSize(width: 760, height: 600)])
            }
        }
    }

    func testLanguageFailureAndHoldEditorWrapWithinNativeScrollViewport() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: "RebindInputLanguageLayout-\(UUID())")
        let store = ConfigurationStore(url: directory.appending(path: "configuration.json"))
        defer { try? FileManager.default.removeItem(at: directory) }
        try store.save(Configuration())
        let model = AppModel(store: store, readPermissions: { InputPermissions() },
            loginItem: LoginItemModel(service: LoginItemServiceStub()), preferredLanguages: ["en"])
        let editing = LanguageSettingsModel(app: model)
        editing.draft = .ru
        try FileManager.default.removeItem(at: store.url)
        try FileManager.default.createDirectory(at: store.url, withIntermediateDirectories: false)
        editing.apply()
        XCTAssertTrue(editing.saveFailed)

        for language in AppLanguage.allCases.map(\.rawValue) {
            for appearance in [ColorScheme.light, .dark] {
                try await check(LanguageSettingsView(model: model, editing: editing), name: "language-failure",
                    language: language, appearance: appearance, sizes: [NSSize(width: 600, height: 300),
                        NSSize(width: 760, height: 460)])
                for duration in [UInt32(100), 575, 5000] {
                    let binding = rebind.Binding(scope: .allMice, trigger: .mouseButton(99), modifiers: [],
                        action: .workspace(.openSystemSettings), activation: .hold, holdDurationMilliseconds: duration)
                    try await check(BindingEditor(model: model, scope: .allMice, existing: binding),
                        name: "hold-\(duration)", language: language, appearance: appearance,
                        sizes: [NSSize(width: 520, height: 600), NSSize(width: 520, height: 760)])
                }
            }
        }
    }

    private func check<Content: View>(_ content: Content, name: String, language: String,
                                     appearance: ColorScheme, sizes: [NSSize]) async throws {
        let controller = NSHostingController(rootView: content.environment(\.locale, Locale(identifier: language))
            .preferredColorScheme(appearance))
        let window = NSWindow(contentViewController: controller)
        window.appearance = NSAppearance(named: appearance == .dark ? .darkAqua : .aqua)
        window.isReleasedWhenClosed = false
        defer { window.close() }
        for size in sizes {
            window.setContentSize(size)
            try await Task.sleep(for: .milliseconds(70))
            controller.view.layoutSubtreeIfNeeded()
            let scroll = try XCTUnwrap(findScroll(controller.view))
            let viewport = controller.view.bounds
            let bounds = scroll.convert(scroll.bounds, to: controller.view)
            let context = "\(name), \(language), \(appearance), \(size)"
            XCTAssertEqual(viewport.width, size.width, accuracy: 1, context)
            XCTAssertEqual(viewport.height, size.height, accuracy: 1, context)
            XCTAssertGreaterThan(bounds.height, 0, context)
            XCTAssertGreaterThanOrEqual(bounds.minY, viewport.minY - 1, context)
            XCTAssertLessThanOrEqual(bounds.maxY, viewport.maxY + 1, context)
            XCTAssertLessThanOrEqual(scroll.documentView?.frame.width ?? 0, scroll.contentView.bounds.width + 1, context)
            if language == "ru" && size.height == sizes.last?.height {
                let bitmap = try XCTUnwrap(controller.view.bitmapImageRepForCachingDisplay(in: viewport))
                controller.view.cacheDisplay(in: viewport, to: bitmap)
                let png = try XCTUnwrap(bitmap.representation(using: .png, properties: [:]))
                let attachment = XCTAttachment(data: png, uniformTypeIdentifier: "public.png")
                attachment.name = "\(name)-\(language)-\(appearance)"
                attachment.lifetime = .keepAlways
                add(attachment)
            }
        }
    }

    private func findScroll(_ view: NSView) -> NSScrollView? {
        if let scroll = view as? NSScrollView { return scroll }
        for child in view.subviews { if let scroll = findScroll(child) { return scroll } }
        return nil
    }
}
