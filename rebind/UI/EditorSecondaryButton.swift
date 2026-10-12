import SwiftUI

struct EditorSecondaryButton: ViewModifier {
    func body(content: Content) -> some View {
        content.buttonStyle(SecondaryButtonStyle()).keyboardFocusRing()
    }
}

/// White raised capsule for secondary actions: 28 pt, or 36 pt with `.controlSize(.large)`.
struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.controlSize) private var controlSize

    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        let isLarge = controlSize == .large
        configuration.label
            .font(isLarge ? Theme.bodyStrong : Theme.calloutStrong)
            .foregroundStyle(Theme.textPrimary)
            .padding(.horizontal, isLarge ? 18 : 14)
            .frame(minHeight: isLarge ? Theme.controlHeight : EditorMetrics.buttonHeight)
            .modifier(ControlSurface())
            .opacity(isEnabled ? (configuration.isPressed ? 0.7 : 1) : 0.45)
            .contentShape(.capsule)
    }
}
