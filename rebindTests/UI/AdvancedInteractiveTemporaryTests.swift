import AppKit
import SwiftUI
import XCTest
@testable import rebind

@MainActor final class AdvancedInteractiveTemporaryTests: XCTestCase {
    func testIsolatedInteractiveAdvanced() async throws {
        let directory = URL(fileURLWithPath: "/private/tmp/RebindAdvancedInteractive")
        let marker = URL(fileURLWithPath: "/private/tmp/rebind-advanced-interactive-finish")
        try? FileManager.default.removeItem(at: directory)
        try? FileManager.default.removeItem(at: marker)
        let store = ConfigurationStore(url: directory.appending(path: "configuration.json"))
        var configuration = Configuration()
        configuration.hasCompletedSetup = true
        try configuration.createProfile(name: "Test profile")
        try store.save(configuration)
        let bytes = try Data(contentsOf: store.url)
        let model = AppModel(store: store, readPermissions: { InputPermissions() },
            loginItem: LoginItemModel(service: LoginItemServiceStub()), preferredLanguages: ["en"])
        AppLocalization.configureAtLaunch(.en)
        let controller = NSHostingController(rootView: ContentView(model: model, initialDestination: .settings(.advanced))
            .environment(\.locale, Locale(identifier: "en")).preferredColorScheme(.dark))
        let window = NSWindow(contentViewController: controller)
        window.title = "Rebind Advanced isolated verification"
        window.appearance = NSAppearance(named: .darkAqua)
        window.isReleasedWhenClosed = false
        window.setContentSize(NSSize(width: 1040, height: 640))
        window.makeKeyAndOrderFront(nil)
        NSApp.activate()
        defer { window.close() }
        let deadline = Date().addingTimeInterval(240)
        while Date() < deadline && !FileManager.default.fileExists(atPath: marker.path) {
            try await Task.sleep(for: .seconds(1))
        }
        XCTAssertEqual(try Data(contentsOf: store.url), bytes)
        XCTAssertEqual(model.configurationReplacementRevision, 0)
    }
}
