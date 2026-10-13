import SwiftUI

struct MouseTriggerEditor: View {
    @SwiftUI.Binding var draft: BindingEditorDraft
    let model: AppModel
    let record: () -> Void
    let recordTapOutput: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(.triggerTitle)
            HStack(spacing: 12) {
                Text(.mouseInputKind).font(Theme.caption).foregroundStyle(Theme.textPrimary)
                Spacer(minLength: 8)
                MenuSelector(selection: $draft.mouseTarget, title: .mouseInputKind,
                    choices: [.mouseTrigger, .scrollTrigger, .gestureTrigger, .buttonScrollTrigger], label: inputKindTitle)
                    .frame(maxWidth: 224)
                    .accessibilityIdentifier("mouse-input-selector")
                    .disabled(model.recording != nil)
            }

            BindingCaptureField(value: draft.trigger.map { InputLabels.trigger($0.trigger, modifiers: $0.modifiers) },
                target: draft.mouseTarget, recording: model.recording, canRecord: model.canRecord,
                record: record, cancel: model.cancelRecording, clear: { draft.trigger = nil })

            if draft.mouseTarget == .mouseTrigger {
                Text(.activationTitle).font(Theme.caption).foregroundStyle(Theme.textSecondary)
                ActivationPicker(selection: $draft.activation)
                    .frame(maxWidth: .infinity)
                    .disabled(model.recording != nil)
                if draft.activation == .hold {
                    HoldDurationRow(milliseconds: $draft.holdDurationMilliseconds).disabled(model.recording != nil)
                    Text(.holdHint).font(Theme.caption).foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    TapOutputField(draft: $draft, model: model, record: recordTapOutput)
                } else if draft.activation == .doublePress {
                    Text(.doublePressHint).font(Theme.caption).foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else if draft.mouseTarget == .gestureTrigger {
                Text(.pointerDirectionTitle).font(Theme.caption).foregroundStyle(Theme.textSecondary)
                SegmentedPicker(selection: $draft.pointerDirection, title: .pointerDirectionTitle,
                                options: PointerDirection.allCases, label: { $0.label }, fillsWidth: true)
                    .accessibilityIdentifier("mouse-direction-selector")
                    .disabled(model.recording != nil)
            } else if draft.mouseTarget == .buttonScrollTrigger {
                Text(.wheelDirectionTitle).font(Theme.caption).foregroundStyle(Theme.textSecondary)
                SegmentedPicker(selection: $draft.scrollDirection, title: .wheelDirectionTitle,
                                options: ScrollDirection.allCases, label: { $0.directionLabel }, fillsWidth: true)
                    .accessibilityIdentifier("mouse-wheel-direction-selector")
                    .disabled(model.recording != nil)
            }
            Text(help).font(Theme.caption).foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func inputKindTitle(_ target: RecordingTarget) -> LocalizedStringResource {
        switch target {
        case .scrollTrigger: .mouseWheelInput
        case .gestureTrigger: .pointerGestureInput
        case .buttonScrollTrigger: .buttonWheelInput
        default: .mouseButtonInput
        }
    }

    private var help: LocalizedStringResource {
        switch draft.mouseTarget {
        case .scrollTrigger: .mouseWheelHelp
        case .gestureTrigger: .mousePointerHelp
        case .buttonScrollTrigger: .buttonWheelHelp
        default: .mouseButtonHelp
        }
    }
}
