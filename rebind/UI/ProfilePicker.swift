import SwiftUI

struct ProfilePicker: View {
    let model: AppModel

    // Commit to storage before changing the engine; do not bind directly to the
    // observable model's private configuration and bypass transactional saving.
    private var selection: SwiftUI.Binding<UUID> {
        SwiftUI.Binding(get: { model.configuration.selectedProfileID }, set: { model.selectProfile($0) })
    }

    var body: some View {
        Picker(.profileTitle, selection: selection) {
            ForEach(model.configuration.profiles) { profile in
                Text(verbatim: profile.title).tag(profile.id)
            }
        }.disabled(model.storageLocked)
    }
}
