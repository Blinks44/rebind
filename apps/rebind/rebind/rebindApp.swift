import AppKit
import SwiftUI

@main
struct rebindApp: App {
    @NSApplicationDelegateAdaptor(RebindAppDelegate.self) private var delegate
    @State private var settingsSection: SettingsSection = .general

    private var menuBarIconShown: SwiftUI.Binding<Bool> {
        SwiftUI.Binding(get: { delegate.model.configuration.showsMenuBarIcon },
                set: { delegate.model.setPresencePreference(\.showsMenuBarIcon, to: $0) })
    }

    var body: some Scene {
        Window(.rebindWindowTitle, id: "main") {
            ContentView(model: delegate.model).environment(\.locale, delegate.model.activeLanguage.locale)
                .background { ActiveSpaceWindow() }
        }
            .windowToolbarStyle(.unified(showsTitle: false))
            .defaultSize(width: 1080, height: 720)
            // "Start in the background" keeps the window closed at launch, including at login.
            .defaultLaunchBehavior(delegate.model.configuration.opensWindowAtLaunch ? .automatic : .suppressed)
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
            SettingsView(model: delegate.model, selection: $settingsSection)
                .frame(minWidth: 600, idealWidth: 760, minHeight: 480, idealHeight: 600)
                .background { ThemeCanvas() }
                .background { ActiveSpaceWindow() }
                .environment(\.locale, delegate.model.activeLanguage.locale)
        }
        MenuBarExtra("Rebind", image: delegate.model.rulesAreRunning ? "RebindMenuBar" : "RebindMenuBarPaused",
                     isInserted: menuBarIconShown) {
            RebindMenu(model: delegate.model).environment(\.locale, delegate.model.activeLanguage.locale)
        }
    }
}

final class RebindAppDelegate: NSObject, NSApplicationDelegate {
    private static var runningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
            || NSClassFromString("XCTestCase") != nil
    }
    let model: AppModel

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
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(windowDidOpen), name: NSWindow.didBecomeMainNotification, object: nil)
        center.addObserver(self, selector: #selector(windowWillClose), name: NSWindow.willCloseNotification, object: nil)
        // The first window is created after launch finishes; decide once it exists.
        DispatchQueue.main.async { [model] in Self.updateDockIcon(preferred: model.configuration.showsDockIcon) }
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
    static func showWindow(_ open: () -> Void) {
        if NSApp.activationPolicy() != .regular { NSApp.setActivationPolicy(.regular) }
        open()
        NSApp.activate()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
    func applicationWillTerminate(_ notification: Notification) { model.stop() }
}

private struct RebindMenu: View {
    let model: AppModel
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Text(model.statusText)
        // The window may be closed when an action fails; the menu is where it can still be seen.
        if let error = model.error { Text(error) }
        Button(.openRebind) { RebindAppDelegate.showWindow { openWindow(id: "main") } }
        Menu(.profileTitle) {
            ProfilePicker(model: model).pickerStyle(.inline)
        }.disabled(model.storageLocked)
        Button(model.configuration.isEnabled ? LocalizedStringResource.pauseBindings : .resumeBindings) {
            model.setEnabled(!model.configuration.isEnabled)
        }.disabled(model.storageLocked && !model.configuration.isEnabled)
        Button(.settingsTitle) { RebindAppDelegate.showWindow { openSettings() } }
        Divider()
        Button(.quitRebind) { NSApp.terminate(nil) }.keyboardShortcut("q")
    }
}
