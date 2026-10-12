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
            Text(operation.title).font(Theme.titleSmall).foregroundStyle(Theme.textPrimary)
                .accessibilityAddTraits(.isHeader)
            TextField(text: $name, prompt: Text(.profileName).foregroundStyle(Theme.textTertiary)) { Text(.profileName) }
                .textFieldStyle(.plain).font(Theme.body).foregroundStyle(Theme.textPrimary)
                .focused($focused).focusEffectDisabled().onSubmit(save)
                .padding(.horizontal, 16).frame(height: Theme.controlHeight)
                .modifier(ControlSurface(isFocused: focused))
            Text(.profileNamingHint).font(Theme.caption).foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            if let error = model.error {
                Text(error).font(Theme.callout).foregroundStyle(Theme.dangerText).fixedSize(horizontal: false, vertical: true)
            }
            HStack(spacing: 10) {
                Spacer()
                Button(.cancel) { dismiss() }.keyboardShortcut(.cancelAction).modifier(EditorSecondaryButton())
                Button(.saveBinding) { save() }.keyboardShortcut(.defaultAction)
                    .buttonStyle(PrimaryButtonStyle()).keyboardFocusRing()
                    .disabled(model.storageLocked || name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }.controlSize(.large).padding(.top, 8)
        }.padding(28).frame(width: 440).background(Theme.sheetSurface)
            .onAppear { model.error = nil; model.beginEditing(); focused = true }
            .onDisappear { model.endEditing() }
    }

    private func save() {
        guard !model.storageLocked, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let saved: Bool
        switch operation {
        case .create: saved = model.createProfile(name: name)
        case .duplicate(let id): saved = model.createProfile(name: name, copying: id)
        case .rename(let id): saved = model.renameProfile(id, name: name)
        }
        if saved { dismiss() }
    }
}
