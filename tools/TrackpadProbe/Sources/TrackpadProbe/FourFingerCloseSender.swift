import AppKit
// SDK imports the immutable AX prompt key as a mutable global. Permission
// requests and access to that key remain confined to MainActor, as in Rebind.
@preconcurrency import ApplicationServices

@MainActor enum FourFingerCloseSender {
    enum Outcome: String {
        case posted, protectedSession = "protected-session", permissionUnavailable = "permission-unavailable"
        case heldModifiers = "held-modifiers", heldButton = "held-button", heldW = "held-output-key"
        case eventCreationFailed = "event-creation-failed", foregroundChanged = "foreground-changed"
    }
    static func access() -> ProbeTestAccess {
        ProbeTestAccess(accessibility: AXIsProcessTrusted(), posting: CGPreflightPostEventAccess())
    }

    static func allowed() -> Bool { access().allowed }

    // Called only by --request-test-access, never by capture or polling.
    static func request(_ request: ProbeTestAccess.Request) {
        switch request {
        case .accessibility:
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
            _ = AXIsProcessTrustedWithOptions(options)
        case .eventPosting:
            _ = CGRequestPostEventAccess()
        }
    }

    static func target() -> pid_t? {
        guard let app = NSWorkspace.shared.frontmostApplication,
              app.activationPolicy == .regular, !app.isTerminated,
              app.processIdentifier > 0,
              app.processIdentifier != ProcessInfo.processInfo.processIdentifier else { return nil }
        return app.processIdentifier
    }

    // Prepares both events before posting either. Tests construct these without
    // calling send. Match Rebind's balanced private-source/tagged shortcut recipe.
    static func events() -> [CGEvent]? {
        guard let source = CGEventSource(stateID: .privateState) else { return nil }
        source.userData = PassiveButtonProbe.rebindTag
        guard let down = CGEvent(keyboardEventSource: source, virtualKey: 13, keyDown: true),
              let up = CGEvent(keyboardEventSource: source, virtualKey: 13, keyDown: false) else { return nil }
        for event in [down, up] {
            event.flags = .maskCommand
            event.setIntegerValueField(.eventSourceUserData, value: PassiveButtonProbe.rebindTag)
        }
        return [down, up]
    }

    static func send(to expectedTarget: pid_t) -> Outcome {
        let modifiers: CGEventFlags = [.maskShift, .maskControl, .maskAlternate, .maskCommand, .maskSecondaryFn]
        guard ProbeSession.allowsCapture() else { return .protectedSession }
        guard allowed() else { return .permissionUnavailable }
        guard CGEventSource.flagsState(.combinedSessionState).intersection(modifiers).isEmpty else { return .heldModifiers }
        guard NSEvent.pressedMouseButtons == 0 else { return .heldButton }
        guard !CGEventSource.keyState(.combinedSessionState, key: 13) else { return .heldW }
        guard let events = events() else { return .eventCreationFailed }
        guard target() == expectedTarget else { return .foregroundChanged }
        // Targeted posting avoids redirecting to a different app in the small
        // interval after the foreground check. No delivery acknowledgement.
        for event in events { event.postToPid(expectedTarget) }
        return .posted
    }
}
