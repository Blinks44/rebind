import SwiftUI

/// Inset Settings navigation; narrow localized windows retain one complete native menu.
struct SettingsSectionPicker: View {
    @SwiftUI.Binding var selection: SettingsSection
    @Environment(\.isEnabled) private var isEnabled
    @FocusState private var focused: SettingsSection?

    var body: some View {
        ViewThatFits(in: .horizontal) {
            track
            EditorMenuSelector(selection: $selection, title: .settingsTitle,
                choices: SettingsSection.allCases, label: { $0.title }, compact: true)
                .frame(maxWidth: 256)
                .accessibilityIdentifier("settings-section-menu")
        }
    }

    private var track: some View {
        HStack(spacing: 0) {
            ForEach(SettingsSection.allCases, id: \.self) { section in
                Button { selection = section } label: {
                    Text(section.title).font(Theme.calloutStrong)
                        .foregroundStyle(selection == section ? Theme.textPrimary : Theme.textSecondary)
                        .padding(.horizontal, 12)
                        .frame(minWidth: minimumWidth(for: section), minHeight: 28)
                        .contentShape(.capsule)
                        .background {
                            if selection == section { Color.clear.modifier(ControlSurface()) }
                        }
                }
                .buttonStyle(.plain)
                .focused($focused, equals: section)
                .keyboardFocusRing()
            }
        }
        .padding(4)
        .fixedSize(horizontal: true, vertical: false)
        .background(Theme.insetSurface, in: .capsule)
        .overlay { Capsule(style: .circular).strokeBorder(Theme.borderSubtle) }
        .transaction { $0.animation = nil }
        .onKeyPress(.leftArrow) { moveSelection(by: -1) }
        .onKeyPress(.rightArrow) { moveSelection(by: 1) }
        .onChange(of: selection) { if focused != nil { focused = selection } }
        .accessibilityRepresentation {
            Picker(.settingsTitle, selection: $selection) {
                ForEach(SettingsSection.allCases, id: \.self) { Text($0.title).tag($0) }
            }.pickerStyle(.radioGroup)
        }
        .accessibilityIdentifier("settings-section-track")
    }

    private func minimumWidth(for section: SettingsSection) -> CGFloat {
        switch section {
        case .general, .input: 96
        case .permissions: 132
        case .language, .advanced: 112
        }
    }

    private func moveSelection(by offset: Int) -> KeyPress.Result {
        guard isEnabled else { return .ignored }
        let sections = SettingsSection.allCases
        guard let index = sections.firstIndex(of: focused ?? selection) else { return .ignored }
        let next = min(max(index + offset, sections.startIndex), sections.count - 1)
        selection = sections[next]
        focused = sections[next]
        return .handled
    }
}
