import SwiftUI

struct BindingEditor: View {
    let model: AppModel
    let scope: DeviceScope
    let existing: Binding?
    @Environment(\.dismiss) private var dismiss
    @State private var trigger: MatchKey?
    @State private var output: KeyboardShortcut?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(existing == nil ? LocalizedStringResource.addBinding : .editBinding).font(.title2.bold())
            Text(.recordingLimitations).foregroundStyle(.secondary)
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    Text(.triggerTitle).font(.headline)
                    Text(trigger.map { InputLabels.trigger($0.trigger, modifiers: $0.modifiers) } ?? String(localized: .notRecorded)).font(.title3.monospaced())
                    Button(.recordTrigger) { model.beginRecording(scope == .allKeyboards ? .keyboardTrigger : .mouseTrigger) }
                        .disabled(!model.canRecord || model.recording != nil)
                }.frame(maxWidth: .infinity, alignment: .leading).padding(8)
            }
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    Text(.outputShortcut).font(.headline)
                    Text(output.map(InputLabels.shortcut) ?? String(localized: .notRecorded)).font(.title3.monospaced())
                    Button(.recordOutput) { model.beginRecording(.output) }.disabled(!model.canRecord || model.recording != nil)
                }.frame(maxWidth: .infinity, alignment: .leading).padding(8)
            }
            if model.recording != nil {
                HStack {
                    Label(.listeningHint, systemImage: "record.circle").foregroundStyle(.tint)
                    Spacer()
                    Button(.cancelRecording) { model.cancelRecording() }
                }
            }
            if !model.canRecord { Text(.permissionsRequired).foregroundStyle(.secondary) }
            switch model.status {
            case .tapFailed, .interrupted, .outputFailed, .secureInput:
                Text(model.status.text).foregroundStyle(.secondary)
            default: EmptyView()
            }
            if let error = model.error { Text(error).foregroundStyle(.red) }
            HStack {
                Button(.clearRecording) { model.cancelRecording(); trigger = nil; output = nil }
                Spacer()
                Button(.cancel) { dismiss() }.keyboardShortcut(.cancelAction)
                Button(.saveBinding) { save() }.keyboardShortcut(.defaultAction)
                    .disabled(trigger == nil || output == nil || model.recording != nil || model.storageLocked)
            }
        }.padding(24).frame(width: 520)
        .onAppear { model.error = nil; model.beginEditing(); trigger = existing?.matchKey; output = existing?.action.shortcut }
        .onDisappear { model.endEditing() }
        .onChange(of: model.lastRecording?.request.id) {
            guard let recording = model.lastRecording, let input = recording.input else { return }
            if recording.request.target == .output, case .key(let code) = input.trigger {
                output = KeyboardShortcut(keyCode: code, modifiers: input.modifiers)
            } else { trigger = input }
        }
    }

    private func save() {
        guard let trigger, let output else { return }
        var binding = Binding(scope: scope, trigger: trigger.trigger, modifiers: trigger.modifiers, action: .shortcut(output))
        if let existing { binding.id = existing.id; binding.isEnabled = existing.isEnabled }
        if model.saveBinding(binding) { dismiss() }
    }
}
