import SwiftUI

struct ProfileNameEditor: View {
    let model: AppModel
    let operation: ProfileEditOperation
    @State private var name: String
    @FocusState private var focused: Bool
    @Environment(\.dismiss) private var dismiss

    init(model: AppModel, operation: ProfileEditOperation) {
        self.model = model
        self.operation = operation
        let initial: String
        switch operation {
        case .create: initial = ""
        case .duplicate(let id): initial = (model.configuration.profiles.first { $0.id == id }?.title ?? "") + " 2"
        case .rename(let id): initial = model.configuration.profiles.first { $0.id == id }?.title ?? ""
        }
        _name = State(initialValue: initial)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(operation.title).font(.title2.bold())
            TextField(.profileName, text: $name).focused($focused)
            Text(.profileNamingHint).font(.caption).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            if let error = model.error { Text(error).foregroundStyle(.red).fixedSize(horizontal: false, vertical: true) }
            HStack {
                Spacer()
                Button(.cancel) { dismiss() }.keyboardShortcut(.cancelAction)
                Button(.saveBinding) { save() }.keyboardShortcut(.defaultAction)
                    .disabled(model.storageLocked || name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }.padding(24).frame(width: 440)
            .onAppear { model.error = nil; model.beginEditing(); focused = true }
            .onDisappear { model.endEditing() }
    }

    private func save() {
        let saved: Bool
        switch operation {
        case .create: saved = model.createProfile(name: name)
        case .duplicate(let id): saved = model.createProfile(name: name, copying: id)
        case .rename(let id): saved = model.renameProfile(id, name: name)
        }
        if saved { dismiss() }
    }
}
