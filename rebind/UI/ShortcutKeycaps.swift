import SwiftUI

/// Renders configured physical keys; the combined label preserves a single spoken shortcut.
struct ShortcutKeycaps: View {
    let shortcut: KeyboardShortcut

    var body: some View {
        HStack(spacing: 8) {
            if !shortcut.modifiers.glyphs.isEmpty {
                keycap(shortcut.modifiers.glyphs)
                Text("+").accessibilityHidden(true)
            }
            keycap(InputLabels.key(shortcut.keyCode))
        }
        .accessibilityRepresentation { Text(InputLabels.shortcut(shortcut)) }
    }

    private func keycap(_ title: String) -> some View {
        Text(title).font(EditorTypography.label)
            .padding(.horizontal, 12).frame(minHeight: EditorMetrics.keycapHeight)
            .background(Color(.editorKeycap), in: .rect(cornerRadius: 8))
    }
}
