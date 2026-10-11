import AppKit
import SwiftUI
import XCTest
@testable import rebind

/// Native presentation fixtures use temporary storage and never start input capture.
@MainActor final class TrackpadEditorLayoutTests: XCTestCase {
    func testPresetsAndRecoveryStatesFitLocalizedNativeEditors() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: "TrackpadEditorLayout-\(UUID())")
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = ConfigurationStore(url: directory.appending(path: "configuration.json"))
        let shortcut = RebindAction.shortcut(KeyboardShortcut(keyCode: 13, modifiers: .command))
        for language in ["en", "ru", "de", "fr"] {
            for appearance in [ColorScheme.light, .dark] {
                for scenario in 0..<10 {
                    let preset = TrackpadPreset.allCases[scenario % 4]
                    var existing: rebind.Binding? = rebind.Binding(scope: .builtInTrackpad,
                        trigger: preset.gesture.trigger, modifiers: [], action: shortcut)
                    if scenario == 4 { existing = nil }
                    if scenario == 9 { existing?.isEnabled = false }
                    let duplicate = scenario == 5
                    var stored = existing.map { [$0] } ?? []
                    if duplicate { stored[0].id = UUID() }
                    var configuration = Configuration(bindings: stored)
                    configuration.hasCompletedSetup = true
                    try store.save(configuration)
                    let model = AppModel(store: store,
                        readPermissions: { InputPermissions(accessibility: scenario != 6, posting: scenario != 6) })
                    if scenario == 7 { model.recording = RecordingRequest(target: .output) }
                    let controller = NSHostingController(rootView: BindingEditor(model: model,
                        scope: .builtInTrackpad, existing: existing)
                        .environment(\.locale, Locale(identifier: language))
                        .preferredColorScheme(appearance))
                    let window = NSWindow(contentViewController: controller)
                    window.isReleasedWhenClosed = false
                    window.appearance = NSAppearance(named: appearance == .light ? .aqua : .darkAqua)
                    for height in [488.0, 640.0] {
                        window.setContentSize(NSSize(width: 512, height: height))
                        try await Task.sleep(for: .milliseconds(80))
                        if scenario == 8 {
                            model.error = .storageWriteFailed
                            try await Task.sleep(for: .milliseconds(60))
                            XCTAssertEqual(model.error, .storageWriteFailed)
                        }
                        controller.view.layoutSubtreeIfNeeded()
                        let scroll = try XCTUnwrap(findScroll(controller.view))
                        let viewport = controller.view.bounds
                        let scrollFrame = scroll.convert(scroll.bounds, to: controller.view)
                        let context = "\(language), \(appearance), scenario=\(scenario), \(height)"
                        XCTAssertEqual(viewport.width, 512, accuracy: 1, context)
                        XCTAssertEqual(viewport.height, height, accuracy: 1, context)
                        XCTAssertGreaterThan(scrollFrame.height, 0, context)
                        XCTAssertGreaterThanOrEqual(scrollFrame.minY, viewport.minY - 1, context)
                        XCTAssertLessThanOrEqual(scrollFrame.maxY, viewport.maxY + 1, context)
                        XCTAssertLessThanOrEqual(scroll.documentView?.frame.width ?? 0,
                                                scroll.contentView.bounds.width + 1, context)
                        if height == 640 && (scenario == 0 || scenario == 2 || scenario >= 5) {
                            try attach(controller.view, name: "trackpad-\(language)-\(appearance)-\(scenario)")
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

    private func attach(_ view: NSView, name: String) throws {
        let bitmap = try XCTUnwrap(view.bitmapImageRepForCachingDisplay(in: view.bounds))
        view.cacheDisplay(in: view.bounds, to: bitmap)
        let png = try XCTUnwrap(bitmap.representation(using: .png, properties: [:]))
        let attachment = XCTAttachment(data: png, uniformTypeIdentifier: "public.png")
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
