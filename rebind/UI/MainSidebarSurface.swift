import SwiftUI

/// Raised navigation glass from Sketch Foundations 04, with an opaque adaptive fallback.
struct MainSidebarSurface: View {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(reduceTransparency ? Color(.navigationOpaqueSurface) : Color(.navigationGlassTint))
            .glassEffect(reduceTransparency ? .identity : .regular,
                         in: .rect(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(contrast == .increased ? Color(.editorTextPrimary) : Color(.navigationRim),
                                  lineWidth: 1)
            }
            .shadow(color: Color(.navigationShadow), radius: 10, y: 6)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}
