import AppKit
import SwiftUI

@main
struct rebindApp: App {
    @NSApplicationDelegateAdaptor(RebindAppDelegate.self) private var delegate

    private var opensWindowAtLaunch: Bool {
        let configuration = delegate.model.configuration
        return configuration.opensWindowAtLaunch || (!configuration.showsDockIcon && !configuration.showsMenuBarIcon)
    }

    @ViewBuilder private var mainContent: some View {
        #if DEBUG
        if RebindAppDelegate.isWindowFixture {
            ContentView(model: delegate.model, persistsWindowSelection: false)
                .environment(\.locale, delegate.model.activeLanguage.locale)
        } else if ProcessInfo.processInfo.arguments.contains("--keyboard-fixture") {
            KeyboardNavigationFixture()
        } else if ProcessInfo.processInfo.arguments.contains("--application-fixture") {
            ApplicationUIFixture()
        } else {
            ContentView(model: delegate.model).environment(\.locale, delegate.model.activeLanguage.locale)
        }
        #else
        ContentView(model: delegate.model).environment(\.locale, delegate.model.activeLanguage.locale)
        #endif
    }

    var body: some Scene {
        Window(.rebindWindowTitle, id: "main") {
            mainContent
                .background { ActiveSpaceWindow() }
                .background { MainWindowRegistration(presenter: RebindAppDelegate.mainWindow) }
                .background { MainWindowPersistence() }
        }
            .windowToolbarStyle(.unified(showsTitle: false))
            .defaultSize(width: 1080, height: 720)
            // "Start in the background" keeps the window closed at launch, including at login, unless
            // Rebind shows neither a Dock nor a Menu Bar icon: then the window is its only way in.
            .defaultLaunchBehavior(opensWindowAtLaunch ? .automatic : .suppressed)
            .restorationBehavior(.disabled)
            .commands {
                BindingsCommands()
                CommandGroup(replacing: .appSettings) {
                    Button(.settingsTitle) {
                        delegate.model.requestedSettingsSection = delegate.model.settingsSection
                        RebindAppDelegate.mainWindow.show()
                    }.keyboardShortcut(",", modifiers: .command)
                }
                CommandGroup(replacing: .appInfo) {
                    AboutCommand(language: delegate.model.activeLanguage)
                    Button(AppLocalization.string(.checkForUpdates, language: delegate.model.activeLanguage)) {
                        RebindAppDelegate.updater.checkForUpdates()
                    }.disabled(!RebindAppDelegate.updater.canCheckForUpdates || delegate.model.recording != nil)
                }
            }
        Window(.aboutTitle, id: "about") {
            AboutView().environment(\.locale, delegate.model.activeLanguage.locale)
                .background { ActiveSpaceWindow() }
        }
        .defaultSize(width: 440, height: 448)
        .windowResizability(.contentSize)
        .defaultLaunchBehavior(.suppressed)
    }
}

final class RebindAppDelegate: NSObject, NSApplicationDelegate {
    static var isWindowFixture: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("--window-fixture")
        #else
        false
        #endif
    }

    private static var runningTests: Bool {
        if isWindowFixture { return true }
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--keyboard-fixture")
            || ProcessInfo.processInfo.arguments.contains("--application-fixture") { return true }
        #endif
        return ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
            || NSClassFromString("XCTestCase") != nil
    }
    let model: AppModel
    private var menuBar: MenuBarController?
    private var terminationSignal: DispatchSourceSignal?

    override init() {
        let runningTests = Self.runningTests
        // Secondary scenes must also stay away from production storage in debug fixtures/tests.
        let store: ConfigurationStore = runningTests
            ? ConfigurationStore(url: FileManager.default.temporaryDirectory
                .appending(path: "RebindTestScene-\(UUID())").appending(path: "configuration.json"))
            : .applicationStore
        model = AppModel(store: store, loadConfiguration: !runningTests, languagePreferenceSaved: { preference in
            if !runningTests { AppLanguageDefaults(defaults: .standard).apply(preference) }
        })
        super.init()
        if Self.isWindowFixture {
            model.setPresencePreference(\.opensWindowAtLaunch, to: false)
            model.setPresencePreference(\.showsDockIcon, to: false)
            model.completePermissionSetup()
        }
        if !runningTests {
            AppLocalization.configureAtLaunch(model.activeLanguage)
            if !model.storageLocked {
                AppLanguageDefaults(defaults: .standard).apply(model.configuration.languagePreference)
            }
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard !Self.runningTests || Self.isWindowFixture else { return }
        // `kill`, `launchctl` and installers end a process with SIGTERM, which skips
        // applicationWillTerminate: held keys would stay down and the gesture button diverted.
        // Quit normally instead, as for ⌘Q.
        signal(SIGTERM, SIG_IGN)
        let terminationSignal = DispatchSource.makeSignalSource(signal: SIGTERM, queue: .main)
        terminationSignal.setEventHandler { NSApp.terminate(nil) }
        terminationSignal.resume()
        self.terminationSignal = terminationSignal
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(windowDidOpen), name: NSWindow.didBecomeMainNotification, object: nil)
        center.addObserver(self, selector: #selector(windowWillClose), name: NSWindow.willCloseNotification, object: nil)
        // The first window is created after launch finishes; decide once it exists.
        DispatchQueue.main.async { [model] in Self.updateDockIcon(preferred: model.configuration.showsDockIcon) }
        menuBar = MenuBarController(model: model)
        if !Self.isWindowFixture { model.start() }
    }

    @objc private func windowDidOpen(_ notification: Notification) {
        Self.updateDockIcon(preferred: model.configuration.showsDockIcon)
    }

    @objc private func windowWillClose(_ notification: Notification) {
        Self.updateDockIcon(preferred: model.configuration.showsDockIcon, closing: notification.object as? NSWindow)
    }

    /// With "Show in Dock" off, Rebind still has a Dock icon while one of its windows is open and
    /// becomes an accessory app when the last one closes. The Menu Bar item works in both modes.
    static func updateDockIcon(preferred: Bool, closing: NSWindow? = nil) {
        let hasWindow = NSApp.windows.contains {
            $0 !== closing && $0.canBecomeMain && !($0 is NSPanel) && ($0.isVisible || $0.isMiniaturized)
        }
        let policy: NSApplication.ActivationPolicy = preferred || hasWindow ? .regular : .accessory
        guard NSApp.activationPolicy() != policy else { return }
        NSApp.setActivationPolicy(policy)
        // Changing the policy deactivates the app; keep an open window in front.
        if hasWindow { NSApp.activate() }
    }

    static let mainWindow = MainWindowPresenter()
    static let updater = AppUpdater(startsUpdater: !runningTests)

    /// A click on the Dock icon (or opening Rebind again from Finder) while it runs. Rebind
    /// handles it itself: with Show in Dock off it may still be an accessory app, so a window
    /// SwiftUI opened stayed inactive and looked minimized; and a window suppressed at launch
    /// ("Start in the background") is not opened by SwiftUI at all. Become a regular app, then
    /// bring back the existing window or open it.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        Self.mainWindow.show()
        return false
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
    func applicationWillTerminate(_ notification: Notification) { model.stop() }
}
