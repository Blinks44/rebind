import SwiftUI

/// One adaptive material for editor selectors and native activation tracks.
struct EditorGlassSurface: ViewModifier {
    var interactive = true
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background {
                if reduceTransparency { Capsule().fill(Color(.permissionSurface)) }
            }
            .glassEffect(reduceTransparency ? .identity : glass, in: .capsule)
            .overlay {
                if contrast == .increased {
                    Capsule().strokeBorder(Color(nsColor: .separatorColor))
                } else if colorScheme == .light && !reduceTransparency {
                    Capsule().strokeBorder(.white.opacity(0.9))
                }
            }
    }

    private var glass: Glass {
        // Light Sketch controls use a luminous neutral material rather than dark control chrome.
        .clear.tint(colorScheme == .light ? .white.opacity(0.2) : .white.opacity(0.04))
            .interactive(interactive)
    }
}
