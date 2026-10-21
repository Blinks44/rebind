import AppKit
import SwiftUI

/// First-run steps. Recovery shows only the access content.
nonisolated enum FirstRunStep: Int, CaseIterable, Sendable {
    case welcome = 1, access, ready
}

/// First-run and recovery guidance never changes the user's remapping preference.
struct PermissionSetupView: View {
    let model: AppModel
    let context: PermissionSetupContext
    var addFirstBinding: () -> Void = {}
    @State private var step = FirstRunStep.welcome
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    introduction
                    switch context == .recovery ? .access : step {
                    case .welcome: welcome
                    case .access: access
                    case .ready: ready
                    }
                    if let error = model.error { Text(error).font(Theme.callout).foregroundStyle(Theme.dangerText) }
                }
                .fixedSize(horizontal: false, vertical: true)
                .padding(32)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            footer
                .controlSize(.large)
                .padding(.horizontal, 32).padding(.bottom, 32).padding(.top, 16)
        }
        .frame(minWidth: 520, idealWidth: 560, minHeight: 560, idealHeight: 580)
        .background(Theme.sheetSurface)
        .interactiveDismissDisabled(context == .firstRun)
    }

    private var introduction: some View {
        let (title, purpose): (LocalizedStringResource, LocalizedStringResource) = switch (context, step) {
        case (.recovery, _): (.restoreTitle, .restorePurpose)
        case (_, .welcome): (.welcomeTitle, .welcomePurpose)
        case (_, .access): (.accessStepTitle, .accessStepPurpose)
        case (_, .ready): (.readyTitle, .readyStepPurpose)
        }
        return HStack(alignment: .top, spacing: 16) {
            Image(nsImage: NSWorkspace.shared.icon(forFile: Bundle.main.bundlePath))
                .resizable().frame(width: 48, height: 48).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 8) {
                Text(title).font(Theme.title).foregroundStyle(Theme.textPrimary).accessibilityAddTraits(.isHeader)
                Text(purpose).foregroundStyle(Theme.textSecondary)
            }
        }.frame(minHeight: 88, alignment: .top)
    }

    private var welcome: some View {
        VStack(alignment: .leading, spacing: 20) {
            Card(insets: EdgeInsets()) {
                VStack(spacing: 0) {
                    feature("keyboard", .welcomeKeysTitle, .welcomeKeysDescription)
                    divider
                    feature("hand.tap", .welcomeTouchTitle, .welcomeTouchDescription)
                    divider
                    feature("app", .welcomeAppsTitle, .welcomeAppsDescription)
                    divider
                    feature("pause", .welcomePauseTitle, .welcomePauseDescription)
                }
            }
            Text(.privacyAssurance).font(Theme.callout).foregroundStyle(Theme.textSecondary)
        }
    }

    private var access: some View {
        VStack(alignment: .leading, spacing: 24) {
            requiredAccess
            Card(insets: EdgeInsets()) {
                VStack(spacing: 0) {
                    if model.permissions.requirement == .accessibility {
                        row(.eventSendingTitle, status: .permissionsWaitingAccessibility, isWarning: true,
                            description: .permissionsSendingWaiting)
                        divider
                    }
                    row(.inputMonitoringTitle, status: .notRequired, description: .otherPermissionsPurpose)
                }
            }
            Text(.privacyAssurance).font(Theme.callout).foregroundStyle(Theme.textSecondary)
        }
    }

    private var ready: some View {
        VStack(alignment: .leading, spacing: 16) {
            Banner(severity: .success, title: .accessOnTitle, message: .accessOnMessage)
            LoginItemSettingsRow(model: model.loginItem)
            UpdateSettingsRow(updater: RebindAppDelegate.updater)
            Text(.menuBarHint).font(Theme.callout).foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder private var requiredAccess: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let requirement = model.permissions.requirement {
                Banner(severity: .warning,
                    title: requirement == .accessibility ? .accessibilityTitle : .eventSendingTitle,
                    message: context == .recovery ? .accessLostPurpose
                        : requirement == .accessibility ? .accessibilityPurpose : .eventSendingPurpose)
                PermissionAccessControls(model: model, requirement: requirement)
                Text(requirement == .eventPosting ? LocalizedStringResource.eventSendingSteps
                     : context == .recovery ? .restoreSteps : .accessibilitySteps)
                    .font(Theme.callout).foregroundStyle(Theme.textSecondary)
            } else {
                Banner(severity: .success, title: .ready,
                    message: context == .recovery ? .permissionsRespectsPause : .readyPurpose) {
                    Button(.checkAgain) { model.refreshPermissions() }.secondaryButton()
                }
                Text(.backgroundHint).font(Theme.callout).foregroundStyle(Theme.textSecondary)
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 12) {
            if context == .firstRun {
                Text(.setupStep(step.rawValue, FirstRunStep.allCases.count))
                    .font(Theme.callout).foregroundStyle(Theme.textSecondary)
            }
            Spacer(minLength: 0)
            switch context == .recovery ? nil : step {
            case nil:
                Button(.close) { dismiss() }.keyboardShortcut(.cancelAction).secondaryButton()
            case .welcome:
                Button(.`continue`) {
                    model.refreshPermissions()
                    step = model.permissions.allowsRemapping ? .ready : .access
                }
                .primaryButton().keyboardShortcut(.defaultAction)
            case .access:
                if !model.permissions.allowsRemapping {
                    // Escape is not available on first run (Sketch Foundations 11): leaving is deliberate.
                    Button(.setUpLater) { finishSetup() }.secondaryButton()
                }
                Button(.`continue`) {
                    model.refreshPermissions()
                    if model.permissions.allowsRemapping { step = .ready }
                }
                .primaryButton()
                .keyboardShortcut(.defaultAction)
                .disabled(!model.permissions.allowsRemapping)
            case .ready:
                Button(.addFirstBinding) {
                    guard model.completePermissionSetup() else { return }
                    addFirstBinding()
                    dismiss()
                }.secondaryButton()
                Button(.aboutDone) { finishSetup() }.primaryButton().keyboardShortcut(.defaultAction)
            }
        }
    }

    private var divider: some View { Theme.separator.frame(height: 1).padding(.horizontal, 20) }

    private func feature(_ symbol: String, _ title: LocalizedStringResource,
                         _ description: LocalizedStringResource) -> some View {
        HStack(spacing: 12) {
            ActionTile(symbol: symbol)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(Theme.bodyStrong).foregroundStyle(Theme.textPrimary)
                Text(description).font(Theme.caption).foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 20).padding(.vertical, 16)
        .accessibilityElement(children: .combine)
    }

    private func row(_ title: LocalizedStringResource, status: LocalizedStringResource, isWarning: Bool = false,
                     description: LocalizedStringResource) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            StatusLabel(title: title, status: status, isWarning: isWarning)
            Text(description).font(Theme.caption).foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 20).padding(.vertical, 14).frame(maxWidth: .infinity, alignment: .leading)
    }

    private func finishSetup() {
        if model.completePermissionSetup() { dismiss() }
    }
}
