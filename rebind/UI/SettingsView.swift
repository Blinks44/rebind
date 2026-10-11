import SwiftUI

/// Shared settings shell for the main window and the system Settings command.
struct SettingsView: View {
    let model: AppModel
    @SwiftUI.Binding var selection: SettingsSection

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(.settingsTitle).font(.title.bold()).accessibilityAddTraits(.isHeader)
                    // Keep header text compressible during split-view minimum-size measurement.
                    // Vertical fixedSize here can expand and displace the entire main window.
                    Text(.settingsDescription).foregroundStyle(.secondary)
                }
                ViewThatFits(in: .horizontal) {
                    sectionPicker.pickerStyle(.segmented)
                    sectionPicker.pickerStyle(.menu)
                }
            }.padding(28)
            switch selection {
            case .general:
                GeneralSettingsView(model: model) { selection = .permissions }
            case .permissions:
                PermissionView(model: model, showsSettingsHeader: false)
            case .input:
                InputSettingsView()
            case .language:
                LanguageSettingsView(model: model)
            case .advanced:
                AdvancedSettingsView(model: model)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background { PermissionCanvas() }
        .navigationTitle(.settingsTitle)
        .onAppear { model.loginItem.refresh() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            model.loginItem.refresh()
            model.refreshPermissions()
        }
    }

    private var sectionPicker: some View {
        Picker(.settingsTitle, selection: $selection) {
            ForEach(SettingsSection.allCases, id: \.self) { section in
                Text(section.title).tag(section)
            }
        }.labelsHidden()
    }
}
