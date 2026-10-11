import SwiftUI

/// Settings → Permissions uses actual grants, independently of engine status.
struct PermissionView: View {
    let model: AppModel
    var showsSettingsHeader = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if showsSettingsHeader {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(.settingsTitle).font(.largeTitle.bold()).accessibilityAddTraits(.isHeader)
                        Text(.settingsDescription).foregroundStyle(.secondary)
                    }
                }
                Label(.permissionsTitle, systemImage: "lock.shield").font(.headline)
                    .accessibilityAddTraits(.isHeader)
                VStack(alignment: .leading, spacing: 8) {
                    Text(model.permissions.allowsRemapping ? LocalizedStringResource.permissionsAccessEnabled : .permissionsStopped)
                        .font(.headline).accessibilityAddTraits(.isHeader)
                    Text(statusExplanation).foregroundStyle(.secondary)
                }
                VStack(spacing: 16) {
                    accessibilityCard
                    eventSendingCard
                    PermissionCard {
                        VStack(alignment: .leading, spacing: 12) {
                            PermissionStatusLabel(title: .inputMonitoringTitle, status: .notRequired)
                            Text(.permissionsOtherPurpose).foregroundStyle(.secondary)
                        }
                    }
                }
                Text(.privacyAssurance).font(.callout).foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 12) {
                    Button(.showApplicationInFinder) { model.showApplicationInFinder() }
                    Text(.signingHint).font(.callout).foregroundStyle(.secondary)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(28)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background { PermissionCanvas() }
        .navigationTitle(.settingsTitle)
    }

    private var statusExplanation: LocalizedStringResource {
        switch model.permissions.requirement {
        case .accessibility: .permissionsEnableAccessibility
        case .eventPosting: .permissionsAllowSending
        case nil: .permissionsRespectsPause
        }
    }

    private var accessibilityCard: some View {
        PermissionCard {
            VStack(alignment: .leading, spacing: 12) {
                PermissionStatusLabel(title: .accessibilityTitle,
                                      status: model.permissions.accessibility ? .permissionEnabled : .notEnabled,
                                      isWarning: !model.permissions.accessibility, isPrimary: !model.permissions.accessibility)
                Text(model.permissions.accessibility ? LocalizedStringResource.permissionsAccessibilityEnabled : .permissionsAccessibilityPurpose)
                    .foregroundStyle(.secondary)
                if !model.permissions.accessibility {
                    PermissionAccessControls(model: model, requirement: .accessibility)
                    Text(.accessibilitySteps).font(.callout).foregroundStyle(.secondary)
                } else {
                    Button(.checkAgain) { model.refreshPermissions() }.buttonStyle(.bordered)
                }
            }
        }
    }

    private var eventSendingCard: some View {
        PermissionCard {
            VStack(alignment: .leading, spacing: 12) {
                PermissionStatusLabel(title: .eventSendingTitle, status: postingStatus,
                                      isWarning: model.permissions.requirement == .eventPosting,
                                      isPrimary: model.permissions.requirement == .eventPosting)
                Text(postingExplanation).foregroundStyle(.secondary)
                if model.permissions.requirement == .eventPosting {
                    PermissionAccessControls(model: model, requirement: .eventPosting)
                    Text(.eventSendingSteps).font(.callout).foregroundStyle(.secondary)
                }
            }
        }
    }

    private var postingStatus: LocalizedStringResource {
        if model.permissions.posting { return .permissionEnabled }
        return model.permissions.accessibility ? .notEnabled : .permissionsWaitingAccessibility
    }

    private var postingExplanation: LocalizedStringResource {
        if model.permissions.posting { return .permissionsSendingEnabled }
        return model.permissions.accessibility ? .permissionsSendingPurpose : .permissionsSendingWaiting
    }
}
