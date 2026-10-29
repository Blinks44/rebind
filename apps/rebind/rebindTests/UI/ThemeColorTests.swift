import AppKit
import SwiftUI
import Testing
@testable import rebind

struct ThemeColorTests {
    // SwiftUI on macOS 15 resolves dynamic colors on its display-link thread; a main-actor
    // provider trapped there when a toggle animated.
    @Test @MainActor func adaptiveColorResolvesOffTheMainThread() async {
        nonisolated(unsafe) let color = NSColor(Color(light: 0xFF0000, dark: 0x0000FF))
        let red = await Task.detached { color.usingColorSpace(.sRGB)?.redComponent }.value
        #expect(red != nil)
    }
}
