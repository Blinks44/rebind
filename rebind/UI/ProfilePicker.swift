import SwiftUI

struct ProfilePicker: View {
    let model: AppModel
    var usesGlass = false

    // Commit to storage before changing the engine; do not bind directly to the
    // observable model's private configuration and bypass transactional saving.
    private var selection: SwiftUI.Binding<UUID> {
        SwiftUI.Binding(get: { model.configuration.selectedProfileID }, set: { model.selectProfile($0) })
    }

    var body: some View {
        Group {
            if usesGlass {
                EditorMenuSelector(selection: selection, title: .profileTitle,
                    choices: model.configuration.profiles.map(\.id),
                    label: { id in
                        let name = model.configuration.profiles.first { $0.id == id }?.title ?? ""
                        return LocalizedStringResource("\(name)")
                    }, symbol: "house", singleLine: true)
            } else {
                Picker(.profileTitle, selection: selection) {
                    ForEach(model.configuration.profiles) { profile in
                        Text(verbatim: profile.title).tag(profile.id)
                    }
                }
            }
        }.disabled(model.storageLocked)
    }
}
