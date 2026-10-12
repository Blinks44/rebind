import SwiftUI

/// Accent capsule for the one primary action of a screen: 36 pt, or 28 pt with `.controlSize(.small)`.
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.controlSize) private var controlSize

    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        let isSmall = controlSize == .small || controlSize == .mini
        configuration.label
            .font(isSmall ? Theme.calloutStrong : Theme.bodyBold).foregroundStyle(.white)
            .padding(.horizontal, isSmall ? 14 : 17)
            .frame(height: isSmall ? Theme.smallControlHeight : Theme.controlHeight)
            .background {
                Capsule(style: .circular).fill(Theme.accentFill)
                    .overlay {
                        Capsule(style: .circular).fill(LinearGradient(stops: [.init(color: .white.opacity(0.24), location: 0),
                                                              .init(color: .white.opacity(0), location: 0.55)],
                                                      startPoint: .top, endPoint: .bottom))
                    }
                    .shadow(color: Theme.accentGlow, radius: 8, y: 6)
            }
            .overlay { Capsule(style: .circular).strokeBorder(.white.opacity(0.3)) }
            .opacity(isEnabled ? (configuration.isPressed ? 0.85 : 1) : 0.4)
            .contentShape(.capsule)
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
            .frame(minHeight: isLarge ? Theme.controlHeight : Theme.smallControlHeight)
            .modifier(ControlSurface())
            .opacity(isEnabled ? (configuration.isPressed ? 0.7 : 1) : 0.45)
            .contentShape(.capsule)
    }
}

/// Soft red capsule for a destructive action that still asks for confirmation.
struct DestructiveButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        configuration.label
            .font(Theme.bodyStrong).foregroundStyle(Theme.dangerText)
            .padding(.horizontal, 18).frame(height: Theme.controlHeight)
            .background {
                Capsule(style: .circular).fill(Theme.danger.opacity(0.12)).strokeBorder(Theme.danger.opacity(0.25))
            }
            .opacity(isEnabled ? (configuration.isPressed ? 0.7 : 1) : 0.45)
            .contentShape(.capsule)
    }
}

extension View {
    /// Apply these to one `Button` each, so every button gets its own keyboard focus ring.
    func primaryButton() -> some View { buttonStyle(PrimaryButtonStyle()).keyboardFocusRing() }
    func secondaryButton() -> some View { buttonStyle(SecondaryButtonStyle()).keyboardFocusRing() }
    func destructiveButton() -> some View { buttonStyle(DestructiveButtonStyle()).keyboardFocusRing() }
}
