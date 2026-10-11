import SwiftUI

/// Inline login approval/failure controls never imply a granted OS registration.
struct LoginItemSettingsRow: View {
    let model: LoginItemModel

    var body: some View {
        PermissionCard {
            if model.showsToggle {
                Toggle(isOn: loginEnabled) { label }
                    .toggleStyle(.switch)
                    .accessibilityLabel(Text(.launchAtLogin))
                    .accessibilityHint(Text(model.description))
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    label
                    if model.operation != nil {
                        ProgressView().controlSize(.small).accessibilityHidden(true)
                    } else {
                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: 8) { recoveryActions }
                            VStack(alignment: .leading, spacing: 8) { recoveryActions }
                        }.buttonStyle(.bordered)
                    }
                }
            }
        }
    }

    private var label: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(.launchAtLogin)
            Text(model.description).font(.callout).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder private var recoveryActions: some View {
        Button(.openLoginItems) { model.openLoginItems() }
        Button(.checkAgain) { model.refresh() }
        if model.status != .unavailable {
            if model.failedOperation != nil {
                Button(.tryAgain) { Task { await model.retry() } }
            }
            if model.status == .requiresApproval {
                Button(.turnOff) { Task { await model.setEnabled(false) } }
            }
        }
    }

    private var loginEnabled: SwiftUI.Binding<Bool> {
        // The model owns operations beyond view disappearance and rejects overlap.
        SwiftUI.Binding(get: { model.status == .enabled },
                        set: { enabled in Task { await model.setEnabled(enabled) } })
    }
}
