import SwiftUI

struct TrackpadTriggerEditor: View {
    @SwiftUI.Binding var draft: BindingEditorDraft
    let isRecording: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(.triggerTitle)
            EditorMenuSelector(selection: $draft.trackpadPreset, title: .trackpadGestureTitle,
                choices: (draft.trackpadPreset == nil ? [nil] : []) + TrackpadPreset.allCases.map(Optional.some),
                label: { $0?.title ?? .notRecorded })
            .frame(maxWidth: .infinity, minHeight: 36)
            .disabled(isRecording)
            .accessibilityIdentifier("trackpad-preset-selector")
            if let preset = draft.trackpadPreset {
                Text(preset.explanation).font(EditorTypography.caption).foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
