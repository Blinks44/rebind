import AppKit
import SwiftUI

@main
struct rebindApp: App {
    @NSApplicationDelegateAdaptor(RebindAppDelegate.self) private var delegate

    private var opensWindowAtLaunch: Bool {
        let configuration = delegate.model.configuration
        return configuration.opensWindowAtLaunch || (!configuration.showsDockIcon && !configuration.showsMenuBarIcon)
    }

    var body: some Scene {
        Window(.rebindWindowTitle, id: "main") {
            ContentView(model: delegate.model).environment(\.locale, delegate.model.activeLanguage.locale)
                .background { ActiveSpaceWindow() }
                .background { MainWindowOpener() }
        }
            .windowToolbarStyle(.unified(showsTitle: false))
            .defaultSize(width: 1080, height: 720)
            // "Start in the background" keeps the window closed at launch, including at login, unless
            // Rebind shows neither a Dock nor a Menu Bar icon: then the window is its only way in.
            .defaultLaunchBehavior(opensWindowAtLaunch ? .automatic : .suppressed)
            .restorationBehavior(.disabled)
            .commands {
                CommandGroup(replacing: .appInfo) {
                    AboutCommand(language: delegate.model.activeLanguage)
                }
            }
        Window(.aboutTitle, id: "about") {
            AboutView().environment(\.locale, delegate.model.activeLanguage.locale)
                .background { ActiveSpaceWindow() }
        }
        .defaultSize(width: 440, height: 448)
        .windowResizability(.contentSize)
        .defaultLaunchBehavior(.suppressed)
        Settings {
            SettingsView(model: delegate.model, selection: Bindable(delegate.model).settingsSection)
                .frame(minWidth: 600, idealWidth: 760, minHeight: 480, idealHeight: 600)
                .background { ThemeCanvas() }
                .background { ActiveSpaceWindow() }
                .environment(\.locale, delegate.model.activeLanguage.locale)
        }
    }
}

final class RebindAppDelegate: NSObject, NSApplicationDelegate {
    private static var runningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
            || NSClassFromString("XCTestCase") != nil
    }
    let model: AppModel
    private var menuBar: MenuBarController?
    private var terminationSignal: DispatchSourceSignal?

    override init() {
        let runningTests = Self.runningTests
        model = AppModel(loadConfiguration: !runningTests, languagePreferenceSaved: { preference in
            if !runningTests { AppLanguageDefaults(defaults: .standard).apply(preference) }
        })
        super.init()
        if !runningTests {
            AppLocalization.configureAtLaunch(model.activeLanguage)
            if !model.storageLocked {
                AppLanguageDefaults(defaults: .standard).apply(model.configuration.languagePreference)
            }
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard !Self.runningTests else { return }
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
        model.start()
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

    /// Opens a window from the Menu Bar item and brings Rebind to the front. As an accessory app,
    /// Rebind first becomes a regular app: switching the policy later, when the window becomes main,
    /// deactivates the app after the click's activation and the window can stay behind other apps.
    /// The rest waits one run-loop turn: the policy change and the closing menu settle first. An
    /// activation requested in the same turn can be dropped, and a window that appears while Rebind
    /// is inactive opens behind other apps or, with Stage Manager, in the strip at the side.
    static func showWindow(_ open: @escaping () -> Void) {
        if NSApp.activationPolicy() != .regular { NSApp.setActivationPolicy(.regular) }
        DispatchQueue.main.async {
            NSApp.activate()
            open()
            // The window SwiftUI just opened or reused is the frontmost one; make sure it leads.
            DispatchQueue.main.async {
                NSApp.orderedWindows.first { $0.canBecomeMain && $0.isVisible && !($0 is NSPanel) }?
                    .makeKeyAndOrderFront(nil)
                NSApp.activate()
            }
        }
    }

    /// Opens the main window from outside a view (set by `MainWindowOpener`).
    static var openMainWindow: (() -> Void)?

    /// A click on the Dock icon (or opening Rebind again from Finder) while it runs. Rebind
    /// handles it itself: with Show in Dock off it may still be an accessory app, so a window
    /// SwiftUI opened stayed inactive and looked minimized; and a window suppressed at launch
    /// ("Start in the background") is not opened by SwiftUI at all. Become a regular app, then
    /// bring back the existing window or open it.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        let existing = NSApp.windows.first {
            $0.canBecomeMain && !($0 is NSPanel) && ($0.isVisible || $0.isMiniaturized)
        }
        Self.showWindow {
            if let existing {
                if existing.isMiniaturized { existing.deminiaturize(nil) }
                existing.makeKeyAndOrderFront(nil)
            } else {
                Self.openMainWindow?()
            }
        }
        return false
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
    func applicationWillTerminate(_ notification: Notification) { model.stop() }
}

/// Hands the scene's `openWindow` action to the app delegate, which has no SwiftUI environment.
private struct MainWindowOpener: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Color.clear.frame(width: 0, height: 0).accessibilityHidden(true)
            .onAppear { RebindAppDelegate.openMainWindow = { openWindow(id: "main") } }
    }
}
