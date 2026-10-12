import SwiftUI

/// Inline login approval/failure controls never imply a granted OS registration.
struct LoginItemSettingsRow: View {
    let model: LoginItemModel

    var body: some View {
        if model.showsToggle {
            Card {
                Toggle(isOn: loginEnabled) { label }
                    .toggleStyle(ThemeSwitchStyle())
                    .accessibilityLabel(Text(.launchAtLogin))
                    .accessibilityHint(Text(model.description))
            }
        } else {
            Banner(severity: feedbackSeverity, title: .launchAtLogin, message: model.description) {
                if model.operation != nil {
                    ProgressView().controlSize(.small).accessibilityHidden(true)
                } else {
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 8) { recoveryActions }
                        VStack(alignment: .leading, spacing: 8) { recoveryActions }
                    }
                }
            }
        }
    }

    private var feedbackSeverity: BannerSeverity {
        if model.operation != nil { return .information }
        if model.status == .unavailable { return .warning }
        return model.failedOperation == nil ? .warning : .error
    }

    private var label: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(.launchAtLogin).font(Theme.bodyStrong).foregroundStyle(Theme.textPrimary)
            Text(model.description).font(Theme.callout).foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder private var recoveryActions: some View {
        Button(.openLoginItems) { model.openLoginItems() }.secondaryButton()
        Button(.checkAgain) { model.refresh() }.secondaryButton()
        if model.status != .unavailable {
            if model.failedOperation != nil {
                Button(.tryAgain) { Task { await model.retry() } }.secondaryButton()
            }
            if model.status == .requiresApproval {
                Button(.turnOff) { Task { await model.setEnabled(false) } }.secondaryButton()
            }
        }
    }

    private var loginEnabled: SwiftUI.Binding<Bool> {
        // The model owns operations beyond view disappearance and rejects overlap.
        SwiftUI.Binding(get: { model.status == .enabled },
                        set: { enabled in Task { await model.setEnabled(enabled) } })
    }
}
