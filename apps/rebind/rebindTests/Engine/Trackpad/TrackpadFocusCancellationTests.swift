import CoreGraphics
import Synchronization
import Testing
@testable import rebind

struct TrackpadFocusCancellationTests {
    private let shortcut = KeyboardShortcut(keyCode: 13, modifiers: .command)

    private func mailbox(for tap: TrackpadSingleTap = .fourFinger) -> EngineMailbox {
        let mailbox = EngineMailbox()
        let binding = rebind.Binding(scope: .builtInTrackpad, trigger: tap.trigger,
                                     modifiers: [], action: .shortcut(shortcut))
        mailbox.configure(Configuration(isEnabled: true, bindings: [binding]))
        mailbox.state.withLock { $0.status = .active; $0.foregroundPID = 100 }
        return mailbox
    }

    @Test(arguments: [Int32(101), nil])
    func returningToOriginalTargetCannotReadmitAnOldRuntime(_ intermediatePID: Int32?) throws {
        let mailbox = mailbox()
        let runtime = try #require(mailbox.trackpadRuntime())
        mailbox.updateTrackpadForeground(intermediatePID)
        mailbox.updateTrackpadForeground(100)
        #expect(mailbox.submitTrackpad(runtime, pid: 100, at: 0) == false)
        #expect(mailbox.nextAction() == nil)
        let fresh = try #require(mailbox.trackpadRuntime())
        #expect(mailbox.submitTrackpad(fresh, pid: 100, at: 1) == true)
        #expect(mailbox.nextAction()?.trackpadTarget?.pid == 100)
    }

    @Test(arguments: [Int32(101), nil])
    func dequeuedDispatchStaysCancelledAfterReturningToItsTarget(_ intermediatePID: Int32?) throws {
        let mailbox = mailbox()
        let runtime = try #require(mailbox.trackpadRuntime())
        try #require(mailbox.submitTrackpad(runtime, pid: 100, at: 0) == true)
        let dispatch = try #require(mailbox.nextAction())
        mailbox.updateTrackpadForeground(intermediatePID)
        mailbox.updateTrackpadForeground(100)
        #expect(mailbox.dispatchIsCurrent(dispatch) == false)
        #expect(mailbox.state.withLock { $0.enabled && !$0.emergencyPause && $0.actionFailed == nil })
    }

    @Test func focusRoundTripDuringSenderPreparationPostsNothingAndFreshOutputRecovers() throws {
        let mailbox = mailbox()
        let runtime = try #require(mailbox.trackpadRuntime())
        try #require(mailbox.submitTrackpad(runtime, pid: 100, at: 0) == true)
        let posts = Mutex<[CGEventType]>([])
        let reasons = Mutex<[String]>([])
        let shouldSwitch = Mutex(true)
        let worker = ActionWorker(mailbox: mailbox, capabilities: { AudioOutputCapabilities() },
            sendTrackpadShortcut: { shortcut, target, canPerform in
                var activeChecks = 0
                return ShortcutSender.send(shortcut, to: target, canPerform: canPerform,
                    diagnose: { event in reasons.withLock { $0.append(event.key) } },
                    allowsInput: { true }, blockedInput: { _ in nil }, targetIsActive: { pid in
                        activeChecks += 1
                        if activeChecks == 2 && shouldSwitch.withLock({ $0 }) {
                            mailbox.updateTrackpadForeground(101)
                            mailbox.updateTrackpadForeground(100)
                        }
                        return pid == 100
                    }, clock: { 1 }, post: { event, pid in
                        #expect(pid == 100)
                        #expect(event.getIntegerValueField(.eventSourceUserData) == ShortcutSender.eventTag)
                        posts.withLock { $0.append(event.type) }
                    })
            }, sendShortcut: { _ in Issue.record("Touch used global sender"); return false },
            secureInput: { false }, postingAllowed: { true })
        worker.service(at: 1)
        #expect(posts.withLock { $0.isEmpty })
        #expect(reasons.withLock { $0 } == ["output-runtime-changed"])
        shouldSwitch.withLock { $0 = false }
        let fresh = try #require(mailbox.trackpadRuntime())
        try #require(mailbox.submitTrackpad(fresh, pid: 100, at: 0) == true)
        worker.service(at: 1)
        worker.service(at: 2)
        #expect(posts.withLock { $0 } == [.keyDown, .keyUp])
        #expect(mailbox.state.withLock { $0.enabled && !$0.emergencyPause && $0.actionFailed == nil })
    }

