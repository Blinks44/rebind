import Foundation

nonisolated enum InputTrigger: Codable, Hashable, Sendable {
    case key(UInt16)
    // Quartz is zero-based. UI Button 4 corresponds to Quartz index 3.
    case mouseButton(UInt32)
    case scroll(ScrollDirection)

    var scope: DeviceScope {
        switch self {
        case .key: .allKeyboards
        case .mouseButton, .scroll: .allMice
        }
    }

    var isSupported: Bool {
        switch self {
        case .key(let code): KeyboardShortcut.isSupportedKey(code)
        case .mouseButton(let number): number >= 2
        case .scroll: true
        }
    }
}
