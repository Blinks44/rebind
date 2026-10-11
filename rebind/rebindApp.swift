import AppKit
import SwiftUI

@main
struct rebindApp: App {
    @NSApplicationDelegateAdaptor(RebindAppDelegate.self) private var delegate
    @State private var settingsSection: SettingsSection = .general

    var body: some Scene {
        Window(.rebindWindowTitle, id: "main") { ContentView(model: delegate.model) }
            .defaultSize(width: 1040, height: 640)
        Settings {
            SettingsView(model: delegate.model, selection: $settingsSection)
                .frame(minWidth: 600, idealWidth: 760, minHeight: 480, idealHeight: 600)
        }
        MenuBarExtra("Rebind", image: "RebindMenuBar") { RebindMenu(model: delegate.model) }
    }
}

final class RebindAppDelegate: NSObject, NSApplicationDelegate {
    private static var runningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
            || NSClassFromString("XCTestCase") != nil
    }
    let model = AppModel(loadConfiguration: !RebindAppDelegate.runningTests)

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard !Self.runningTests else { return }
        model.start()
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
    func applicationWillTerminate(_ notification: Notification) { model.stop() }
}

private struct RebindMenu: View {
    let model: AppModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Text(model.statusText)
        Button(.openRebind) { openWindow(id: "main"); NSApp.activate() }
        Menu(.profileTitle) {
            ProfilePicker(model: model).pickerStyle(.inline)
        }.disabled(model.storageLocked)
        Button(model.configuration.isEnabled ? LocalizedStringResource.pauseBindings : .resumeBindings) {
            model.setEnabled(!model.configuration.isEnabled)
        }.disabled(model.storageLocked && !model.configuration.isEnabled)
        SettingsLink { Text(.settingsTitle) }
        Divider()
        Button(.quitRebind) { NSApp.terminate(nil) }.keyboardShortcut("q")
    }
}
