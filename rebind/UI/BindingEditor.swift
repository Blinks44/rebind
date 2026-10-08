import SwiftUI

struct BindingEditor: View {
    let model: AppModel
    let scope: DeviceScope
    let existing: Binding?
    @Environment(\.dismiss) private var dismiss
    @State private var trigger: MatchKey?
    @State private var output: KeyboardShortcut?
    @State private var mouseRecordingTarget: RecordingTarget
    @State private var activation: PressActivation
    @State private var holdDurationMilliseconds: UInt32
    @State private var pointerDirection: PointerDirection

    init(model: AppModel, scope: DeviceScope, existing: Binding?) {
        self.model = model
        self.scope = scope
        self.existing = existing
        _trigger = State(initialValue: existing.map { $0.matchKey.pressSource })
        _output = State(initialValue: existing?.action.shortcut)
        _activation = State(initialValue: existing?.activation ?? .press)
        _holdDurationMilliseconds = State(initialValue: existing?.holdDurationMilliseconds ?? 500)
        let target: RecordingTarget
        if let existing, case .scroll = existing.trigger { target = .scrollTrigger }
        else if let existing, case .mouseGesture = existing.trigger { target = .gestureTrigger }
        else { target = .mouseTrigger }
        _mouseRecordingTarget = State(initialValue: target)
        let direction: PointerDirection
        if let existing, case .mouseGesture(_, let value) = existing.trigger { direction = value }
        else { direction = .left }
        _pointerDirection = State(initialValue: direction)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(existing == nil ? LocalizedStringResource.addBinding : .editBinding).font(.title2.bold())
            Text(.recordingLimitations).foregroundStyle(.secondary)
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    Text(.triggerTitle).font(.headline)
                    if scope == .allMice {
                        Picker(.mouseInputKind, selection: $mouseRecordingTarget) {
                            Text(.mouseButtonInput).tag(RecordingTarget.mouseTrigger)
                            Text(.mouseWheelInput).tag(RecordingTarget.scrollTrigger)
                            Text(.pointerGestureInput).tag(RecordingTarget.gestureTrigger)
                        }.pickerStyle(.menu)
                        if mouseRecordingTarget == .scrollTrigger {
                            Text(.wheelMappingHint).font(.caption).foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        if mouseRecordingTarget == .gestureTrigger {
                            Picker(.pointerDirectionTitle, selection: $pointerDirection) {
                                ForEach(PointerDirection.allCases, id: \.self) { direction in
                                    Text(direction.label).tag(direction)
                                }
                            }
                            Text(.pointerGestureHint).font(.caption).foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    if scope == .allKeyboards || mouseRecordingTarget == .mouseTrigger {
                        Text(.activationTitle).font(.caption).foregroundStyle(.secondary)
                        Picker(.activationTitle, selection: $activation) {
                            Text(.pressActivation).tag(PressActivation.press)
                            Text(.doublePressActivation).tag(PressActivation.doublePress)
                            Text(.holdActivation).tag(PressActivation.hold)
                        }.pickerStyle(.segmented).labelsHidden()
                        if activation == .doublePress {
                            Text(.doublePressHint).font(.caption).foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        if activation == .hold {
                            Stepper(value: $holdDurationMilliseconds, in: 100...5000, step: 100) {
                                Text(.holdDuration(Int(holdDurationMilliseconds)))
                            }
                            Text(.holdHint).font(.caption).foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    Text(trigger.map { InputLabels.trigger($0.trigger, modifiers: $0.modifiers) } ?? String(localized: .notRecorded)).font(.title3.monospaced())
                    Button(.recordTrigger) { model.beginRecording(scope == .allKeyboards ? .keyboardTrigger : mouseRecordingTarget) }
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
            if !model.canRecord {
                Text(model.permissionHint).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
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
        .onAppear { model.error = nil; model.beginEditing() }
        .onDisappear { model.endEditing() }
        .onChange(of: mouseRecordingTarget) {
            model.cancelRecording()
            trigger = nil
            activation = .press
            holdDurationMilliseconds = 500
            pointerDirection = .left
        }
        .onChange(of: activation) { model.cancelRecording() }
        .onChange(of: holdDurationMilliseconds) { model.cancelRecording() }
        .onChange(of: pointerDirection) { model.cancelRecording() }
        .onChange(of: model.lastRecording?.request.id) {
            guard let recording = model.lastRecording, let input = recording.input else { return }
            if recording.request.target == .output, case .key(let code) = input.trigger {
                output = KeyboardShortcut(keyCode: code, modifiers: input.modifiers)
            } else { trigger = input }
        }
    }

    private func save() {
        guard let trigger, let output else { return }
        let source: InputTrigger
        if mouseRecordingTarget == .gestureTrigger, scope == .allMice {
            guard case .mouseButton(let button) = trigger.trigger else { return }
            source = .mouseGesture(button: button, direction: pointerDirection)
        } else { source = trigger.trigger }
        var binding = Binding(scope: scope, trigger: source, modifiers: trigger.modifiers,
                              action: .shortcut(output), activation: activation,
                              holdDurationMilliseconds: holdDurationMilliseconds)
        if let existing { binding.id = existing.id; binding.isEnabled = existing.isEnabled }
        if model.saveBinding(binding) { dismiss() }
    }
}
