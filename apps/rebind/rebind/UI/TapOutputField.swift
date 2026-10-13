import SwiftUI

/// Optional shortcut a hold rule sends when the trigger is released before the hold time.
struct TapOutputField: View {
    @SwiftUI.Binding var draft: BindingEditorDraft
    let model: AppModel
    let record: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(.tapOutputTitle).font(Theme.caption).foregroundStyle(Theme.textSecondary)
            BindingCaptureField(value: draft.tapOutput.map(InputLabels.shortcut), target: .tapOutput,
                recording: model.recording, canRecord: model.canRecord,
                record: record, cancel: model.cancelRecording,
                clear: { draft.tapOutput = nil }, wrapsControls: true, shortcut: draft.tapOutput)
            Text(.tapOutputHint).font(Theme.caption).foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
