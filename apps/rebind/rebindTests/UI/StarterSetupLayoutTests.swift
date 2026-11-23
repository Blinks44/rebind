import AppKit
import SwiftUI
import XCTest

@testable import rebind

/// Temporary configurations only; the engine is never started and no action is executed.
@MainActor final class StarterSetupLayoutTests: XCTestCase {
    func testCatalogPreviewsAndConflictsFitAllLocalesAndBothAppearances() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: "StarterLayout-\(UUID())")
        defer { try? FileManager.default.removeItem(at: directory) }
        let originalLanguage = AppLocalization.language
        defer { AppLocalization.configureAtLaunch(originalLanguage) }
        for language in AppLanguage.allCases {
            AppLocalization.configureAtLaunch(language)
            for appearance in [ColorScheme.light, .dark] {
                // Catalog, all bundles, conflict, and missing target states.
                for scenario in 0..<7 {
                    let store = ConfigurationStore(url: directory.appending(path: "config.json"))
                    var configuration = Configuration(isEnabled: true)
                    if scenario == 5 {
                        configuration.bindings = StarterSetup.windows.entries(safari: nil).prefix(2).map(\.binding)
                        configuration.bindings[0].isEnabled = false
                        configuration.bindings[1].action = .dock(.missionControl)
                    }
                    try store.save(configuration)
                    let model = AppModel(store: store, readPermissions: { InputPermissions(accessibility: false, posting: false) })
                    let setup: StarterSetup? =
                        scenario == 0 ? nil : (scenario >= 5 ? (scenario == 5 ? .windows : .browser) : StarterSetup.allCases[scenario - 1])
                    let safari =
                        scenario == 6
                        ? nil : ApplicationTarget(url: URL(filePath: "/Applications/Safari.app"), bundleIdentifier: "com.apple.Safari")
                    let controller = NSHostingController(
                        rootView: StarterSetupsView(
                            model: model, initialSetup: setup, initialDestinationID: scenario == 5 ? configuration.selectedProfileID : nil,
                            safari: safari
                        )
                        .environment(\.locale, language.locale).preferredColorScheme(appearance))
                    let window = NSWindow(contentViewController: controller)
                    window.isReleasedWhenClosed = false
                    window.appearance = NSAppearance(named: appearance == .light ? .aqua : .darkAqua)
                    for height in [480.0, 600.0] {
                        window.setContentSize(NSSize(width: 680, height: height))
                        try await Task.sleep(for: .milliseconds(50))
                        controller.view.layoutSubtreeIfNeeded()
                        let context = "\(language), \(appearance), \(scenario), \(height)"
                        XCTAssertEqual(controller.view.bounds.width, 680, accuracy: 1, context)
                        XCTAssertEqual(controller.view.bounds.height, height, accuracy: 1, context)
                        let scroll = try XCTUnwrap(findScroll(controller.view), context)
                        let region = scroll.convert(scroll.bounds, to: controller.view)
                        XCTAssertGreaterThan(region.height, 60, context)
                        XCTAssertGreaterThanOrEqual(region.minY, -1, context)
                        XCTAssertLessThanOrEqual(region.maxY, height + 1, context)
                        XCTAssertLessThanOrEqual(scroll.documentView?.frame.width ?? 0, scroll.contentView.bounds.width + 1, context)
                        XCTAssertEqual(model.configuration, configuration, context)
                        XCTAssertTrue(model.mailbox.state.withLock { $0.pending.isEmpty }, context)
                        if height == 600
                            && ((language == .en && appearance == .light && [0, 2, 5].contains(scenario))
                                || (language == .ru && appearance == .dark && scenario == 3)
                                || (language == .de && appearance == .light && scenario == 1)
                                || (language == .fr && appearance == .light && scenario == 4))
                        {
                            let bitmap = try XCTUnwrap(controller.view.bitmapImageRepForCachingDisplay(in: controller.view.bounds))
                            controller.view.cacheDisplay(in: controller.view.bounds, to: bitmap)
                            let png = try XCTUnwrap(bitmap.representation(using: .png, properties: [:]))
                            let attachment = XCTAttachment(data: png, uniformTypeIdentifier: "public.png")
                            attachment.name = "starter-\(language)-\(appearance)-\(scenario)"
                            attachment.lifetime = .keepAlways
                            add(attachment)
                        }
                    }
                    window.close()
                }
            }
        }
    }

    private func findScroll(_ view: NSView) -> NSScrollView? {
        if let scroll = view as? NSScrollView { return scroll }
        return view.subviews.lazy.compactMap(findScroll).first
    }
}
