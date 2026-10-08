import Foundation

nonisolated enum InputTrigger: Codable, Hashable, Sendable {
    case key(UInt16)
    // Quartz is zero-based. UI Button 4 corresponds to Quartz index 3.
    case mouseButton(UInt32)
    case mouseGesture(button: UInt32, direction: PointerDirection)
    case scroll(ScrollDirection)

    var isPointerGesture: Bool {
        if case .mouseGesture = self { return true }
        return false
    }

    var pressSource: InputTrigger {
        if case .mouseGesture(let button, _) = self { return .mouseButton(button) }
        return self
    }

    var isScroll: Bool {
        if case .scroll = self { return true }
        return false
    }

    var scope: DeviceScope {
        switch self {
        case .key: .allKeyboards
        case .mouseButton, .mouseGesture, .scroll: .allMice
        }
    }

    var isSupported: Bool {
        switch self {
        case .key(let code): KeyboardShortcut.isSupportedKey(code)
        case .mouseButton(let number): number >= 2
        case .mouseGesture(let number, _): number >= 2
        case .scroll: true
        }
    }
}
