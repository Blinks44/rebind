import SwiftUI

struct MouseTriggerEditor: View {
    @SwiftUI.Binding var draft: BindingEditorDraft
    let model: AppModel
    let record: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(.triggerTitle).font(.headline).accessibilityAddTraits(.isHeader)
            Picker(.mouseInputKind, selection: $draft.mouseTarget) {
                Text(.mouseButtonInput).tag(RecordingTarget.mouseTrigger)
                Text(.mouseWheelInput).tag(RecordingTarget.scrollTrigger)
                Text(.pointerGestureInput).tag(RecordingTarget.gestureTrigger)
            }.pickerStyle(.menu).disabled(model.recording != nil)

            BindingCaptureField(value: draft.trigger.map { InputLabels.trigger($0.trigger, modifiers: $0.modifiers) },
                target: draft.mouseTarget, recording: model.recording, canRecord: model.canRecord,
                record: record, cancel: model.cancelRecording, clear: { draft.trigger = nil })

            if draft.mouseTarget == .mouseTrigger {
                Text(.activationTitle).font(.caption).foregroundStyle(.secondary)
                Picker(.activationTitle, selection: $draft.activation) {
                    Text(.pressActivation).tag(PressActivation.press)
                    Text(.doublePressActivation).tag(PressActivation.doublePress)
                    Text(.holdActivation).tag(PressActivation.hold)
                }.pickerStyle(.segmented).labelsHidden().disabled(model.recording != nil)
                if draft.activation == .hold {
                    HoldDurationRow(milliseconds: $draft.holdDurationMilliseconds).disabled(model.recording != nil)
                    Text(.holdHint).font(.caption).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                } else if draft.activation == .doublePress {
                    Text(.doublePressHint).font(.caption).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else if draft.mouseTarget == .gestureTrigger {
                Picker(.pointerDirectionTitle, selection: $draft.pointerDirection) {
                    ForEach(PointerDirection.allCases, id: \.self) { direction in
                        Text(direction.label).tag(direction)
                    }
                }.pickerStyle(.menu).disabled(model.recording != nil)
            }
            Text(help).font(.caption).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var help: LocalizedStringResource {
        switch draft.mouseTarget {
        case .scrollTrigger: .mouseWheelHelp
        case .gestureTrigger: .mousePointerHelp
        default: .mouseButtonHelp
        }
    }
}
