import Foundation

nonisolated enum InputTrigger: Codable, Hashable, Sendable {
    case key(UInt16)
    // Quartz is zero-based. UI Button 4 corresponds to Quartz index 3.
    case mouseButton(UInt32)
    case mouseGesture(button: UInt32, direction: PointerDirection)
    case scroll(ScrollDirection)
    case fourFingerTap
    case threeFingerTap
    case threeFingerDoubleTap
    case fourFingerDoubleTap
    case twoFingerDoubleTap
    /// A one-finger light tap inside one corner region of the trackpad.
    case cornerTap(TrackpadCorner)
    /// A physical press of the trackpad with 2, 3 or 4 fingers resting on it.
    case trackpadClick(fingers: Int)

    var isTrackpad: Bool {
        switch self {
        case .fourFingerTap, .threeFingerTap, .threeFingerDoubleTap, .fourFingerDoubleTap,
             .twoFingerDoubleTap, .cornerTap, .trackpadClick: true
        default: false
        }
    }

    var isTrackpadDoubleTap: Bool {
        self == .threeFingerDoubleTap || self == .fourFingerDoubleTap || self == .twoFingerDoubleTap
    }

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
        case .fourFingerTap, .threeFingerTap, .threeFingerDoubleTap, .fourFingerDoubleTap,
             .twoFingerDoubleTap, .cornerTap, .trackpadClick: .builtInTrackpad
        case .key: .allKeyboards
        case .mouseButton, .mouseGesture, .scroll: .allMice
        }
    }

    var isSupported: Bool {
        switch self {
        case .key(let code): KeyboardShortcut.isSupportedKey(code)
        case .mouseButton(let number): number >= 2
        case .mouseGesture(let number, _): number >= 2
        case .scroll, .fourFingerTap, .threeFingerTap, .threeFingerDoubleTap, .fourFingerDoubleTap,
             .twoFingerDoubleTap, .cornerTap: true
        case .trackpadClick(let fingers): (2...4).contains(fingers)
        }
    }
}
