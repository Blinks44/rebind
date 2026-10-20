import SwiftUI

/// Shared navigation target: the label's full rectangle belongs to the native button.
struct MainSidebarButton: View {
    let title: LocalizedStringResource
    let symbol: String
    var isSelected = false
    var keyboardFocus: Bool? = nil
    let action: () -> Void
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: symbol).font(.system(size: 15, weight: .medium))
                    .foregroundStyle(isSelected ? Theme.accent : Theme.iconSecondary)
                    .frame(width: 20, height: 20).accessibilityHidden(true)
                Text(title).font(Theme.bodyStrong).foregroundStyle(Theme.textPrimary).lineLimit(1)
                Spacer(minLength: 0)
            }
            .opacity(isEnabled ? 1 : 0.45)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity).frame(height: 40)
            .background(isSelected ? Theme.accentSoft : isHovered && isEnabled ? Theme.hoverSurface : .clear,
                        in: .rect(cornerRadius: 14, style: .continuous))
            .overlay {
                if isSelected && (contrast == .increased || differentiateWithoutColor) {
                    RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Theme.accent)
                }
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .focusable(interactions: .edit)
        .onKeyPress(.space) {
            guard isEnabled else { return .ignored }
            action()
            return .handled
        }
        .keyboardFocusRing(RoundedRectangle(cornerRadius: 14, style: .continuous), isFocused: keyboardFocus)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .onHover { isHovered = $0 }
        .transaction { $0.animation = nil }
    }
}
