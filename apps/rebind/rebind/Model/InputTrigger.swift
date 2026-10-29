import Foundation

nonisolated enum InputTrigger: Codable, Hashable, Sendable {
    case key(UInt16)
    // Quartz is zero-based. UI Button 4 corresponds to Quartz index 3.
    case mouseButton(UInt32)
    case mouseGesture(button: UInt32, direction: PointerDirection)
    case scroll(ScrollDirection)
    /// A wheel step while a middle or extra button is held.
    case buttonScroll(button: UInt32, direction: ScrollDirection)
    case fourFingerTap
    case threeFingerTap
    case threeFingerDoubleTap
    case fourFingerDoubleTap
    case twoFingerDoubleTap
    /// A one-finger light tap inside one corner region of the trackpad.
    case cornerTap(TrackpadCorner)
    /// A physical press of the trackpad with 2, 3 or 4 fingers resting on it.
    case trackpadClick(fingers: Int)

    /// Experimental stationary single taps on the Magic Mouse surface.
    case magicMouseTap(fingers: Int)
    /// A one-finger stationary tap on the left or right half; it takes precedence over `magicMouseTap(fingers: 1)`.
    case magicMouseSideTap(MagicMouseSide)

    /// A physical press with three contacts, distinct from a light tap.
    case magicMouseClick(fingers: Int)
    /// Two-finger vertical finger movement; independent of Natural Scrolling.
    case magicMouseScroll(ScrollDirection)

    var isTouchGesture: Bool { isTrackpad || isMagicMouse }
    var isMagicMouse: Bool {
        switch self {
        case .magicMouseTap, .magicMouseSideTap, .magicMouseClick, .magicMouseScroll: true
        default: false
        }
    }

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

    /// Rules that act while their button stays down; the button's own click is decided on release.
    var holdsButton: Bool {
        switch self {
        case .mouseGesture, .buttonScroll: true
        default: false
        }
    }

    var pressSource: InputTrigger {
        switch self {
        case .mouseGesture(let button, _), .buttonScroll(let button, _): .mouseButton(button)
        default: self
        }
    }

    /// Only a key or a mouse button has a release to end a held output.
    var canHoldOutput: Bool {
        switch self {
        case .key, .mouseButton: true
        default: false
        }
    }

    var isScroll: Bool {
        if case .scroll = self { return true }
        return false
    }

    var scope: DeviceScope {
        switch self {
        case .fourFingerTap, .threeFingerTap, .threeFingerDoubleTap, .fourFingerDoubleTap,
             .twoFingerDoubleTap, .cornerTap, .trackpadClick: .builtInTrackpad
        case .magicMouseTap, .magicMouseSideTap, .magicMouseClick, .magicMouseScroll: .magicMouse
        case .key: .allKeyboards
        case .mouseButton, .mouseGesture, .scroll, .buttonScroll: .allMice
        }
    }

    var isSupported: Bool {
        switch self {
        case .key(let code): KeyboardShortcut.isSupportedKey(code)
        case .mouseButton(let number): number >= 2
        case .mouseGesture(let number, _), .buttonScroll(let number, _): number >= 2
        case .scroll, .fourFingerTap, .threeFingerTap, .threeFingerDoubleTap, .fourFingerDoubleTap,
             .twoFingerDoubleTap, .cornerTap, .magicMouseSideTap: true
        case .trackpadClick(let fingers): (2...4).contains(fingers)
        case .magicMouseTap(let fingers): (1...3).contains(fingers)
        case .magicMouseClick(let fingers): fingers == 3
        case .magicMouseScroll(let direction): direction == .up || direction == .down
        }
    }
}

extension InputTrigger {
    /// The Logitech gesture button, diverted to Rebind over HID++. Quartz never sees it, so it
    /// takes a button number far above any real one and works like any other mouse button.
    nonisolated static let gestureButton: UInt32 = 1000
}
