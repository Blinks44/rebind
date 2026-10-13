import SwiftUI

struct TrackpadTriggerEditor: View {
    @SwiftUI.Binding var draft: BindingEditorDraft
    let isRecording: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(.triggerTitle)
            MenuSelector(selection: $draft.trackpadPreset, title: .trackpadGestureTitle,
                choices: (draft.trackpadPreset == nil ? [nil] : []) + TrackpadPreset.allCases.map(Optional.some),
                label: { $0?.title ?? .notRecorded },
                startsGroup: { [.twoFingerDoubleTap, .click(fingers: 2), .cornerTap(.topLeft)].contains($0) })
            .frame(maxWidth: .infinity, minHeight: 36)
            .disabled(isRecording)
            .accessibilityIdentifier("trackpad-preset-selector")
            if let preset = draft.trackpadPreset {
                Text(preset.explanation).font(Theme.caption).foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
