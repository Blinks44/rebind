import CoreGraphics

nonisolated enum MouseAction: String, Codable, CaseIterable, Sendable {
    case leftClick, rightClick, middleClick, doubleLeftClick
    /// Quartz buttons 3 and 4, which browsers and Finder treat as Back and Forward.
    case backClick, forwardClick
    case scrollUp, scrollDown, scrollLeft, scrollRight

    var button: CGMouseButton {
        switch self {
        case .leftClick, .doubleLeftClick: .left
        case .rightClick: .right
        case .middleClick: .center
        case .backClick: CGMouseButton(rawValue: 3) ?? .center
        case .forwardClick: CGMouseButton(rawValue: 4) ?? .center
        case .scrollUp, .scrollDown, .scrollLeft, .scrollRight: .center
        }
    }

    /// Back/Forward and scroll actions, which files older than schema 31 cannot carry.
    var isNewInSchema31: Bool { self == .backClick || self == .forwardClick || scrollLines != nil }

    var clickCount: Int { self == .doubleLeftClick ? 2 : 1 }

    /// Line deltas for a scroll action; nil for clicks. Positive vertical scrolls up, positive horizontal left.
    var scrollLines: (vertical: Int32, horizontal: Int32)? {
        switch self {
        case .scrollUp: (3, 0)
        case .scrollDown: (-3, 0)
        case .scrollLeft: (0, 3)
        case .scrollRight: (0, -3)
        default: nil
        }
    }

    var downType: CGEventType {
        switch button {
        case .left: .leftMouseDown
        case .right: .rightMouseDown
        default: .otherMouseDown
        }
    }

    var upType: CGEventType {
        switch button {
        case .left: .leftMouseUp
        case .right: .rightMouseUp
        default: .otherMouseUp
        }
    }
}
