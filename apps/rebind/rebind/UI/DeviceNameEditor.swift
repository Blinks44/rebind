import SwiftUI

/// Uses the same naming-sheet controls as profiles; an empty name restores the hardware name.
struct DeviceNameEditor: View {
    let model: AppModel
    let deviceKey: String
    let original: String
    @State private var name: String
    @Environment(\.dismiss) private var dismiss

    init(model: AppModel, deviceKey: String, original: String) {
        self.model = model
        self.deviceKey = deviceKey
        self.original = original
        _name = State(initialValue: model.configuration.deviceNames[deviceKey] ?? "")
    }

    private var valid: Bool {
        Configuration.isValidDeviceName(name.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(.renameDevice).font(Theme.titleSmall).foregroundStyle(Theme.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Text(verbatim: original).font(Theme.caption).foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            ThemeTextField(title: .deviceName, text: $name, autofocus: true, onSubmit: save)
            Text(.deviceNamingHint).font(Theme.caption).foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            if let error = model.error {
                Text(error).font(Theme.callout).foregroundStyle(Theme.dangerText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack(spacing: 10) {
                Spacer()
                Button(.cancel) { dismiss() }.keyboardShortcut(.cancelAction).secondaryButton()
                Button(.saveBinding) { save() }.keyboardShortcut(.defaultAction).primaryButton()
                    .disabled(model.storageLocked || !valid)
            }.controlSize(.large).padding(.top, 8)
        }.padding(28).frame(width: 440).background(Theme.sheetSurface)
            .onAppear { model.error = nil; model.beginEditing() }
            .onDisappear { model.endEditing() }
    }

    private func save() {
        guard valid, model.renameDevice(key: deviceKey, original: original, name: name) else { return }
        dismiss()
    }
}
