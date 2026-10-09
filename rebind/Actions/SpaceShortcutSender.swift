import CoreGraphics
import Foundation

// HID shortcut recipe checked against spacekit (MIT); see ThirdPartyNotices.txt.
// Unlike a Dock swipe, this asks macOS to run its normal Space hotkey, including
// its animation, display selection, Reduce Motion and first/last-Space handling.
nonisolated enum SpaceShortcutSender {
    static func perform(_ action: DesktopAction, canPerform: () -> Bool,
                        preferences: () -> Any? = systemPreferences,
                        build: (DesktopAction) -> [CGEvent]? = { events($0) },
                        post: (CGEvent, CGEventTapLocation) -> Void = { $0.post(tap: $1) }) -> WindowActionResult {
        guard action.isSpaceNavigation else { return .unavailable }
        guard canPerform() else { return .cancelled }
        // Never deliver Ctrl+Arrow into an application when the system hotkey
        // is explicitly disabled or assigned a different chord.
        guard usesStandardShortcut(action, preferences: preferences()),
              let pair = build(action), pair.count == 2 else { return .unavailable }
        guard canPerform() else { return .cancelled }
        // Once down is posted, finish the balanced pair even if cancellation
        // arrives. No modifier key transitions or synthetic held state to restore.
        for event in pair { post(event, .cghidEventTap) }
        return .performed // Quartz does not acknowledge the resulting visual effect.
    }

    static func events(_ action: DesktopAction,
                       source: () -> CGEventSource? = { CGEventSource(stateID: .hidSystemState) },
                       make: (CGEventSource, CGKeyCode, Bool) -> CGEvent? = {
                           CGEvent(keyboardEventSource: $0, virtualKey: $1, keyDown: $2)
                       }) -> [CGEvent]? {
        guard let key = keyCode(for: action), let source = source(),
              let down = make(source, key, true), let up = make(source, key, false) else { return nil }
        for event in [down, up] {
            // Arrow keys carry the secondary-Fn bit. Replace all inherited
            // flags, including low device-specific Command/Option bits.
            event.flags = [.maskControl, .maskSecondaryFn]
            event.setIntegerValueField(.keyboardEventAutorepeat, value: 0)
            event.setIntegerValueField(.eventSourceUserData, value: ShortcutSender.eventTag)
        }
        return [down, up]
    }

    static func usesStandardShortcut(_ action: DesktopAction, preferences: Any?) -> Bool {
        guard let key = keyCode(for: action) else { return false }
        // Missing overrides mean macOS defaults. The preference schema/IDs are
        // undocumented; malformed or customized entries fail closed. No writes.
        guard let preferences else { return true }
        guard let hotkeys = preferences as? [String: Any] else { return false }
        guard let value = hotkeys[action == .previousSpace ? "79" : "81"] else { return true }
        guard let entry = value as? [String: Any], let enabled = entry["enabled"] as? NSNumber,
              CFGetTypeID(enabled) == CFBooleanGetTypeID(), enabled.boolValue else { return false }
        guard let value = entry["value"] else { return true }
        guard let shortcut = value as? [String: Any], shortcut["type"] as? String == "standard",
              let parameters = shortcut["parameters"] as? [Int], parameters.count == 3,
              parameters[1] == Int(key) else { return false }
        let flags = UInt64(CGEventFlags.maskControl.rawValue)
        return parameters[2] == Int(flags)
            || parameters[2] == Int(flags | CGEventFlags.maskSecondaryFn.rawValue)
    }

    private static func keyCode(for action: DesktopAction) -> CGKeyCode? {
        switch action {
        case .previousSpace: 123
        case .nextSpace: 124
        default: nil
        }
    }

    private static func systemPreferences() -> Any? {
        // Called only on the action worker, never in the synchronous tap or a
        // mailbox lock. Read the two relevant entries; never modify OS settings.
        CFPreferencesCopyAppValue("AppleSymbolicHotKeys" as CFString,
                                  "com.apple.symbolichotkeys" as CFString)
    }
}
