import SwiftUI

struct ProfileManagerView: View {
    let model: AppModel
    @State private var editing: ProfileEditOperation?
    @State private var pendingDeletion: RuleProfile?
    @Environment(\.dismiss) private var dismiss

    private var atLimit: Bool { model.configuration.profiles.count >= Configuration.maximumProfiles }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Text(.manageProfiles).font(Theme.titleSmall).foregroundStyle(Theme.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                Text(.profilesHint).font(Theme.caption).foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 28).padding(.top, 26)
            ScrollView {
                Card(insets: EdgeInsets()) {
                    VStack(spacing: 0) {
                        ForEach(model.configuration.profiles) { profile in
                            row(profile).overlay(alignment: .top) {
                                if profile.id != model.configuration.profiles.first?.id {
                                    Theme.separator.frame(height: 1).padding(.horizontal, 20)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 28).padding(.vertical, 20)
            }
            if let error = model.error {
                Text(error).font(Theme.callout).foregroundStyle(Theme.dangerText)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 28).padding(.bottom, 12)
            }
            Theme.separator.frame(height: 1)
            HStack(spacing: 10) {
                Button(.newProfile, systemImage: "plus") { editing = .create }
                    .secondaryButton().disabled(model.storageLocked || atLimit)
                Spacer()
                Button(.diagnosticsClose) { dismiss() }.keyboardShortcut(.cancelAction)
                    .primaryButton()
            }
            .controlSize(.large).padding(.horizontal, 28).padding(.vertical, 20)
        }
        .frame(width: 560, height: 480)
        .background(Theme.sheetSurface)
        .sheet(item: $editing) { ProfileNameEditor(model: model, operation: $0) }
        .alert(.deleteProfile, isPresented: deletionPresented) {
            Button(.cancel, role: .cancel) { pendingDeletion = nil }
            Button(.deleteProfile, role: .destructive) {
                if let profile = pendingDeletion { model.deleteProfile(profile.id) }
                pendingDeletion = nil
            }
        } message: { Text(.deleteProfileConfirmation(pendingDeletion?.title ?? "")) }
    }

    private func row(_ profile: RuleProfile) -> some View {
        let isSelected = profile.id == model.configuration.selectedProfileID
        return HStack(spacing: 12) {
            ActionTile(symbol: "square.on.square")
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: profile.title).font(Theme.headline).foregroundStyle(Theme.textPrimary).lineLimit(1)
                Text(.profileRuleCount(profile.bindings.count)).font(Theme.caption).foregroundStyle(Theme.textSecondary)
            }
            Spacer(minLength: 12)
            if isSelected {
                Label(.profileSelected, systemImage: "checkmark").font(Theme.calloutStrong).foregroundStyle(Theme.successText)
            } else {
                Button(.selectProfile) { model.selectProfile(profile.id) }.secondaryButton()
            }
            OptionsMenu(label: .profileOptions) {
                Button(.duplicateProfile) { editing = .duplicate(profile.id) }.disabled(atLimit)
                Button(.renameProfile) { editing = .rename(profile.id) }
                Button(.deleteProfile, role: .destructive) { pendingDeletion = profile }
                    .disabled(model.configuration.profiles.count <= 1)
            }
        }
        .disabled(model.storageLocked)
        .padding(.leading, 20).padding(.trailing, 16).frame(minHeight: 64)
    }

    private var deletionPresented: SwiftUI.Binding<Bool> {
        SwiftUI.Binding(get: { pendingDeletion != nil }, set: { if !$0 { pendingDeletion = nil } })
    }
}
