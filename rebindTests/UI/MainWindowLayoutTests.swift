import AppKit
import SwiftUI
import XCTest
@testable import rebind

/// Native layout coverage: isolated models never start capture or load user data.
@MainActor final class MainWindowLayoutTests: XCTestCase {
    func testPermissionNoticeDoesNotExpandNavigationBeyondTheWindow() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: "RebindLayout-\(UUID())")
        let store = ConfigurationStore(url: directory.appending(path: "configuration.json"))
        defer { try? FileManager.default.removeItem(at: directory) }
        let sizes = [NSSize(width: 1040, height: 640), NSSize(width: 880, height: 600),
                     NSSize(width: 1280, height: 800)]
        let grants = [InputPermissions(), InputPermissions(accessibility: true),
                      InputPermissions(accessibility: true, posting: true)]
        for language in ["en", "ru", "de", "fr"] {
            for permissions in grants {
                for hasRules in [false, true] {
                    var configuration = Configuration()
                    configuration.hasCompletedSetup = true
                    if hasRules {
                        configuration.bindings = [rebind.Binding(scope: .allKeyboards,
                            trigger: .key(0), modifiers: .control,
                            action: .shortcut(KeyboardShortcut(keyCode: 1, modifiers: .command)))]
                    }
                    try store.save(configuration)
                    let model = AppModel(store: store, readPermissions: { permissions })
                    let controller = NSHostingController(rootView: ContentView(model: model)
                        .environment(\.locale, Locale(identifier: language)))
                    let window = NSWindow(contentViewController: controller)
                    window.isReleasedWhenClosed = false
                    defer { window.close() }
                    for size in sizes {
                        window.setContentSize(size)
                        controller.view.layoutSubtreeIfNeeded()
                        // Let AppKit attach and lay out the native split/list hierarchy.
                        try await Task.sleep(for: .milliseconds(100))
                        controller.view.layoutSubtreeIfNeeded()
                        let split = try XCTUnwrap(firstSplitView(in: controller.view))
                        let bounds = split.convert(split.bounds, to: controller.view)
                        let viewport = controller.view.bounds
                        let context = "\(language), grants=\(permissions), rules=\(hasRules), size=\(size)"
                        XCTAssertEqual(viewport.width, size.width, accuracy: 1, context)
                        XCTAssertEqual(viewport.height, size.height, accuracy: 1, context)
                        XCTAssertGreaterThan(bounds.height, 0, context)
                        XCTAssertGreaterThanOrEqual(bounds.minY, viewport.minY - 1, context)
                        XCTAssertLessThanOrEqual(bounds.maxY, viewport.maxY + 1, context)
                        XCTAssertGreaterThanOrEqual(bounds.minX, viewport.minX - 1, context)
                        XCTAssertLessThanOrEqual(bounds.maxX, viewport.maxX + 1, context)
                    }
                }
            }
        }
    }

    private enum SettingsFixture: String, CaseIterable {
        case paused, active, missingAccess, engineError, approval, permissionsMissing, permissionsAllowed
        case input, language, languageReopen, languageLocked
        case advanced, advancedLocked

        var destination: MainDestination {
            switch self {
            case .permissionsMissing, .permissionsAllowed: .settings(.permissions)
            case .input: .settings(.input)
            case .language, .languageReopen, .languageLocked: .settings(.language)
            case .advanced, .advancedLocked: .settings(.advanced)
            default: .settings(.general)
            }
        }
    }

    func testSettingsDoesNotExpandNavigationBeyondTheWindow() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: "RebindMainSettings-\(UUID())")
        defer { try? FileManager.default.removeItem(at: directory) }
        let sizes = [NSSize(width: 880, height: 600), NSSize(width: 1040, height: 640),
                     NSSize(width: 1157, height: 750), NSSize(width: 1280, height: 800)]
        for fixture in SettingsFixture.allCases {
            let store = ConfigurationStore(url: directory.appending(path: "\(fixture.rawValue)/configuration.json"))
            var configuration = Configuration(isEnabled: fixture != .paused)
            configuration.hasCompletedSetup = true
            try store.save(configuration)
            if fixture == .languageLocked || fixture == .advancedLocked {
                try Data("protected future/corrupt fixture".utf8).write(to: store.url)
            }
            let grants = fixture == .missingAccess || fixture == .permissionsMissing
                ? InputPermissions() : InputPermissions(accessibility: true, posting: true)
            let service = LoginItemServiceStub(status: fixture == .approval ? .requiresApproval : .off)
            let model = AppModel(store: store, readPermissions: { grants },
                loginItem: LoginItemModel(service: service), preferredLanguages: ["en"])
            if fixture == .languageReopen { try model.saveLanguagePreference(.fr) }
            model.mailbox.configure(configuration)
            model.mailbox.state.withLock { $0.status = fixture == .engineError ? .tapFailed : .active }
            model.refresh()
            for language in ["en", "ru", "de", "fr"] {
                for appearance in [ColorScheme.light, .dark] {
                    let controller = NSHostingController(rootView: ContentView(model: model,
                        initialDestination: fixture.destination)
                        .environment(\.locale, Locale(identifier: language))
                        .preferredColorScheme(appearance))
                    let window = NSWindow(contentViewController: controller)
                    // Native sidebar controls must share the SwiftUI fixture appearance.
                    window.appearance = NSAppearance(named: appearance == .dark ? .darkAqua : .aqua)
                    window.isReleasedWhenClosed = false
                    defer { window.close() }
                    for size in sizes {
                        window.setContentSize(size)
                        controller.view.layoutSubtreeIfNeeded()
                        try await Task.sleep(for: .milliseconds(100))
                        controller.view.layoutSubtreeIfNeeded()
                        let split = try XCTUnwrap(firstSplitView(in: controller.view))
                        let viewport = controller.view.bounds
                        let context = "\(fixture), \(language), \(appearance), \(size)"
                        XCTAssertEqual(viewport.width, size.width, accuracy: 1, context)
                        XCTAssertEqual(viewport.height, size.height, accuracy: 1, context)
                        // A correctly sized root hosting view alone did not catch the regression.
                        // Check the actual split and both native columns in viewport coordinates.
                        for view in [split] + split.subviews {
                            let bounds = view.convert(view.bounds, to: controller.view)
                            XCTAssertGreaterThan(bounds.height, 0, context)
                            XCTAssertGreaterThanOrEqual(bounds.minX, viewport.minX - 1, context)
                            XCTAssertGreaterThanOrEqual(bounds.minY, viewport.minY - 1, context)
                            XCTAssertLessThanOrEqual(bounds.maxX, viewport.maxX + 1, context)
                            XCTAssertLessThanOrEqual(bounds.maxY, viewport.maxY + 1, context)
                        }
                        if size.width == 1040 && language == "ru" {
                            let bitmap = try XCTUnwrap(controller.view.bitmapImageRepForCachingDisplay(in: viewport))
                            controller.view.cacheDisplay(in: viewport, to: bitmap)
                            let png = try XCTUnwrap(bitmap.representation(using: .png, properties: [:]))
                            let attachment = XCTAttachment(data: png, uniformTypeIdentifier: "public.png")
                            attachment.name = "main-settings-\(fixture.rawValue)-\(language)-\(appearance)"
                            attachment.lifetime = .keepAlways
                            add(attachment)
                        }
                    }
                }
            }
        }
    }

    private func firstSplitView(in view: NSView) -> NSSplitView? {
        if let split = view as? NSSplitView { return split }
        for child in view.subviews {
            if let split = firstSplitView(in: child) { return split }
        }
        return nil
    }
}
