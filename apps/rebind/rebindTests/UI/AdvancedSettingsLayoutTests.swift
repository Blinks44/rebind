import AppKit
import SwiftUI
import XCTest
@testable import rebind

@MainActor final class AdvancedSettingsLayoutTests: XCTestCase {
    func testAdvancedFeedbackAndProtectedStatesFitNativeSettings() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: "RebindAdvancedLayout-\(UUID())")
        defer { try? FileManager.default.removeItem(at: directory) }
        for state in ["overview", "imported", "reset", "exported", "invalid", "incompatible", "protected",
                      "writeFailed", "importWriteFailed", "exportFailed", "staleReview", "reopen"] {
            let store = ConfigurationStore(url: directory.appending(path: "\(state)/configuration.json"))
            var configuration = Configuration()
            configuration.hasCompletedSetup = true
            try store.save(configuration)
            if state == "protected" { try Data("protected".utf8).write(to: store.url) }
            let model = AppModel(store: store, readPermissions: { InputPermissions() },
                loginItem: LoginItemModel(service: LoginItemServiceStub()),
                languagePreferenceSaved: { _ in })
            let page = AdvancedSettingsModel(app: model)
            switch state {
            case "imported": await page.validateImport(at: store.url); page.confirmReplacement()
            case "reset": page.reviewReset(); page.confirmReplacement()
            case "invalid": await page.validateImport(at: directory.appending(path: "missing.json"))
            case "exported": await page.export(to: directory.appending(path: "exported.json"))
            case "incompatible":
                let backup = directory.appending(path: "future.json")
                try Data("{\"schemaVersion\":999}".utf8).write(to: backup)
                await page.validateImport(at: backup)
            case "staleReview":
                await page.validateImport(at: store.url)
                try model.saveLanguagePreference(.fr)
                page.confirmReplacement()
            case "reopen": try model.saveLanguagePreference(.de)
            case "writeFailed", "importWriteFailed":
                if state == "writeFailed" { page.reviewReset() }
                else { await page.validateImport(at: store.url) }
                try FileManager.default.removeItem(at: store.url)
                try FileManager.default.createDirectory(at: store.url, withIntermediateDirectories: false)
                page.confirmReplacement()
            case "exportFailed": await page.export(to: store.url)
            default: break
            }
            for language in AppLanguage.allCases.map(\.rawValue) {
                for scheme in [ColorScheme.light, .dark] {
                    let controller = NSHostingController(rootView: AdvancedSettingsView(model: model, editing: page)
                        .environment(\.locale, Locale(identifier: language)).preferredColorScheme(scheme))
                    let window = NSWindow(contentViewController: controller)
                    window.isReleasedWhenClosed = false
                    defer { window.close() }
                    for size in [NSSize(width: 600, height: 300), NSSize(width: 808, height: 460)] {
                        window.setContentSize(size)
                        try await Task.sleep(for: .milliseconds(50))
                        controller.view.layoutSubtreeIfNeeded()
                        let scroll = try XCTUnwrap(findScroll(controller.view))
                        let bounds = scroll.convert(scroll.bounds, to: controller.view)
                        let context = "\(state), \(language), \(scheme), \(size)"
                        XCTAssertEqual(controller.view.bounds.width, size.width, accuracy: 1, context)
                        XCTAssertEqual(controller.view.bounds.height, size.height, accuracy: 1, context)
                        XCTAssertGreaterThan(bounds.height, 0, context)
                        XCTAssertGreaterThanOrEqual(bounds.minY, -1, context)
                        XCTAssertLessThanOrEqual(bounds.maxY, size.height + 1, context)
                        XCTAssertLessThanOrEqual(scroll.documentView?.frame.width ?? 0,
                                                 scroll.contentView.bounds.width + 1, context)
                        if language == "ru" && size.width == 808 {
                            let bitmap = try XCTUnwrap(controller.view.bitmapImageRepForCachingDisplay(in: controller.view.bounds))
                            controller.view.cacheDisplay(in: controller.view.bounds, to: bitmap)
                            let png = try XCTUnwrap(bitmap.representation(using: .png, properties: [:]))
                            let attachment = XCTAttachment(data: png, uniformTypeIdentifier: "public.png")
                            attachment.name = "advanced-\(state)-\(language)-\(scheme)"
                            attachment.lifetime = .keepAlways
                            add(attachment)
                        }
                    }
                }
            }
            if state == "writeFailed" || state == "importWriteFailed" {
                try FileManager.default.removeItem(at: store.url)
            }
        }
    }

    func testFiveSettingsSectionsAndDiagnosticsFitAllLanguages() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: "RebindAdvancedShell-\(UUID())")
        defer { try? FileManager.default.removeItem(at: directory) }
        let model = AppModel(store: ConfigurationStore(url: directory.appending(path: "configuration.json")),
            readPermissions: { InputPermissions() }, loginItem: LoginItemModel(service: LoginItemServiceStub()))
        for language in AppLanguage.allCases.map(\.rawValue) {
            for scheme in [ColorScheme.light, .dark] {
                let controller = NSHostingController(rootView: SettingsView(model: model, selection: .constant(.advanced))
                    .environment(\.locale, Locale(identifier: language)).preferredColorScheme(scheme))
                let window = NSWindow(contentViewController: controller)
                window.isReleasedWhenClosed = false
                defer { window.close() }
                window.setContentSize(NSSize(width: 600, height: 480))
                try await Task.sleep(for: .milliseconds(60))
                controller.view.layoutSubtreeIfNeeded()
                XCTAssertEqual(controller.view.bounds.width, 600, accuracy: 1)
                XCTAssertEqual(controller.view.bounds.height, 480, accuracy: 1)
                let diagnostics = NSHostingController(rootView: InputDiagnosticsView(model: model)
                    .environment(\.locale, Locale(identifier: language)).preferredColorScheme(scheme))
                let diagnosticWindow = NSWindow(contentViewController: diagnostics)
                diagnosticWindow.isReleasedWhenClosed = false
                defer { diagnosticWindow.close() }
                diagnosticWindow.setContentSize(NSSize(width: 840, height: 570))
                try await Task.sleep(for: .milliseconds(60))
                diagnostics.view.layoutSubtreeIfNeeded()
                XCTAssertEqual(diagnostics.view.bounds.width, 840, accuracy: 1)
                XCTAssertEqual(diagnostics.view.bounds.height, 570, accuracy: 1)
            }
        }
    }

    private func findScroll(_ view: NSView) -> NSScrollView? {
        if let scroll = view as? NSScrollView { return scroll }
        return view.subviews.lazy.compactMap { self.findScroll($0) }.first
    }
}
