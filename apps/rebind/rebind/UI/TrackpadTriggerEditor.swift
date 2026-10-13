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
            HStack(spacing: 12) {
                Text(.trackpadModifierTitle).font(Theme.caption).foregroundStyle(Theme.textPrimary)
                Spacer(minLength: 8)
                MenuSelector(selection: $draft.trackpadModifiers, title: .trackpadModifierTitle,
                             choices: ModifierSet.trackpadChoices, label: { $0.choiceTitle })
                    .frame(maxWidth: 224)
                    .disabled(isRecording || draft.trackpadPreset == nil)
                    .accessibilityIdentifier("trackpad-modifier-selector")
            }
            if !draft.trackpadModifiers.isEmpty {
                Text(.trackpadModifierHint).font(Theme.caption).foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let preset = draft.trackpadPreset {
                Text(preset.explanation).font(Theme.caption).foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
