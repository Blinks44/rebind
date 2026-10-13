import SwiftUI

/// Shared settings shell for the main window and the system Settings command.
struct SettingsView: View {
    let model: AppModel
    @SwiftUI.Binding var selection: SettingsSection

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(.settingsTitle).font(Theme.largeTitle).accessibilityAddTraits(.isHeader)
                    // Keep header text compressible during split-view minimum-size measurement.
                    // Vertical fixedSize here can expand and displace the entire main window.
                    Text(.settingsDescription).font(Theme.body).foregroundStyle(Theme.textSecondary)
                }
                SettingsSectionPicker(selection: $selection)
            }.detailMargins().padding(.top, 28).padding(.bottom, 24)
            switch selection {
            case .general:
                GeneralSettingsView(model: model) { selection = .permissions }
            case .permissions:
                PermissionView(model: model)
            case .input:
                InputSettingsView(model: model)
            case .language:
                LanguageSettingsView(model: model)
            case .advanced:
                AdvancedSettingsView(model: model)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .navigationTitle(.settingsTitle)
        .onAppear { model.loginItem.refresh() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            model.loginItem.refresh()
            model.refreshPermissions()
        }
    }
}
