import SwiftUI

/// Reuses the existing trackpad editor's selector, held-key row and native semantics.
struct MagicMouseTriggerEditor: View {
    @SwiftUI.Binding var draft: BindingEditorDraft
    let isRecording: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(.triggerTitle)
            MenuSelector(selection: $draft.magicMousePreset, title: .magicMouseGestureTitle,
                         choices: MagicMousePreset.allCases, label: { $0.title })
                .frame(maxWidth: .infinity, minHeight: 36)
                .disabled(isRecording)
                .accessibilityIdentifier("magic-mouse-preset-selector")
            HStack(spacing: 12) {
                Text(.trackpadModifierTitle).font(Theme.caption).foregroundStyle(Theme.textPrimary)
                Spacer(minLength: 8)
                MenuSelector(selection: $draft.trackpadModifiers, title: .trackpadModifierTitle,
                             choices: ModifierSet.trackpadChoices, label: { $0.choiceTitle })
                    .frame(maxWidth: 224)
                    .disabled(isRecording)
                    .accessibilityIdentifier("magic-mouse-modifier-selector")
            }
            if !draft.trackpadModifiers.isEmpty {
                Text(.trackpadModifierHint).font(Theme.caption).foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Text(.magicMouseTapHelp).font(Theme.caption).foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
