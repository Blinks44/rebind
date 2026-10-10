import CoreGraphics
import Dispatch
import Carbon
import ApplicationServices

nonisolated enum ShortcutSender {
    // Only our events carry this tag. Other apps' synthetic input remains eligible.
    static let eventTag: Int64 = 0x524542494E443031

    static func events(for shortcut: KeyboardShortcut) -> [CGEvent]? {
        guard shortcut.isSupported,
              let source = CGEventSource(stateID: .privateState),
              let down = CGEvent(keyboardEventSource: source, virtualKey: shortcut.keyCode, keyDown: true),
              let up = CGEvent(keyboardEventSource: source, virtualKey: shortcut.keyCode, keyDown: false) else {
            return nil
        }
        // Encode shortcut modifiers on the balanced key pair rather than posting
        // modifier key-downs that could overwrite physically held modifier state.
        // This slice sends a pulse once per press; it does not synthesize held keys.
        for event in [down, up] {
            event.flags = shortcut.modifiers.flags
            event.setIntegerValueField(.eventSourceUserData, value: eventTag)
        }
        return [down, up]
    }

    // The touch action keeps its captured target even if foreground changes in
    // the final posting race. No retry/acknowledgement or global modifier events.
    static func send(_ shortcut: KeyboardShortcut, to target: TrackpadDispatchTarget,
                     canPerform: @Sendable () -> Bool,
                     diagnose: @Sendable (TrackpadDiagnosticEvent) -> Void = { _ in }) -> WindowActionResult {
        let pid = target.pid
        guard canPerform() else { diagnose(.runtimeChanged); return .cancelled }
        guard pid > 0, kill(pid, 0) == 0 else { diagnose(.targetChanged); return .cancelled }
        guard AXIsProcessTrusted(), CGPreflightPostEventAccess(),
              !IsSecureEventInputEnabled(), ScreenLockSession.allowsInput() else {
            diagnose(.protectedContext); return .cancelled
        }
        guard CGEventSource.flagsState(.combinedSessionState)
            .intersection([.maskCommand, .maskControl, .maskAlternate, .maskShift, .maskSecondaryFn]).isEmpty else {
            diagnose(.heldModifier); return .cancelled
        }
        guard !(0..<64).contains(where: {
            CGEventSource.buttonState(.combinedSessionState, button: CGMouseButton(rawValue: UInt32($0)) ?? .left)
        }) else { diagnose(.heldButton); return .cancelled }
        guard !CGEventSource.keyState(.combinedSessionState, key: shortcut.keyCode) else {
            diagnose(.heldKey); return .cancelled
        }
        guard let events = events(for: shortcut) else { return .unavailable }
        // Reuse the existing public AX client on the serial worker to verify
        // current focus even if MainActor's workspace notification is delayed.
        let client = AXWindowAccessibility()
        guard let app = client.application, client.processID(of: app) == pid,
              canPerform() else { diagnose(.targetChanged); return .cancelled }
        guard DispatchTime.now().uptimeNanoseconds <= target.expiresAt else { diagnose(.outputExpired); return .cancelled }
        for event in events { event.postToPid(pid) }
        return .performed
    }

    static func send(_ shortcut: KeyboardShortcut) -> Bool {
        guard let events = events(for: shortcut) else { return false }
        for event in events { event.post(tap: .cgSessionEventTap) }
        // Quartz has no delivery acknowledgement; protected targets need manual validation.
        return true
    }
}
