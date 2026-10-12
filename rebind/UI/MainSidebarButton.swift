import SwiftUI

/// Shared navigation target: the label's full rectangle belongs to the native button.
struct MainSidebarButton: View {
    let title: LocalizedStringResource
    let symbol: String
    var isSelected = false
    let action: () -> Void
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor
    @State private var isHovered = false
    @FocusState private var isFocused: Bool

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: symbol)
                    .font(EditorTypography.body)
                    .frame(width: 18, height: 18).accessibilityHidden(true)
                Text(title).font(isSelected ? EditorTypography.label : EditorTypography.body).lineLimit(1)
                Spacer(minLength: 0)
            }
            .foregroundStyle(isEnabled ? Color(isSelected ? .editorAccentText : .editorTextPrimary) : Color(nsColor: .secondaryLabelColor))
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity).frame(height: 40)
            .background(isSelected ? Color(.editorAccentWash) : isHovered && isEnabled ? Color(.navigationHover) : .clear,
                        in: .rect(cornerRadius: 8))
            .overlay {
                if isFocused || isSelected && (contrast == .increased || differentiateWithoutColor) {
                    RoundedRectangle(cornerRadius: 8).strokeBorder(Color(.editorAccentText), lineWidth: isFocused ? 2 : 1)
                }
            }
            .contentShape(.rect)
        }
        .buttonStyle(MainSidebarButtonStyle())
        .focusable()
        .focused($isFocused)
        .focusEffectDisabled()
        .onKeyPress(.space, phases: .down) { _ in
            guard isEnabled else { return .ignored }
            action()
            return .handled
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .onHover { isHovered = $0 }
        .transaction { $0.animation = nil }
    }
}
