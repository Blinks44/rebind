import SwiftUI

struct ProfileManagerView: View {
    let model: AppModel
    @State private var editing: ProfileEditOperation?
    @State private var pendingDeletion: RuleProfile?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(.manageProfiles).font(Theme.titleSmall)
            Text(.profilesHint).foregroundStyle(Theme.textSecondary).fixedSize(horizontal: false, vertical: true)
            List(model.configuration.profiles) { profile in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(verbatim: profile.title).font(Theme.headline)
                        Text(.profileRuleCount(profile.bindings.count)).font(Theme.caption).foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                    if profile.id == model.configuration.selectedProfileID {
                        Label(.profileSelected, systemImage: "checkmark.circle.fill").foregroundStyle(Theme.textSecondary)
                    } else {
                        Button(.selectProfile) { model.selectProfile(profile.id) }.disabled(model.storageLocked)
                    }
                    Menu {
                        Button(.duplicateProfile) { editing = .duplicate(profile.id) }
                            .disabled(model.configuration.profiles.count >= Configuration.maximumProfiles)
                        Button(.renameProfile) { editing = .rename(profile.id) }
                        Button(.deleteProfile, role: .destructive) { pendingDeletion = profile }
                            .disabled(model.configuration.profiles.count <= 1)
                    } label: { Label(.profileOptions, systemImage: "ellipsis") }
                        .labelStyle(.iconOnly).disabled(model.storageLocked)
                }.padding(.vertical, 4)
            }
            if let error = model.error { Text(error).foregroundStyle(.red).fixedSize(horizontal: false, vertical: true) }
            HStack {
                Button(.newProfile, systemImage: "plus") { editing = .create }
                    .disabled(model.storageLocked || model.configuration.profiles.count >= Configuration.maximumProfiles)
                Spacer()
                Button(.diagnosticsClose) { dismiss() }.keyboardShortcut(.cancelAction)
            }
        }.padding(24).frame(width: 620, height: 450)
            .sheet(item: $editing) { ProfileNameEditor(model: model, operation: $0) }
            .alert(.deleteProfile, isPresented: deletionPresented) {
                Button(.cancel, role: .cancel) { pendingDeletion = nil }
                Button(.deleteProfile, role: .destructive) {
                    if let profile = pendingDeletion { model.deleteProfile(profile.id) }
                    pendingDeletion = nil
                }
            } message: { Text(.deleteProfileConfirmation(pendingDeletion?.title ?? "")) }
    }

    private var deletionPresented: SwiftUI.Binding<Bool> {
        SwiftUI.Binding(get: { pendingDeletion != nil }, set: { if !$0 { pendingDeletion = nil } })
    }
}
