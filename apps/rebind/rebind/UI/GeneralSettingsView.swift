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
                Card {
                    Toggle(isOn: remappingEnabled) {
                        settingLabel(.enableRemapping, description: .enableRemappingDescription)
                    }
                    .toggleStyle(ThemeSwitchStyle())
                    .accessibilityLabel(Text(.enableRemapping))
                    .accessibilityHint(Text(.enableRemappingDescription))
                    .disabled(model.storageLocked && !model.configuration.isEnabled)
                }
                LoginItemSettingsRow(model: model.loginItem)
                presenceToggle(.showInDock, description: .showInDockDescription, \.showsDockIcon) {
                    RebindAppDelegate.updateDockIcon(preferred: $0)
                }
                presenceToggle(.showInMenuBar, description: .showInMenuBarDescription, \.showsMenuBarIcon)
                if !model.configuration.showsDockIcon && !model.configuration.showsMenuBarIcon {
                    Banner(severity: .information, title: .hiddenEverywhereTitle, message: .hiddenEverywhereDescription)
                }
                Toggle(isOn: SwiftUI.Binding(get: { !model.configuration.opensWindowAtLaunch },
                                             set: { model.setPresencePreference(\.opensWindowAtLaunch, to: !$0) })) {
                    settingLabel(.startInBackground, description: .startInBackgroundDescription)
                }
                .toggleStyle(ThemeSwitchStyle()).disabled(model.storageLocked).modifier(CardRow())
                Text(.quitGuidance).font(Theme.callout).foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                if let error = model.error, model.generalRuntime != .storageLocked {
                    Banner(severity: .error, title: error)
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
            Banner(severity: .warning, title: model.generalRuntime.title,
                           message: model.generalRuntime.description) {
                Button(.permissionsTitle, action: openPermissions).secondaryButton()
            }
        case .engineError:
            Banner(severity: .error, title: model.generalRuntime.title,
                           message: model.generalRuntime.description) {
                Button(.tryAgain, action: model.retryRemapping).secondaryButton()
            }
        case .storageLocked:
            Banner(severity: .warning, title: model.generalRuntime.title,
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

    private func presenceToggle(_ title: LocalizedStringResource, description: LocalizedStringResource,
                                _ keyPath: WritableKeyPath<Configuration, Bool>,
                                applied: @escaping (Bool) -> Void = { _ in }) -> some View {
        Toggle(isOn: SwiftUI.Binding(get: { model.configuration[keyPath: keyPath] }, set: {
            model.setPresencePreference(keyPath, to: $0)
            applied(model.configuration[keyPath: keyPath])
        })) { settingLabel(title, description: description) }
        .toggleStyle(ThemeSwitchStyle()).disabled(model.storageLocked).modifier(CardRow())
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

/// Wraps a settings control in the shared card surface.
private struct CardRow: ViewModifier {
    func body(content: Content) -> some View { Card { content } }
}
