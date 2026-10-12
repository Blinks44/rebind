import SwiftUI

/// Settings tabs; narrow localized windows fall back to one complete native menu.
struct SettingsSectionPicker: View {
    @SwiftUI.Binding var selection: SettingsSection

    var body: some View {
        ViewThatFits(in: .horizontal) {
            SegmentedPicker(selection: $selection, title: .settingsTitle, options: SettingsSection.allCases,
                            label: { $0.title })
                .fixedSize(horizontal: true, vertical: false)
                .accessibilityIdentifier("settings-section-track")
            MenuSelector(selection: $selection, title: .settingsTitle,
                choices: SettingsSection.allCases, label: { $0.title }, compact: true)
                .frame(maxWidth: 256)
                .accessibilityIdentifier("settings-section-menu")
        }
    }
}
