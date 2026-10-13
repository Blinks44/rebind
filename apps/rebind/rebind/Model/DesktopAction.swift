nonisolated enum DesktopAction: String, Codable, CaseIterable, Sendable {
    case missionControl, applicationWindows, showDesktop, previousSpace, nextSpace

    var dockNotification: String? {
        switch self {
        case .missionControl: "com.apple.expose.awake"
        case .applicationWindows: "com.apple.expose.front.awake"
        case .showDesktop: "com.apple.showdesktop.awake"
        case .previousSpace, .nextSpace: nil
        }
    }

    var isSpaceNavigation: Bool { self == .previousSpace || self == .nextSpace }
}
