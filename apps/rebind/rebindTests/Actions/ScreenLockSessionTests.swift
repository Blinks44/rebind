import AppKit
import ApplicationServices
import Testing
@testable import rebind

struct ScreenLockSessionTests {
    @Test(arguments: 0...8) func onlyKnownUnlockedConsoleSessionAllowsInput(_ scenario: Int) {
        let onConsole = kCGSessionOnConsoleKey as String, locked = "CGSSessionScreenIsLocked"
        let sessions: [[String: Any]?] = [nil, [:], [onConsole: true], [onConsole: true, locked: false],
            [onConsole: true, locked: true], [onConsole: false], [onConsole: 1],
            [onConsole: true, locked: 0], [onConsole: true, locked: "false"]]
        #expect(ScreenLockSession.allowsInput(session: sessions[scenario]) == (scenario == 2 || scenario == 3))
    }

    @Test @MainActor func nativePollingSuspendsAndCancelsRecordingForLockedOrUnknownSession() {
        let model = AppModel(loadConfiguration: false, sessionAllowsInput: { false })
        let request = RecordingRequest(target: .mouseTrigger)
        model.recording = request
        model.mailbox.record(request)
        model.mailbox.configure(Configuration(isEnabled: true))
        #expect(model.mailbox.startDiagnostics(at: 0))
        #expect(model.mailbox.handle(InputEvent(trigger: .mouseButton(99), phase: .down, receivedAt: 1), secureInput: false))
        #expect(model.mailbox.state.withLock { !$0.diagnostics.snapshot().entries.isEmpty })
        model.mailbox.state.withLock { $0.pending = [.media(.playPause)] }
        model.refresh()
        #expect(model.recording == nil && !model.canRecord && !model.canStartDiagnostics)
        #expect(model.mailbox.state.withLock { $0.suspended && $0.enabled && $0.pending.isEmpty && $0.recording == nil })
        let snapshot = model.mailbox.state.withLock { $0.diagnostics.snapshot() }
        #expect(!snapshot.isRunning && snapshot.entries.isEmpty)
    }

    @Test @MainActor func lockNotificationImmediatelySuspendsAndUnlockNeedsNativeConfirmation() {
        var nativeAllows = false
        let model = AppModel(loadConfiguration: false, sessionAllowsInput: { nativeAllows })
        model.mailbox.configure(Configuration(isEnabled: true))
        model.handleScreenLockNotification(Notification(name: ScreenLockSession.lockedNotification))
        #expect(model.mailbox.state.withLock { $0.suspended && $0.enabled })
        model.handleScreenLockNotification(Notification(name: ScreenLockSession.unlockedNotification))
        #expect(model.mailbox.state.withLock { $0.suspended })
        nativeAllows = true
        model.handleScreenLockNotification(Notification(name: ScreenLockSession.unlockedNotification))
        #expect(model.mailbox.state.withLock { !$0.suspended && $0.enabled && $0.pending.isEmpty })
    }

    @Test @MainActor func unlockCannotResumeSleepingOrInactiveUserSession() {
        let model = AppModel(loadConfiguration: false, sessionAllowsInput: { true })
        model.handleScreenLockNotification(Notification(name: ScreenLockSession.lockedNotification))
        model.handleWorkspaceNotification(Notification(name: NSWorkspace.willSleepNotification))
        model.handleWorkspaceNotification(Notification(name: NSWorkspace.sessionDidResignActiveNotification))
        model.handleScreenLockNotification(Notification(name: ScreenLockSession.unlockedNotification))
        model.handleWorkspaceNotification(Notification(name: NSWorkspace.didWakeNotification))
        #expect(model.mailbox.state.withLock { $0.suspended })
        model.handleWorkspaceNotification(Notification(name: NSWorkspace.sessionDidBecomeActiveNotification))
        #expect(model.mailbox.state.withLock { !$0.suspended })
    }

    @Test @MainActor func wakeOrActiveSessionNotificationCannotOverrideKnownScreenLock() {
        let model = AppModel(loadConfiguration: false, sessionAllowsInput: { false })
        model.handleScreenLockNotification(Notification(name: ScreenLockSession.lockedNotification))
        model.handleWorkspaceNotification(Notification(name: NSWorkspace.didWakeNotification))
        model.handleWorkspaceNotification(Notification(name: NSWorkspace.sessionDidBecomeActiveNotification))
        model.handleScreenLockNotification(Notification(name: Notification.Name("Unrelated")))
        #expect(model.mailbox.state.withLock { $0.suspended })
    }
}
