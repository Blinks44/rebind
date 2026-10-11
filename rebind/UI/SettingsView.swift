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
                    Text(.settingsDescription).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Picker(.settingsTitle, selection: $selection) {
                    ForEach(SettingsSection.allCases, id: \.self) { section in
                        Text(section.title).tag(section)
                    }
                }.pickerStyle(.segmented)
            }.padding(28)
            switch selection {
            case .general:
                GeneralSettingsView(model: model) { selection = .permissions }
            case .permissions:
                PermissionView(model: model, showsSettingsHeader: false)
            }
        }
        .background { PermissionCanvas() }
        .navigationTitle(.settingsTitle)
        .onAppear { model.loginItem.refresh() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            model.loginItem.refresh()
            model.refreshPermissions()
        }
    }
}
