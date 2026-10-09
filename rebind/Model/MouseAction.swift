import CoreGraphics

nonisolated enum MouseAction: String, Codable, CaseIterable, Sendable {
    case leftClick, rightClick, middleClick, doubleLeftClick

    var button: CGMouseButton {
        switch self {
        case .leftClick, .doubleLeftClick: .left
        case .rightClick: .right
        case .middleClick: .center
        }
    }

    var clickCount: Int { self == .doubleLeftClick ? 2 : 1 }

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
