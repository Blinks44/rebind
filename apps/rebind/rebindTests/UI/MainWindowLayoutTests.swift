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
        for language in AppLanguage.allCases.map(\.rawValue) {
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
                    configureMainWindow(window)
                    window.isReleasedWhenClosed = false
                    defer { window.close() }
                    try await Task.sleep(for: .milliseconds(100))
                    for size in sizes {
                        // Sketch sizes include the titlebar now covered by the hosting view.
                        window.setFrame(NSRect(origin: window.frame.origin, size: size), display: false)
                        controller.view.layoutSubtreeIfNeeded()
                        // Let AppKit attach and lay out the native hosting/list hierarchy.
                        try await Task.sleep(for: .milliseconds(100))
                        controller.view.layoutSubtreeIfNeeded()
                        let viewport = controller.view.bounds
                        let context = "\(language), grants=\(permissions), rules=\(hasRules), size=\(size)"
                        XCTAssertEqual(viewport.width, size.width, accuracy: 1, context)
                        XCTAssertEqual(viewport.height, size.height, accuracy: 1, context)
                        try MainWindowLayoutAssertions.verifyRegions(in: controller.view, context: context)
                        XCTAssertEqual(window.minSize.height, 600, accuracy: 1, context)
                    }
                }
            }
        }
    }

    /// Renders the main window and the sheets with fixture rules for review against Sketch in Light and Dark.
    func testKeyboardScreensRenderAtSketchSize() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: "RebindKeyboard-\(UUID())")
        let store = ConfigurationStore(url: directory.appending(path: "configuration.json"))
        defer { try? FileManager.default.removeItem(at: directory) }
        func rule(_ key: UInt16, _ modifiers: ModifierSet, _ action: RebindAction, enabled: Bool = true) -> rebind.Binding {
            rebind.Binding(scope: .allKeyboards, trigger: .key(key), modifiers: modifiers, action: action, isEnabled: enabled)
        }
        let language = AppLocalization.language
        AppLocalization.configureAtLaunch(.en)
        defer { AppLocalization.configureAtLaunch(language) }
        var configuration = Configuration(isEnabled: true, bindings: [
            rule(113, [], .shortcut(KeyboardShortcut(keyCode: 53, modifiers: []))),
            rule(38, [.control, .option], .dock(.nextSpace)),
            rule(40, [.control, .option], .dock(.previousSpace)),
            rule(105, [], .dock(.missionControl)),
            rule(13, .option, .window(.close)),
            rule(49, [.control, .option], .dock(.showDesktop)),
            rule(107, [], .media(.playPause), enabled: false)
        ])
        configuration.hasCompletedSetup = true
        try store.save(configuration)
        let model = AppModel(store: store, readPermissions: { InputPermissions(accessibility: true, posting: true) },
                             preferredLanguages: ["en"])
        model.mailbox.configure(configuration)
        model.mailbox.state.withLock { $0.status = .active }
        model.refresh()
        for appearance in [ColorScheme.light, .dark] {
            let controller = NSHostingController(rootView: ContentView(model: model)
                .environment(\.locale, Locale(identifier: "en")).preferredColorScheme(appearance))
            let window = NSWindow(contentViewController: controller)
            configureMainWindow(window)
            window.appearance = NSAppearance(named: appearance == .dark ? .darkAqua : .aqua)
            window.isReleasedWhenClosed = false
            defer { window.close() }
            let size = NSSize(width: 1080, height: 720)
            window.setFrame(NSRect(origin: window.frame.origin, size: size), display: false)
            try await Task.sleep(for: .milliseconds(200))
            controller.view.layoutSubtreeIfNeeded()
            let viewport = controller.view.bounds
            XCTAssertEqual(viewport.width, size.width, accuracy: 1)
            XCTAssertEqual(viewport.height, size.height, accuracy: 1)
            try MainWindowLayoutAssertions.verifyRegions(in: controller.view, context: "keyboard \(appearance)")
            let bitmap = try XCTUnwrap(controller.view.bitmapImageRepForCachingDisplay(in: viewport))
            controller.view.cacheDisplay(in: viewport, to: bitmap)
            let png = try XCTUnwrap(bitmap.representation(using: .png, properties: [:]))
            let attachment = XCTAttachment(data: png, uniformTypeIdentifier: "public.png")
            attachment.name = "main-keyboard-\(appearance)"
            attachment.lifetime = .keepAlways
            add(attachment)

            try await attach(ContentView(model: model, initialDestination: .input(.allMice)), size: size,
                             mainWindow: true, appearance: appearance, name: "main-empty")
            try await attach(BindingEditor(model: model, scope: .allKeyboards, existing: configuration.bindings[1]),
                             size: NSSize(width: 520, height: 640), appearance: appearance, name: "editor-keyboard")
            try await attach(ProfileManagerView(model: model), size: NSSize(width: 560, height: 480),
                             appearance: appearance, name: "profiles")
            try await attach(PermissionSetupView(model: model, context: .firstRun), size: NSSize(width: 560, height: 580),
                             appearance: appearance, name: "setup")
            try await attach(AboutView(), size: NSSize(width: 440, height: 448), appearance: appearance, name: "about")
        }
    }

    /// Hosts a view in an offscreen window of the given size and attaches its rendering.
    private func attach(_ view: some View, size: NSSize, mainWindow: Bool = false,
                        appearance: ColorScheme, name: String) async throws {
        let controller = NSHostingController(rootView: view.environment(\.locale, Locale(identifier: "en"))
            .preferredColorScheme(appearance))
        let window = NSWindow(contentViewController: controller)
        if mainWindow { configureMainWindow(window) }
        window.appearance = NSAppearance(named: appearance == .dark ? .darkAqua : .aqua)
        window.isReleasedWhenClosed = false
        defer { window.close() }
        if mainWindow { window.setFrame(NSRect(origin: window.frame.origin, size: size), display: false) }
        else { window.setContentSize(size) }
        try await Task.sleep(for: .milliseconds(200))
        controller.view.layoutSubtreeIfNeeded()
        let bitmap = try XCTUnwrap(controller.view.bitmapImageRepForCachingDisplay(in: controller.view.bounds))
        controller.view.cacheDisplay(in: controller.view.bounds, to: bitmap)
        let attachment = XCTAttachment(data: try XCTUnwrap(bitmap.representation(using: .png, properties: [:])),
                                       uniformTypeIdentifier: "public.png")
        attachment.name = "\(name)-\(appearance)"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private enum SettingsFixture: String, CaseIterable {
        case paused, active, missingAccess, engineError, approval, permissionsMissing, permissionsAllowed
        case permissionsPosting, permissionsPaused, permissionsEngineError
        case devices, language, languageReopen, languageLocked
        case advanced, advancedLocked

        var destination: MainDestination {
            switch self {
            case .permissionsMissing, .permissionsAllowed, .permissionsPosting, .permissionsPaused, .permissionsEngineError:
                .settings(.permissions)
            case .devices: .devices
            case .language, .languageReopen, .languageLocked: .settings(.language)
            case .advanced, .advancedLocked: .settings(.advanced)
            default: .settings(.general)
            }
        }
    }

    func testSettingsDoesNotExpandNavigationBeyondTheWindow() async throws {
        try await checkSettingsFixtures([.paused, .active, .missingAccess, .engineError, .approval])
    }

    func testPermissionsDoNotExpandNavigationBeyondTheWindow() async throws {
        try await checkSettingsFixtures([.permissionsMissing, .permissionsAllowed, .permissionsPosting,
                                         .permissionsPaused, .permissionsEngineError])
    }

    func testDevicesAndLanguageDoNotExpandNavigationBeyondTheWindow() async throws {
        try await checkSettingsFixtures([.devices, .language, .languageReopen, .languageLocked])
    }

    func testAdvancedDoesNotExpandNavigationBeyondTheWindow() async throws {
        try await checkSettingsFixtures([.advanced, .advancedLocked])
    }

    /// Keep each native test's window/render lifetime bounded while retaining the same state matrix.
    private func checkSettingsFixtures(_ fixtures: [SettingsFixture]) async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: "RebindMainSettings-\(UUID())")
        defer { try? FileManager.default.removeItem(at: directory) }
        let sizes = [NSSize(width: 880, height: 600), NSSize(width: 1040, height: 640),
                     NSSize(width: 1157, height: 750), NSSize(width: 1280, height: 800)]
        for fixture in fixtures {
            let store = ConfigurationStore(url: directory.appending(path: "\(fixture.rawValue)/configuration.json"))
            var configuration = Configuration(isEnabled: fixture != .paused && fixture != .permissionsPaused)
            configuration.hasCompletedSetup = true
            try store.save(configuration)
            if fixture == .languageLocked || fixture == .advancedLocked {
                try Data("protected future/corrupt fixture".utf8).write(to: store.url)
            }
            let grants = fixture == .missingAccess || fixture == .permissionsMissing
                ? InputPermissions() : InputPermissions(accessibility: true, posting: fixture != .permissionsPosting)
            let service = LoginItemServiceStub(status: fixture == .approval ? .requiresApproval : .off)
            let model = AppModel(store: store, readPermissions: { grants },
                loginItem: LoginItemModel(service: service), preferredLanguages: ["en"])
            if fixture == .languageReopen { try model.saveLanguagePreference(.fr) }
            model.mailbox.configure(configuration)
            model.mailbox.state.withLock {
                $0.status = fixture == .engineError || fixture == .permissionsEngineError ? .tapFailed : .active
            }
            model.refresh()
            for language in AppLanguage.allCases.map(\.rawValue) {
                for appearance in [ColorScheme.light, .dark] {
                    let controller = NSHostingController(rootView: ContentView(model: model,
                        initialDestination: fixture.destination)
                        .environment(\.locale, Locale(identifier: language))
                        .preferredColorScheme(appearance))
                    let window = NSWindow(contentViewController: controller)
                    configureMainWindow(window)
                    // Native sidebar controls must share the SwiftUI fixture appearance.
                    window.appearance = NSAppearance(named: appearance == .dark ? .darkAqua : .aqua)
                    window.isReleasedWhenClosed = false
                    defer { window.close() }
                    try await Task.sleep(for: .milliseconds(100))
                    for size in sizes {
                        window.setFrame(NSRect(origin: window.frame.origin, size: size), display: false)
                        controller.view.layoutSubtreeIfNeeded()
                        try await Task.sleep(for: .milliseconds(100))
                        controller.view.layoutSubtreeIfNeeded()
                        let viewport = controller.view.bounds
                        let context = "\(fixture), \(language), \(appearance), \(size)"
                        XCTAssertEqual(viewport.width, size.width, accuracy: 1, context)
                        XCTAssertEqual(viewport.height, size.height, accuracy: 1, context)
                        try MainWindowLayoutAssertions.verifyRegions(in: controller.view, context: context)
                        XCTAssertEqual(window.minSize.height, 600, accuracy: 1, context)
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

    private func configureMainWindow(_ window: NSWindow) {
        window.styleMask.insert(.fullSizeContentView)
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
    }
}
