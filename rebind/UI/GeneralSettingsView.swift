import SwiftUI

/// General controls reuse persisted pause and actual ServiceManagement state.
struct GeneralSettingsView: View {
    let model: AppModel
    var openPermissions: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(model.generalRuntime.title).font(.headline).accessibilityAddTraits(.isHeader)
                if model.generalRuntime != .starting {
                    Text(model.generalRuntime.description).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if model.generalRuntime == .missingAccess {
                    Button(.permissionsTitle, action: openPermissions).buttonStyle(.bordered)
                } else if model.generalRuntime == .engineError {
                    Button(.tryAgain) { model.retryRemapping() }.buttonStyle(.bordered)
                }
            }.padding(.horizontal, 28)
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    PermissionCard {
                        Toggle(isOn: remappingEnabled) {
                            settingLabel(.enableRemapping, description: .enableRemappingDescription)
                        }
                        .toggleStyle(.switch)
                        .disabled(model.storageLocked && !model.configuration.isEnabled)
                    }
                    LoginItemSettingsRow(model: model.loginItem)
                    PermissionCard {
                        settingLabel(.backgroundTitle, description: .backgroundDescription)
                    }
                    Text(.quitGuidance).font(.callout).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    if let error = model.error {
                        Text(error).foregroundStyle(.red).fixedSize(horizontal: false, vertical: true)
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 28).padding(.bottom, 28)
            }
        }
    }

    private var remappingEnabled: SwiftUI.Binding<Bool> {
        // Saving can fail and pause must cancel immediately. A draft/onChange
        // binding would temporarily show a preference the model did not accept.
        SwiftUI.Binding(get: { model.configuration.isEnabled }, set: { model.setEnabled($0) })
    }

    private func settingLabel(_ title: LocalizedStringResource,
                              description: LocalizedStringResource) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
            Text(description).font(.callout).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
