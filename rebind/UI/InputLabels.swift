import Carbon
import Foundation

enum InputLabels {
    static func key(_ code: UInt16) -> String {
        let special: [UInt16: String] = [36: "↩", 48: "⇥", 49: "␣", 51: "⌫", 53: "⎋", 76: "⌤", 117: "⌦", 123: "←", 124: "→", 125: "↓", 126: "↑", 115: "↖", 119: "↘", 116: "⇞", 121: "⇟"]
        if let label = special[code] { return label }
        let functionKeys: [UInt16: Int] = [122: 1, 120: 2, 99: 3, 118: 4, 96: 5, 97: 6, 98: 7, 100: 8, 101: 9, 109: 10, 103: 11, 111: 12, 105: 13, 107: 14, 113: 15, 106: 16, 64: 17, 79: 18, 80: 19, 90: 20]
        if let number = functionKeys[code] { return "F\(number)" }
        // Translate an explicitly configured physical key, never received typed text.
        guard let source = TISCopyCurrentKeyboardLayoutInputSource()?.takeRetainedValue(),
              let raw = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData) else {
            return String(localized: .physicalKey(Int(code)))
        }
        let data = Unmanaged<CFData>.fromOpaque(raw).takeUnretainedValue()
        guard let bytes = CFDataGetBytePtr(data) else { return String(localized: .physicalKey(Int(code))) }
        let layout = UnsafeRawPointer(bytes).assumingMemoryBound(to: UCKeyboardLayout.self)
        var deadKey: UInt32 = 0
        var length = 0
        var characters = [UniChar](repeating: 0, count: 8)
        let result = UCKeyTranslate(layout, code, UInt16(kUCKeyActionDisplay), 0, UInt32(LMGetKbdType()), OptionBits(kUCKeyTranslateNoDeadKeysBit), &deadKey, characters.count, &length, &characters)
        guard result == noErr, length > 0 else { return String(localized: .physicalKey(Int(code))) }
        return String(utf16CodeUnits: characters, count: length).uppercased()
    }

    static func trigger(_ trigger: InputTrigger, modifiers: ModifierSet) -> String {
        let label: String
        switch trigger {
        case .key(let code): label = key(code)
        case .mouseButton(let number): label = String(localized: .mouseButton(Int(number) + 1))
        case .mouseGesture(let button, let direction):
            label = String(localized: .mouseGesture(Int(button) + 1, String(localized: direction.label)))
        case .scroll(let direction): label = String(localized: direction.label)
        }
        return modifiers.glyphs + label
    }

    static func shortcut(_ shortcut: KeyboardShortcut) -> String { trigger(.key(shortcut.keyCode), modifiers: shortcut.modifiers) }
}

extension PointerDirection {
    var label: LocalizedStringResource {
        switch self {
        case .left: .pointerLeft
        case .right: .pointerRight
        case .up: .pointerUp
        case .down: .pointerDown
        }
    }
}

extension ScrollDirection {
    var label: LocalizedStringResource {
        switch self {
        case .up: .scrollUp
        case .down: .scrollDown
        case .left: .scrollLeft
        case .right: .scrollRight
        }
    }
}

extension EngineStatus {
    var text: LocalizedStringResource {
        switch self {
        case .paused: .enginePaused
        case .active: .engineActive
        case .permissionRequired: .permissionsRequired
        case .secureInput: .secureInputPaused
        case .tapFailed: .tapCreationFailed
        case .interrupted: .engineInterrupted
        case .outputFailed: .outputFailed
        }
    }
}
