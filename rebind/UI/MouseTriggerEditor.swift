import SwiftUI

struct MouseTriggerEditor: View {
    @SwiftUI.Binding var draft: BindingEditorDraft
    let model: AppModel
    let record: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: EditorMetrics.fieldSpacing) {
            SectionLabel(.triggerTitle)
            HStack(spacing: EditorMetrics.fieldSpacing) {
                Text(.mouseInputKind).font(EditorTypography.caption).foregroundStyle(Theme.textPrimary)
                Spacer(minLength: 8)
                EditorMenuSelector(selection: $draft.mouseTarget, title: .mouseInputKind,
                    choices: [.mouseTrigger, .scrollTrigger, .gestureTrigger], label: inputKindTitle)
                    .frame(maxWidth: EditorMetrics.mouseSelectorWidth)
                    .accessibilityIdentifier("mouse-input-selector")
                    .disabled(model.recording != nil)
            }

            BindingCaptureField(value: draft.trigger.map { InputLabels.trigger($0.trigger, modifiers: $0.modifiers) },
                target: draft.mouseTarget, recording: model.recording, canRecord: model.canRecord,
                record: record, cancel: model.cancelRecording, clear: { draft.trigger = nil })

            if draft.mouseTarget == .mouseTrigger {
                Text(.activationTitle).font(EditorTypography.caption).foregroundStyle(Theme.textSecondary)
                EditorActivationPicker(selection: $draft.activation)
                    .frame(maxWidth: .infinity)
                    .disabled(model.recording != nil)
                if draft.activation == .hold {
                    HoldDurationRow(milliseconds: $draft.holdDurationMilliseconds).disabled(model.recording != nil)
                    Text(.holdHint).font(EditorTypography.caption).foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                } else if draft.activation == .doublePress {
                    Text(.doublePressHint).font(EditorTypography.caption).foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else if draft.mouseTarget == .gestureTrigger {
                HStack(spacing: EditorMetrics.fieldSpacing) {
                    Text(.pointerDirectionTitle).font(EditorTypography.caption).foregroundStyle(Theme.textPrimary)
                    Spacer(minLength: 8)
                    EditorMenuSelector(selection: $draft.pointerDirection, title: .pointerDirectionTitle,
                        choices: PointerDirection.allCases, label: { $0.label })
                        .frame(maxWidth: EditorMetrics.mouseSelectorWidth)
                        .accessibilityIdentifier("mouse-direction-selector")
                        .disabled(model.recording != nil)
                }
            }
            Text(help).font(EditorTypography.caption).foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func inputKindTitle(_ target: RecordingTarget) -> LocalizedStringResource {
        switch target {
        case .scrollTrigger: .mouseWheelInput
        case .gestureTrigger: .pointerGestureInput
        default: .mouseButtonInput
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
