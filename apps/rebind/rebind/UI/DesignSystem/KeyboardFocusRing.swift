import AppKit
import SwiftUI

/// Whether focus is currently moved by the keyboard. Themed controls show their focus ring
/// only then, so a mouse click never leaves an outline behind. Observes event kinds only.
@Observable final class KeyboardFocusVisibility {
    static let shared = KeyboardFocusVisibility()
    private(set) var isKeyboardDriven = false
    private var monitor: Any?

    private init() {
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .leftMouseDown]) { event in
            let isKeyboard = event.type == .keyDown
            MainActor.assumeIsolated {
                if Self.shared.isKeyboardDriven != isKeyboard { Self.shared.isKeyboardDriven = isKeyboard }
            }
            return event
        }
    }
}

/// Replaces the system focus effect with an accent outline that follows the control's shape.
struct KeyboardFocusRing<Outline: InsettableShape>: ViewModifier {
    let shape: Outline
    @FocusState private var isFocused: Bool

    func body(content: Content) -> some View {
        content.focused($isFocused)
            .modifier(KeyboardFocusAppearance(shape: shape, isFocused: isFocused))
    }
}

/// Decorates a control's existing focus state without installing a competing binding.
private struct KeyboardFocusAppearance<Outline: InsettableShape>: ViewModifier {
    let shape: Outline
    let isFocused: Bool

    func body(content: Content) -> some View {
        content.focusEffectDisabled()
            .overlay {
                if isFocused && KeyboardFocusVisibility.shared.isKeyboardDriven {
                    shape.strokeBorder(Theme.accent, lineWidth: 2).allowsHitTesting(false)
                }
            }
    }
}

extension View {
    /// For a control that already tracks its own focus state.
    func keyboardFocusRing(_ shape: some InsettableShape = Capsule(style: .circular), isFocused: Bool) -> some View {
        modifier(KeyboardFocusAppearance(shape: shape, isFocused: isFocused))
    }

    func keyboardFocusRing(_ shape: some InsettableShape = Capsule(style: .circular)) -> some View {
        modifier(KeyboardFocusRing(shape: shape))
    }
}
