import AppKit
import SwiftUI
import XCTest
@testable import rebind

/// Resource and native UI checks do not load configuration or start input capture.
@MainActor final class AboutLayoutTests: XCTestCase {
    func testLocalizedAboutAndNoticesFitNativeWindows() async throws {
        for language in AppLanguage.allCases.map(\.rawValue) {
            for appearance in [ColorScheme.light, .dark] {
                try await check(AboutView()
                    .environment(\.locale, Locale(identifier: language))
                    .preferredColorScheme(appearance),
                    sizes: [NSSize(width: 440, height: 448), NSSize(width: 600, height: 560)],
                    appearance: appearance, name: "about-\(language)-\(appearance)")
                for text in [AboutInformation().notices, nil] {
                    try await check(ThirdPartyNoticesView(text: text)
                        .environment(\.locale, Locale(identifier: language))
                        .preferredColorScheme(appearance),
                        sizes: [NSSize(width: 560, height: 400), NSSize(width: 640, height: 520)],
                        appearance: appearance, name: "licenses-\(language)-\(appearance)-\(text == nil)")
                }
            }
        }
    }

    func testLicenseTextIsReadOnlySelectableSearchableAndLocalized() async throws {
        for language in AppLanguage.allCases.map(\.rawValue) {
            let text = try XCTUnwrap(AboutInformation().notices)
            let controller = NSHostingController(rootView: ReadOnlyNoticesText(text: text)
                .environment(\.locale, Locale(identifier: language)))
            let window = NSWindow(contentViewController: controller)
            window.isReleasedWhenClosed = false
            defer { window.close() }
            window.setContentSize(NSSize(width: 560, height: 400))
            try await Task.sleep(for: .milliseconds(100))
            controller.view.layoutSubtreeIfNeeded()
            let view = try XCTUnwrap(findTextView(controller.view))
            XCTAssertFalse(view.isEditable)
            XCTAssertTrue(view.isSelectable)
            XCTAssertTrue(view.usesFindBar)
            XCTAssertEqual(view.string, text)
            var title = LocalizedStringResource.aboutLicenses
            title.locale = Locale(identifier: language)
            XCTAssertEqual(view.accessibilityLabel(), String(localized: title))
            view.setSelectedRange(NSRange(location: 0, length: 6))
            XCTAssertEqual(view.selectedRange(), NSRange(location: 0, length: 6))
            XCTAssertTrue(window.makeFirstResponder(view))
        }
    }

    func testFindCanReopenWithoutEditingOrResettingSelection() async throws {
        let text = try XCTUnwrap(AboutInformation().notices)
        let controller = NSHostingController(rootView: ReadOnlyNoticesText(text: text))
        let window = NSWindow(contentViewController: controller)
        window.isReleasedWhenClosed = false
        defer { window.close() }
        window.setContentSize(NSSize(width: 560, height: 400))
        try await Task.sleep(for: .milliseconds(100))
        let view = try XCTUnwrap(findTextView(controller.view))
        let scroll = try XCTUnwrap(view.enclosingScrollView)
        XCTAssertFalse(scroll.isFindBarVisible)
        controller.rootView = ReadOnlyNoticesText(text: text, findRequest: 1)
        try await Task.sleep(for: .milliseconds(100))
        XCTAssertTrue(scroll.isFindBarVisible)
        view.setSelectedRange(NSRange(location: 0, length: 6))
        controller.rootView = ReadOnlyNoticesText(text: text, findRequest: 1)
        try await Task.sleep(for: .milliseconds(100))
        XCTAssertEqual(view.selectedRange(), NSRange(location: 0, length: 6))
        scroll.isFindBarVisible = false
        controller.rootView = ReadOnlyNoticesText(text: text, findRequest: 2)
        try await Task.sleep(for: .milliseconds(100))
        XCTAssertTrue(scroll.isFindBarVisible)
        XCTAssertTrue(findTextView(controller.view) === view)
        XCTAssertEqual(view.string, text)
        XCTAssertFalse(view.isEditable)
    }

    private func check<V: View>(_ root: V, sizes: [NSSize], appearance: ColorScheme,
                                name: String) async throws {
        let controller = NSHostingController(rootView: root)
        let window = NSWindow(contentViewController: controller)
        window.appearance = NSAppearance(named: appearance == .dark ? .darkAqua : .aqua)
        window.isReleasedWhenClosed = false
        defer { window.close() }
        for size in sizes {
            window.setContentSize(size)
            try await Task.sleep(for: .milliseconds(100))
            controller.view.layoutSubtreeIfNeeded()
            XCTAssertEqual(controller.view.bounds.width, size.width, accuracy: 1, name)
            XCTAssertEqual(controller.view.bounds.height, size.height, accuracy: 1, name)
            if name == "about-ru-light" || name == "licenses-fr-dark-false" {
                let bounds = controller.view.bounds
                let bitmap = try XCTUnwrap(controller.view.bitmapImageRepForCachingDisplay(in: bounds))
                controller.view.cacheDisplay(in: bounds, to: bitmap)
                let png = try XCTUnwrap(bitmap.representation(using: .png, properties: [:]))
                let attachment = XCTAttachment(data: png, uniformTypeIdentifier: "public.png")
                attachment.name = "\(name)-\(Int(size.width))"
                attachment.lifetime = .keepAlways
                add(attachment)
            }
        }
    }

    private func findTextView(_ view: NSView) -> NSTextView? {
        if let text = view as? NSTextView { return text }
        return view.subviews.lazy.compactMap(findTextView).first
    }
}
