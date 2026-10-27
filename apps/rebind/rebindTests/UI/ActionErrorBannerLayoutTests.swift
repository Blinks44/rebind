import AppKit
import SwiftUI
import XCTest
@testable import rebind

/// Run in the sequential native UI phase: this fixture changes launch-time localization.
/// Uses disposable storage and never starts discovery or input capture.
@MainActor final class ActionErrorBannerLayoutTests: XCTestCase {
    func testLocalizedErrorFitsMainWindowAndDismissalRestoresSpace() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: "RebindErrorLayout-\(UUID())")
        defer { try? FileManager.default.removeItem(at: directory) }
        let previousLanguage = AppLocalization.language
        defer { AppLocalization.configureAtLaunch(previousLanguage) }
        for language in AppLanguage.allCases {
            AppLocalization.configureAtLaunch(language)
            var configuration = Configuration(bindings: (3..<15).map {
                rebind.Binding(scope: .allMice, trigger: .mouseButton(UInt32($0)), modifiers: [], action: .windowLayout(.fill))
            })
            configuration.hasCompletedSetup = true
            let store = ConfigurationStore(url: directory.appending(path: "\(language.rawValue)/configuration.json"))
            try store.save(configuration)
            let model = AppModel(store: store,
                readPermissions: { InputPermissions(accessibility: true, posting: true) },
                companionApps: CompanionAppMonitor(executablePaths: { [] }, initiallyRunning: []))
            model.mailbox.state.withLock { $0.status = .active }
            model.refresh()
            for appearance in [ColorScheme.light, .dark] {
                let controller = NSHostingController(rootView: ContentView(model: model, initialDestination: .input(.allMice))
                    .environment(\.locale, language.locale).preferredColorScheme(appearance))
                let window = NSWindow(contentViewController: controller)
                window.styleMask.insert(.fullSizeContentView)
                window.titleVisibility = .hidden
                window.titlebarAppearsTransparent = true
                window.appearance = NSAppearance(named: appearance == .dark ? .darkAqua : .aqua)
                window.isReleasedWhenClosed = false
                defer { window.close() }
                for size in [NSSize(width: 880, height: 600), NSSize(width: 1080, height: 720)] {
                    window.setFrame(NSRect(origin: .zero, size: size), display: false)
                    model.refreshActionError(.windowLayoutFailed)
                    try await Task.sleep(for: .milliseconds(80))
                    controller.view.layoutSubtreeIfNeeded()
                    let root = controller.view
                    XCTAssertEqual(root.bounds.width, size.width, accuracy: 1)
                    XCTAssertEqual(root.bounds.height, size.height, accuracy: 1)
                    let scrolls = descendants(root).compactMap { $0 as? NSScrollView }
                    let rules = try XCTUnwrap(scrolls.max { $0.frame.width < $1.frame.width })
                    let errorBounds = rules.convert(rules.bounds, to: root)
                    XCTAssertGreaterThan(errorBounds.height, 0)
                    XCTAssertGreaterThanOrEqual(errorBounds.minY, root.bounds.minY - 1)
                    XCTAssertLessThanOrEqual(errorBounds.maxY, root.bounds.maxY + 1)
                    if size.width == 1080 && (language == .en || language == .ru) {
                        let bitmap = try XCTUnwrap(root.bitmapImageRepForCachingDisplay(in: root.bounds))
                        root.cacheDisplay(in: root.bounds, to: bitmap)
                        let png = try XCTUnwrap(bitmap.representation(using: .png, properties: [:]))
                        try png.write(to: URL(filePath: "/private/tmp/rebind-error-\(language.rawValue)-\(appearance).png"))
                    }
                    model.error = nil
                    try await Task.sleep(for: .milliseconds(80))
                    root.layoutSubtreeIfNeeded()
                    let clearedBounds = rules.convert(rules.bounds, to: root)
                    XCTAssertNil(model.error)
                    XCTAssertGreaterThan(clearedBounds.height, errorBounds.height)
                }
            }
        }
    }

    private func descendants(_ view: NSView) -> [NSView] {
        view.subviews.flatMap { [$0] + descendants($0) }
    }
}
