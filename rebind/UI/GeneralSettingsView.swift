import SwiftUI

/// General controls reuse persisted pause and actual ServiceManagement state.
struct GeneralSettingsView: View {
    let model: AppModel
    var openPermissions: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Expanded feedback belongs in scrolling content so localized copy
                // cannot inflate the NavigationSplitView's minimum height.
                runtimeStatus
                PermissionCard {
                    Toggle(isOn: remappingEnabled) {
                        settingLabel(.enableRemapping, description: .enableRemappingDescription)
                    }
                    .toggleStyle(ThemeSwitchStyle())
                    .accessibilityLabel(Text(.enableRemapping))
                    .accessibilityHint(Text(.enableRemappingDescription))
                    .disabled(model.storageLocked && !model.configuration.isEnabled)
                }
                LoginItemSettingsRow(model: model.loginItem)
                PermissionCard {
                    settingLabel(.backgroundTitle, description: .backgroundDescription)
                }
                Text(.quitGuidance).font(Theme.callout).foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                if let error = model.error, model.generalRuntime != .storageLocked {
                    EditorFeedback(severity: .error, title: error)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(.leading, 32).padding(.trailing, 40).padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    @ViewBuilder private var runtimeStatus: some View {
        switch model.generalRuntime {
        case .missingAccess:
            EditorFeedback(severity: .warning, title: model.generalRuntime.title,
                           message: model.generalRuntime.description) {
                Button(.permissionsTitle, action: openPermissions)
            }
        case .engineError:
            EditorFeedback(severity: .error, title: model.generalRuntime.title,
                           message: model.generalRuntime.description) {
                Button(.tryAgain, action: model.retryRemapping)
            }
        case .storageLocked:
            EditorFeedback(severity: .warning, title: model.generalRuntime.title,
                           message: model.generalRuntime.description)
        case .active, .paused, .starting, .secureInput, .suspended:
            VStack(alignment: .leading, spacing: 8) {
                Text(model.generalRuntime.title).font(Theme.headline).accessibilityAddTraits(.isHeader)
                if model.generalRuntime != .starting {
                    Text(model.generalRuntime.description).foregroundStyle(Theme.textSecondary)
                }
            }.frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var remappingEnabled: SwiftUI.Binding<Bool> {
        // Saving can fail and pause must cancel immediately. A draft/onChange
        // binding would temporarily show a preference the model did not accept.
        SwiftUI.Binding(get: { model.configuration.isEnabled }, set: { model.setEnabled($0) })
    }

    private func settingLabel(_ title: LocalizedStringResource,
                              description: LocalizedStringResource) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(Theme.bodyStrong).foregroundStyle(Theme.textPrimary)
            Text(description).font(Theme.callout).foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
