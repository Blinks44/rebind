import SwiftUI

/// Renders configured physical keys; the combined label preserves a single spoken shortcut.
struct ShortcutKeycaps: View {
    let shortcut: KeyboardShortcut

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Array(shortcut.modifiers.glyphs), id: \.self) { Keycap(label: String($0)) }
            Keycap(label: InputLabels.key(shortcut.keyCode))
        }
        .accessibilityRepresentation { Text(InputLabels.shortcut(shortcut)) }
    }
}
