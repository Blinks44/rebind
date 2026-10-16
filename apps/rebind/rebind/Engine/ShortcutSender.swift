import CoreGraphics
import Dispatch
import Carbon
import ApplicationServices
import AppKit

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
        for event in [down, up] {
            event.flags = shortcut.modifiers.flags
            event.setIntegerValueField(.eventSourceUserData, value: eventTag)
        }
        return [down, up]
    }

    /// One half of a held key or modifier. The pair is balanced by the mailbox, which always
    /// issues a release for a press it handed out.
    static func postHeldKey(_ command: HeldKeyCommand) {
        for event in heldKeyEvents(command) { event.post(tap: .cgSessionEventTap) }
    }

    static func heldKeyEvents(_ command: HeldKeyCommand,
                              physicalModifiers: CGEventFlags = CGEventSource.flagsState(.hidSystemState)) -> [CGEvent] {
        guard let source = CGEventSource(stateID: .privateState) else { return [] }
        switch command.target {
        case .shortcut(let shortcut):
            guard shortcut.isSupported,
                  let event = CGEvent(keyboardEventSource: source, virtualKey: shortcut.keyCode,
                                      keyDown: command.phase != .release) else { return [] }
            event.flags = shortcut.modifiers.union(command.otherModifiers).flags
            event.setIntegerValueField(.eventSourceUserData, value: eventTag)
            if command.phase == .repeatPress { event.setIntegerValueField(.keyboardEventAutorepeat, value: 1) }
            return [event]
        case .modifiers(let modifiers):
            // Apps that track modifier state see an ordinary modifier press; the tap adds the
            // same flags to the hardware events that follow, which Quartz would not do itself.
            let keys: [(ModifierSet, CGKeyCode)] = [(.command, 55), (.shift, 56), (.option, 58), (.control, 59)]
            return keys.filter { modifiers.contains($0.0) }.compactMap { _, key in
                guard let event = CGEvent(keyboardEventSource: source, virtualKey: key, keyDown: command.phase != .release) else { return nil }
                event.type = .flagsChanged
                let remaining = command.phase == .release ? command.otherModifiers : modifiers.union(command.otherModifiers)
                event.flags = physicalModifiers.union(remaining.flags)
                event.setIntegerValueField(.eventSourceUserData, value: eventTag)
                return event
            }
        }
    }

    // The touch action keeps its captured target even if foreground changes in
    // the final posting race. No retry/acknowledgement or global modifier events.
    static func send(_ shortcut: KeyboardShortcut, to target: TrackpadDispatchTarget,
                     canPerform: @Sendable () -> Bool,
                     diagnose: @Sendable (TrackpadDiagnosticEvent) -> Void = { _ in },
                     allowsInput: () -> Bool = {
                         AXIsProcessTrusted() && CGPreflightPostEventAccess()
                             && !IsSecureEventInputEnabled() && ScreenLockSession.allowsInput()
                     },
                     blockedInput: ((KeyboardShortcut) -> TrackpadDiagnosticEvent?)? = nil,
                     targetIsActive: (Int32) -> Bool = applicationIsActive,
                     clock: () -> UInt64 = { DispatchTime.now().uptimeNanoseconds },
                     post: (CGEvent, Int32) -> Void = { $0.postToPid($1) }) -> WindowActionResult {
        let pid = target.pid
        // The modifier a rule requires is necessarily down; any other held input still blocks.
        let blockedInput = blockedInput ?? { heldInput($0, allowing: target.modifiers) }
        guard canPerform() else { diagnose(.runtimeChanged); return .cancelled }
        guard pid > 0, pid != getpid(), targetIsActive(pid) else { diagnose(.outputTargetInactive); return .cancelled }
        guard allowsInput() else {
            diagnose(.protectedContext); return .cancelled
        }
        if let reason = blockedInput(shortcut) { diagnose(reason); return .cancelled }
        guard let events = events(for: shortcut) else { return .unavailable }
        // NSRunningApplication's atomic properties are documented thread-safe.
        // Recheck the captured process without AX IPC to the target's UI tree.
        // Main-run-loop caching still applies; mailbox focus/activity checks and
        // PID-directed output preserve cancellation and never retarget the pair.
        guard targetIsActive(pid) else { diagnose(.outputTargetInactive); return .cancelled }
        guard canPerform() else { diagnose(.runtimeChanged); return .cancelled }
        guard allowsInput() else { diagnose(.protectedContext); return .cancelled }
        if let reason = blockedInput(shortcut) { diagnose(reason); return .cancelled }
        let postingTime = clock()
        guard postingTime <= target.expiresAt else { diagnose(.outputExpired); return .cancelled }
        for event in events { post(event, pid) }
        // Reporting cannot insert a mailbox-lock wait between final expiry
        // validation and the balanced pair; the sample is from before posting.
        if postingTime >= target.queuedAt {
            diagnose(.postedQueueAge(nanoseconds: postingTime - target.queuedAt))
        }
        return .performed
    }

    private static func applicationIsActive(_ pid: Int32) -> Bool {
        guard let app = NSRunningApplication(processIdentifier: pid) else { return false }
        return app.isActive && !app.isTerminated && app.activationPolicy == .regular
    }

    private static func heldInput(_ shortcut: KeyboardShortcut, allowing allowed: ModifierSet) -> TrackpadDiagnosticEvent? {
        guard CGEventSource.flagsState(.combinedSessionState)
            .intersection([.maskCommand, .maskControl, .maskAlternate, .maskShift, .maskSecondaryFn])
            .subtracting(allowed.flags).isEmpty else {
            return .heldModifier
        }
        guard !(0..<64).contains(where: {
            CGEventSource.buttonState(.combinedSessionState, button: CGMouseButton(rawValue: UInt32($0)) ?? .left)
        }) else { return .heldButton }
        guard !CGEventSource.keyState(.combinedSessionState, key: shortcut.keyCode) else {
            return .heldKey
        }
        return nil
    }

    static func send(_ shortcut: KeyboardShortcut) -> Bool {
        guard let events = events(for: shortcut) else { return false }
        for event in events { event.post(tap: .cgSessionEventTap) }
        // Quartz has no delivery acknowledgement; protected targets need manual validation.
        return true
    }
}
