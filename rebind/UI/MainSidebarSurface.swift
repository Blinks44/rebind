import SwiftUI

/// Raised sidebar panel from the Sketch design system (Surface/Sidebar).
struct MainSidebarSurface: View {
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(Theme.sidebarSurface)
            .shadow(color: Theme.shadowRaised, radius: 15, y: 10)
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(contrast == .increased ? Theme.borderStrong : Theme.borderHighlight)
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}
