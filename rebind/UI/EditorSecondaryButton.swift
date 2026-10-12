import SwiftUI

struct EditorSecondaryButton: ViewModifier {
    func body(content: Content) -> some View {
        content.buttonStyle(EditorCapsuleButtonStyle())
    }
}

/// The source disables specular highlights. Native glass cannot suppress its rim,
/// so content-card actions use the authored wash and quiet inner lighting.
private struct EditorCapsuleButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.colorScheme) private var colorScheme

    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        configuration.label
            .font(EditorTypography.body)
            .foregroundStyle(isEnabled ? Color(.editorAccentText) : Color(.editorTextSecondary))
            .padding(.horizontal, 16)
            .frame(minHeight: EditorMetrics.buttonHeight)
            .background {
                Capsule().fill(surface)
                    .background {
                        if reduceTransparency { Capsule().fill(Color(.permissionSurface)) }
                    }
                    .overlay {
                        if isEnabled && configuration.isPressed {
                            Capsule().fill(Color(.editorSelection).opacity(0.08))
                        }
                    }
            }
            .overlay {
                if contrast == .increased {
                    Capsule().strokeBorder(Color(.editorAccentText))
                }
            }
            .contentShape(.capsule)
    }

    private var surface: AnyShapeStyle {
        guard isEnabled else { return AnyShapeStyle(Color(.permissionSurface)) }
        let wash = Color(.editorAccentWash)
        if reduceTransparency { return AnyShapeStyle(wash) }
        return AnyShapeStyle(wash.shadow(.inner(
            color: .white.opacity(colorScheme == .light ? 0.7 : 0.12),
            radius: 0.25, x: 0, y: 0.5)))
    }
}
