import SwiftUI

/// Unadorned appearance for controls whose label already draws its surface.
struct KeyboardPlainAppearance: ButtonStyle {
    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        configuration.label.opacity(configuration.isPressed ? 0.8 : 1)
    }
}
