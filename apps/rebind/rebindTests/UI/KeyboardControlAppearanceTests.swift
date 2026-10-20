import AppKit
import SwiftUI
import XCTest
@testable import rebind

/// Local control specimens, without AppModel, storage or input capture.
@MainActor final class KeyboardControlAppearanceTests: XCTestCase {
    func testSharedControlAppearanceInBothThemes() async throws {
        for scheme in [ColorScheme.light, .dark] {
            let controller = NSHostingController(rootView: Specimen().preferredColorScheme(scheme))
            let window = NSWindow(contentViewController: controller)
            window.isReleasedWhenClosed = false
            defer { window.close() }
            window.setContentSize(NSSize(width: 740, height: 540))
            try await Task.sleep(for: .milliseconds(100))
            controller.view.layoutSubtreeIfNeeded()
            let bitmap = try XCTUnwrap(controller.view.bitmapImageRepForCachingDisplay(in: controller.view.bounds))
            controller.view.cacheDisplay(in: controller.view.bounds, to: bitmap)
            let png = try XCTUnwrap(bitmap.representation(using: .png, properties: [:]))
            let attachment = XCTAttachment(data: png, uniformTypeIdentifier: "public.png")
            attachment.name = "keyboard-controls-\(scheme)"
            attachment.lifetime = .keepAlways
            add(attachment)
            XCTAssertEqual(controller.view.bounds.width, 740, accuracy: 1)
        }
    }

    struct Specimen: View {
        @State private var enabled = true
        @State private var section: SettingsSection = .general
        var body: some View {
            VStack(alignment: .leading, spacing: 20) {
                Text("Shared controls").font(Theme.title)
                HStack(spacing: 30) {
                    Text("Options")
                    OptionsMenu(label: .profileOptions) { Button("Fixture item") {} }
                    OptionsMenu(label: .profileOptions) { Button("Fixture item") {} }.disabled(true)
                    Text("Native plain reference")
                    Menu { Button("Fixture item") {} } label: {
                        Image(systemName: "ellipsis").font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Theme.iconSecondary).frame(width: 28, height: 28)
                    }.menuStyle(.button).buttonStyle(.plain).menuIndicator(.hidden).fixedSize()
                }
                HStack(spacing: 24) {
                    Toggle("Enabled", isOn: $enabled).toggleStyle(ThemeSwitchStyle())
                    CircleIconButton(symbol: "plus", action: {})
                    Button {} label: {
                        Image(systemName: "xmark.circle.fill").font(.system(size: 15))
                            .foregroundStyle(Theme.iconTertiary).frame(width: 28, height: 28)
                    }.buttonStyle(KeyboardButtonStyle(KeyboardPlainAppearance())).keyboardFocusRing(Circle())
                }
                HStack {
                    Button("Primary") {}.primaryButton()
                    Button("Secondary") {}.secondaryButton()
                    Button("Destructive") {}.destructiveButton()
                    Button("Disabled") {}.primaryButton().disabled(true)
                }
                SettingsSectionPicker(selection: $section)
                MenuSelector(selection: $section, title: .settingsTitle, choices: SettingsSection.allCases, label: { $0.title })
                Banner(severity: .information, title: .touchNativeGestureTitle, message: .magicMouseOneFingerConflict,
                       dismiss: {})
                Spacer(minLength: 0)
            }.padding(28).frame(width: 740, height: 540).background { ThemeCanvas() }
        }
    }
}
