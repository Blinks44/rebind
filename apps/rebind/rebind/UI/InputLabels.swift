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
            return AppLocalization.string(.physicalKey(Int(code)))
        }
        let data = Unmanaged<CFData>.fromOpaque(raw).takeUnretainedValue()
        guard let bytes = CFDataGetBytePtr(data) else { return AppLocalization.string(.physicalKey(Int(code))) }
        let layout = UnsafeRawPointer(bytes).assumingMemoryBound(to: UCKeyboardLayout.self)
        var deadKey: UInt32 = 0
        var length = 0
        var characters = [UniChar](repeating: 0, count: 8)
        let result = UCKeyTranslate(layout, code, UInt16(kUCKeyActionDisplay), 0, UInt32(LMGetKbdType()), OptionBits(kUCKeyTranslateNoDeadKeysBit), &deadKey, characters.count, &length, &characters)
        guard result == noErr, length > 0 else { return AppLocalization.string(.physicalKey(Int(code))) }
        return String(utf16CodeUnits: characters, count: length).uppercased()
    }

    static func trigger(_ trigger: InputTrigger, modifiers: ModifierSet) -> String {
        let label: String
        switch trigger {
        case .magicMouseTap, .magicMouseSideTap, .magicMouseClick, .magicMouseScroll:
            label = AppLocalization.string((MagicMousePreset(trigger: trigger) ?? .oneFingerTap).title)
        case .fourFingerTap: label = AppLocalization.string(.fourFingerTap)
        case .threeFingerTap: label = AppLocalization.string(.threeFingerTap)
        case .threeFingerDoubleTap: label = AppLocalization.string(.threeFingerDoubleTap)
        case .fourFingerDoubleTap: label = AppLocalization.string(.fourFingerDoubleTap)
        case .twoFingerDoubleTap: label = AppLocalization.string(.twoFingerDoubleTap)
        case .cornerTap(let corner): label = AppLocalization.string(corner.title)
        case .trackpadClick(let fingers): label = AppLocalization.string(TrackpadPreset.clickTitle(fingers: fingers))
        case .key(let code): label = key(code)
        case .mouseButton(let number): label = buttonName(number)
        case .mouseGesture(let button, let direction):
            label = buttonGesture(button, direction: AppLocalization.string(direction.label))
        case .scroll(let direction): label = AppLocalization.string(direction.label)
        case .buttonScroll(let button, let direction):
            label = buttonGesture(button, direction: AppLocalization.string(direction.label))
        }
        switch trigger {
        case .mouseButton, .mouseGesture, .scroll, .buttonScroll:
            return modifiers.glyphs.isEmpty ? label : modifiers.glyphs + " " + label
        default:
            if trigger.isTouchGesture, !modifiers.glyphs.isEmpty { return modifiers.glyphs + " " + label }
            return modifiers.glyphs + label
        }
    }

    /// "Button 4", or the name of a button Quartz does not number, such as the gesture button.
    static func buttonName(_ number: UInt32) -> String {
        number == InputTrigger.gestureButton ? AppLocalization.string(.gestureButton)
            : AppLocalization.string(.mouseButton(Int(number) + 1))
    }

    private static func buttonGesture(_ button: UInt32, direction: String) -> String {
        button == InputTrigger.gestureButton ? AppLocalization.string(.gestureButtonGesture(direction.lowercased()))
            : AppLocalization.string(.mouseGesture(Int(button) + 1, direction.lowercased()))
    }

    static func shortcut(_ shortcut: KeyboardShortcut) -> String { trigger(.key(shortcut.keyCode), modifiers: shortcut.modifiers) }
}

extension ModifierSet {
    /// Name of a single modifier choice for a trackpad gesture.
    var choiceTitle: LocalizedStringResource {
        switch self {
        case .command: .modifierCommand
        case .option: .modifierOption
        case .control: .modifierControl
        case .shift: .modifierShift
        default: .trackpadModifierNone
        }
    }
}

extension MouseWheelSpeed {
    var label: LocalizedStringResource {
        switch self {
        case .standard: .mouseWheelSpeedStandard
        case .fast: .mouseWheelSpeedFast
        case .faster: .mouseWheelSpeedFaster
        }
    }
}

extension PointerGestureDistance {
    var label: LocalizedStringResource {
        switch self {
        case .short: .gestureDistanceShort
        case .standard: .gestureDistanceStandard
        case .long: .gestureDistanceLong
        }
    }
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
    /// The bare direction, for a picker whose title already says it is the wheel.
    var directionLabel: LocalizedStringResource {
        switch self {
        case .up: .pointerUp
        case .down: .pointerDown
        case .left: .pointerLeft
        case .right: .pointerRight
        }
    }

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

extension DeviceScope {
    var title: LocalizedStringResource {
        switch self {
        case .allKeyboards: .allKeyboards
        case .allMice: .allMice
        case .builtInTrackpad: .builtInTrackpad
        case .magicTrackpad: LocalizedStringResource("magicTrackpadNavigationTitle", table: "Navigation")
        case .magicMouse: LocalizedStringResource("magicMouseNavigationTitle", table: "Navigation")
        }
    }
    var symbol: String {
        switch self {
        case .allKeyboards: "keyboard"
        case .allMice: "computermouse"
        case .builtInTrackpad: "rectangle.and.hand.point.up.left"
        case .magicTrackpad: "hand.tap"
        case .magicMouse: "magicmouse"
        }
    }
}

extension TrackpadCaptureStatus {
    var text: LocalizedStringResource {
        switch self {
        case .idle: .trackpadIdle
        case .active: .trackpadActive
        case .unavailable: .trackpadUnavailable
        case .failed: .trackpadFailed
        }
    }
}

nonisolated extension TrackpadCorner {
    var title: LocalizedStringResource {
        switch self {
        case .topLeft: .trackpadTopLeftCornerTap
        case .topRight: .trackpadTopRightCornerTap
        case .bottomLeft: .trackpadBottomLeftCornerTap
        case .bottomRight: .trackpadBottomRightCornerTap
        }
    }
}
