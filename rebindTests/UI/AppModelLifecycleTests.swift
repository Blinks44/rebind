import AppKit
import Testing
@testable import rebind

@MainActor struct AppModelLifecycleTests {
    @Test(arguments: [true, false]) func overlappingSleepAndInactiveSessionRequireBothToRecover(wakeFirst: Bool) {
        let model = AppModel(loadConfiguration: false)
        model.handleWorkspaceNotification(Notification(name: NSWorkspace.willSleepNotification))
        model.handleWorkspaceNotification(Notification(name: NSWorkspace.sessionDidResignActiveNotification))
        model.handleWorkspaceNotification(Notification(name: wakeFirst ? NSWorkspace.didWakeNotification : NSWorkspace.sessionDidBecomeActiveNotification))
        #expect(model.mailbox.state.withLock { $0.suspended })
        model.handleWorkspaceNotification(Notification(name: wakeFirst ? NSWorkspace.sessionDidBecomeActiveNotification : NSWorkspace.didWakeNotification))
        #expect(model.mailbox.state.withLock { $0.suspended } == false)
    }

    @Test func duplicateAndUnrelatedWorkspaceNotificationsDoNotResumeSession() {
        let model = AppModel(loadConfiguration: false)
        model.handleWorkspaceNotification(Notification(name: NSWorkspace.sessionDidResignActiveNotification))
        model.handleWorkspaceNotification(Notification(name: NSWorkspace.sessionDidResignActiveNotification))
        model.handleWorkspaceNotification(Notification(name: NSWorkspace.didWakeNotification))
        model.handleWorkspaceNotification(Notification(name: NSWorkspace.screensDidWakeNotification))
        #expect(model.mailbox.state.withLock { $0.suspended })
        model.handleWorkspaceNotification(Notification(name: NSWorkspace.sessionDidBecomeActiveNotification))
        #expect(model.mailbox.state.withLock { $0.suspended } == false)
    }

    @Test func sleepCancelsUiRecorderWithoutChangingSavedEnablePreference() {
        let model = AppModel(loadConfiguration: false)
        let request = RecordingRequest(target: .mouseTrigger)
        model.recording = request
        model.mailbox.record(request)
        model.mailbox.configure(Configuration(isEnabled: true))
        model.handleWorkspaceNotification(Notification(name: NSWorkspace.willSleepNotification))
        #expect(model.recording == nil)
        #expect(model.mailbox.state.withLock { $0.recording == nil && $0.enabled && $0.suspended })
        model.handleWorkspaceNotification(Notification(name: NSWorkspace.didWakeNotification))
        #expect(model.mailbox.state.withLock { $0.enabled && $0.suspended == false && $0.pending.isEmpty })
    }

    @Test func stopEndsUiRecordingAndClearsQueuedAction() {
        let model = AppModel(loadConfiguration: false)
        let request = RecordingRequest(target: .mouseTrigger)
        model.recording = request
        model.mailbox.record(request)
        model.mailbox.state.withLock { $0.pending = [.shortcut(KeyboardShortcut(keyCode: 0, modifiers: .command))] }
        model.stop()
        #expect(model.recording == nil)
        #expect(model.mailbox.state.withLock { $0.stopped && $0.pending.isEmpty && $0.recording == nil })
    }

    @Test func captureLossCancellationReachesUiWithoutAnotherInputEvent() {
        let model = AppModel(loadConfiguration: false)
        let request = RecordingRequest(target: .mouseTrigger)
        model.recording = request
        model.mailbox.record(request)
        model.mailbox.captureLost(status: .permissionRequired)
        model.refresh() // Reads native permission state, without requesting/granting access.
        #expect(model.recording == nil)
        #expect(model.lastRecording?.request == request)
        #expect(model.lastRecording?.input == nil)
    }
}