    @Test(arguments: TrackpadSingleTap.allCases)
    func bufferedStrokeFromBeforeFocusRoundTripCannotQualify(_ tap: TrackpadSingleTap) throws {
        let mailbox = mailbox(for: tap)
        let old = try #require(mailbox.trackpadRuntime())
        let buffer = NativeTrackpadBuffer(mailbox: mailbox)
        buffer.setAccepting(true)
        func enqueue(_ runtime: TrackpadRuntime, endingAt lift: UInt64, startingID: Int32) {
            for (offset, count) in [0, tap.rawValue, tap.rawValue, 0].enumerated() {
                let receipt = lift - UInt64(3 - offset) * 20_000_000
                var frame = NativeTrackpadFrame(receipt: receipt, revision: runtime.revision,
                    activity: runtime.inputActivity, frame: startingID + Int32(offset),
                    time: Double(receipt) / 1_000_000_000, count: count)
                if count > 0 { frame.first = .init(id: 0, x: 0.2, y: 0.5, pressure: 45) }
                if count > 1 { frame.second = .init(id: 1, x: 0.3, y: 0.5, pressure: 45) }
                if count > 2 { frame.third = .init(id: 2, x: 0.4, y: 0.5, pressure: 45) }
                if count > 3 { frame.fourth = .init(id: 3, x: 0.5, y: 0.5, pressure: 45) }
                buffer.state.withLock { $0.append(frame, generation: $0.generation) }
            }
        }
        enqueue(old, endingAt: 4_000_000_000, startingID: 0)
        mailbox.updateTrackpadForeground(101)
        mailbox.updateTrackpadForeground(100)
        let fresh = try #require(mailbox.trackpadRuntime())
        var session = TrackpadTapSession(runtime: fresh, foreground: 100, startedAt: 0)
        session.consumeBufferedFrames(from: buffer, clock: { 4_000_000_000 })
        let obsolete = session.takeReadyGesture(from: buffer, at: 4_060_000_000)
        #expect(obsolete == nil)
        enqueue(fresh, endingAt: 5_000_000_000, startingID: 4)
        session.consumeBufferedFrames(from: buffer, clock: { 5_000_000_000 })
        let recovered = session.takeReadyGesture(from: buffer, at: 5_060_000_000)
        #expect(recovered == .single(tap))
        let duplicate = session.takeReadyGesture(from: buffer, at: 5_070_000_000)
        #expect(duplicate == nil)
    }

    @Test func activationNotificationInvalidatesEvenWhenLatestPIDIsUnchanged() throws {
        let mailbox = mailbox()
        let old = try #require(mailbox.trackpadRuntime())
        try #require(mailbox.submitTrackpad(old, pid: 100, at: 0) == true)
        let dispatch = try #require(mailbox.nextAction())
        // Delayed A -> B -> A notifications may both read A as frontmost.
        mailbox.updateTrackpadForeground(100, activationChanged: true)
        #expect(mailbox.dispatchIsCurrent(dispatch) == false)
        #expect(mailbox.submitTrackpad(old, pid: 100, at: 0) == false)
        let fresh = try #require(mailbox.trackpadRuntime())
        #expect(mailbox.submitTrackpad(fresh, pid: 100, at: 1) == true)
    }

    @Test func unchangedPollingPreservesQueuedTouchAndRuntime() throws {
        let mailbox = mailbox()
        let runtime = try #require(mailbox.trackpadRuntime())
        try #require(mailbox.submitTrackpad(runtime, pid: 100, at: 0) == true)
        for _ in 0..<100 { mailbox.updateTrackpadForeground(100) }
        #expect(mailbox.trackpadRuntime() == runtime)
        let dispatch = try #require(mailbox.nextAction())
        #expect(mailbox.dispatchIsCurrent(dispatch) == true)
    }

    @Test func focusCancellationPreservesKeyboardDispatchAndSuppressedReleaseOwnership() throws {
        let mailbox = mailbox()
        let keyboard = rebind.Binding(scope: .allKeyboards, trigger: .key(0),
                                      modifiers: [], action: .shortcut(shortcut))
        mailbox.configure(Configuration(isEnabled: true, bindings: [keyboard]))
        let down = InputEvent(trigger: .key(0), phase: .down)
        try #require(mailbox.handle(down, secureInput: false) == true)
        let dispatch = try #require(mailbox.nextAction())
        mailbox.updateTrackpadForeground(101)
        mailbox.updateTrackpadForeground(100)
        #expect(mailbox.dispatchIsCurrent(dispatch) == true)
        #expect(mailbox.handle(InputEvent(trigger: .key(0), phase: .up), secureInput: false) == true)
        #expect(mailbox.handle(InputEvent(trigger: .key(1), phase: .down), secureInput: false) == false)
        #expect(mailbox.nextAction() == nil)
    }
}
