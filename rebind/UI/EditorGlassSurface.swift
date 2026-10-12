import SwiftUI

/// One adaptive material for editor selectors and native activation tracks.
struct EditorGlassSurface: ViewModifier {
    var interactive = true
    var distinctSurface = false
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background {
                if distinctSurface {
                    Capsule().fill(Color(.compactSelectorSurface))
                        .shadow(color: Color(.compactSelectorShadow), radius: 3, y: 1)
                } else if reduceTransparency {
                    Capsule().fill(Color(.permissionSurface))
                }
            }
            .glassEffect(reduceTransparency ? .identity : glass, in: .capsule)
            .overlay {
                if distinctSurface {
                    Capsule().strokeBorder(contrast == .increased ? Color(.editorTextPrimary) : Color(.compactSelectorEdge))
                } else if contrast == .increased {
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
