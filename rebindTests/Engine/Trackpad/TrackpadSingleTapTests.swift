import Foundation
import Synchronization
import Testing
@testable import rebind

struct TrackpadSingleTapTests {
    private let lift: UInt64 = 4_000_000_000
    private let threeOutput = KeyboardShortcut(keyCode: 17, modifiers: [.command, .shift])
    private let fourOutput = KeyboardShortcut(keyCode: 13, modifiers: .command)

    private func binding(_ tap: TrackpadSingleTap) -> rebind.Binding {
        .init(scope: .builtInTrackpad, trigger: tap.trigger, modifiers: [],
              action: .shortcut(tap == .threeFinger ? threeOutput : fourOutput))
    }

    private func mailbox(_ taps: [TrackpadSingleTap] = TrackpadSingleTap.allCases) -> EngineMailbox {
        let mailbox = EngineMailbox()
        mailbox.configure(Configuration(isEnabled: true, bindings: taps.map(binding)))
        mailbox.state.withLock { $0.status = .active; $0.foregroundPID = 100 }
        return mailbox
    }

    private func frame(_ id: Int32, count: Int, at time: UInt64, runtime: TrackpadRuntime) -> NativeTrackpadFrame {
        var frame = NativeTrackpadFrame(receipt: time, revision: runtime.revision, activity: runtime.inputActivity,
                                        frame: id, time: Double(time) / 1_000_000_000, count: count)
        if count > 0 { frame.first = .init(id: 0, x: 0.2, y: 0.5, pressure: 45) }
        if count > 1 { frame.second = .init(id: 1, x: 0.3, y: 0.5, pressure: 45) }
        if count > 2 { frame.third = .init(id: 2, x: 0.4, y: 0.5, pressure: 45) }
        if count > 3 { frame.fourth = .init(id: 3, x: 0.5, y: 0.5, pressure: 45) }
        return frame
    }

    private func complete(_ session: inout TrackpadTapSession, fingers: Int, at end: UInt64,
                          runtime: TrackpadRuntime, firstID: Int32 = 0) {
        for (offset, count) in [0, fingers, fingers, 0].enumerated() {
            let time = end - UInt64(3 - offset) * 20_000_000
            session.consume(frame(firstID + Int32(offset), count: count, at: time, runtime: runtime), at: time)
        }
    }

    @Test(arguments: TrackpadSingleTap.allCases, 0...3)
    func onlyConfiguredFingerCountDispatches(_ tap: TrackpadSingleTap, _ pool: Int) throws {
        let taps: [TrackpadSingleTap] = pool == 0 ? [] : pool == 1 ? [.threeFinger] : pool == 2 ? [.fourFinger] : TrackpadSingleTap.allCases
        let mailbox = mailbox(taps)
        guard let runtime = mailbox.trackpadRuntime() else {
            #expect(taps.isEmpty)
            return
        }
        let buffer = NativeTrackpadBuffer(mailbox: mailbox)
        buffer.setAccepting(true)
        var session = TrackpadTapSession(runtime: runtime, foreground: 100, startedAt: 0)
        complete(&session, fingers: tap.rawValue, at: lift, runtime: runtime)
        #expect(session.takeReadyTap(from: buffer, at: lift + 59_999_999) == nil)
        let recognized = session.takeReadyTap(from: buffer, at: lift + 60_000_000)
        #expect(recognized == (taps.contains(tap) ? tap : nil))
        #expect(session.takeReadyTap(from: buffer, at: lift + 70_000_000) == nil)
        let submitted = mailbox.submitTrackpad(runtime, tap: tap, pid: 100, at: lift + 60_000_000)
        #expect(submitted == taps.contains(tap))
        if taps.contains(tap) {
            let dispatch = try #require(mailbox.nextAction())
            #expect(dispatch.action == binding(tap).action)
            #expect(dispatch.trackpadTarget?.pid == 100)
            #expect(mailbox.nextAction() == nil)
        }
    }

    @Test func alternatingTapsReachTheirOwnTargetedShortcutWorkerOnce() throws {
        let mailbox = mailbox()
        let runtime = try #require(mailbox.trackpadRuntime())
        let buffer = NativeTrackpadBuffer(mailbox: mailbox)
        buffer.setAccepting(true)
        var session = TrackpadTapSession(runtime: runtime, foreground: 100, startedAt: 0)
        let outputs = Mutex<[KeyboardShortcut]>([])
        let worker = ActionWorker(mailbox: mailbox, capabilities: { AudioOutputCapabilities() },
            sendTrackpadShortcut: { shortcut, target, canPerform in
                #expect(target.pid == 100 && canPerform())
                outputs.withLock { $0.append(shortcut) }
                return .performed
            }, sendShortcut: { _ in Issue.record("Touch used global output"); return false },
            secureInput: { false }, postingAllowed: { true })
        for (index, tap) in [TrackpadSingleTap.threeFinger, .fourFinger, .threeFinger].enumerated() {
            let end = lift + UInt64(index) * 1_000_000_000
            complete(&session, fingers: tap.rawValue, at: end, runtime: runtime, firstID: Int32(index * 10))
            let recognized = session.takeReadyTap(from: buffer, at: end + 60_000_000)
            let ready = try #require(recognized)
            #expect(ready == tap)
            #expect(mailbox.submitTrackpad(runtime, tap: ready, pid: 100, at: end + 60_000_000))
            worker.service(at: end + 70_000_000)
            worker.service(at: end + 80_000_000)
        }
        #expect(outputs.withLock { $0 } == [threeOutput, fourOutput, threeOutput])
    }

    @Test(arguments: TrackpadSingleTap.allCases, 0...7)
    func cancelledTapCannotDispatchAndFreshStrokeRecovers(_ tap: TrackpadSingleTap, _ cause: Int) throws {
        let mailbox = mailbox()
        var runtime = try #require(mailbox.trackpadRuntime())
        let buffer = NativeTrackpadBuffer(mailbox: mailbox)
        buffer.setAccepting(true)
        var session = TrackpadTapSession(runtime: runtime, foreground: 100, startedAt: 0)
        complete(&session, fingers: tap.rawValue, at: lift, runtime: runtime)
        switch cause {
        case 0: runtime.inputActivity += 1; session.update(runtime: runtime, foreground: 100)
        case 1: session.update(runtime: runtime, foreground: 101)
        case 2: runtime.revision += 1; session.update(runtime: runtime, foreground: 100)
        case 3: buffer.state.withLock { $0.overflow = true }
        case 4: buffer.setAccepting(false)
        case 5:
            var invalid = frame(4, count: 0, at: lift + 20_000_000, runtime: runtime)
            invalid.valid = false
            session.consume(invalid, at: invalid.receipt)
        case 6: session.interrupt() // protected context, pause or capture loss
        default: break // busy consumer: missed the maximum-lateness deadline
        }
        let poll = lift + (cause == 7 ? 160_000_001 : 60_000_000)
        #expect(session.takeReadyTap(from: buffer, at: poll) == nil)
        buffer.setAccepting(true)
        session.update(runtime: runtime, foreground: 100)
        complete(&session, fingers: tap.rawValue, at: lift + 1_000_000_000, runtime: runtime, firstID: 10)
        #expect(session.takeReadyTap(from: buffer, at: lift + 1_060_000_000) == tap)
        #expect(session.takeReadyTap(from: buffer, at: lift + 1_070_000_000) == nil)
    }

    @Test(arguments: TrackpadSingleTap.allCases)
    func queuedContactBlocksAtomicReadinessAndCancelsOldTap(_ tap: TrackpadSingleTap) throws {
        let mailbox = mailbox()
        let runtime = try #require(mailbox.trackpadRuntime())
        let buffer = NativeTrackpadBuffer(mailbox: mailbox)
        buffer.setAccepting(true)
        var session = TrackpadTapSession(runtime: runtime, foreground: 100, startedAt: 0)
        complete(&session, fingers: tap.rawValue, at: lift, runtime: runtime)
        let contact = frame(4, count: tap.rawValue, at: lift + 20_000_000, runtime: runtime)
        buffer.state.withLock { $0.frames[0] = contact; $0.count = 1 }
        #expect(session.takeReadyTap(from: buffer, at: lift + 60_000_000) == nil)
        session.consumeBufferedFrames(from: buffer, clock: { lift + 60_000_000 })
        #expect(session.takeReadyTap(from: buffer, at: lift + 70_000_000) == nil)
    }

    @Test(arguments: TrackpadSingleTap.allCases, [12_000_000, 28_000_000, 59_000_000] as [UInt64])
    func delayedPhysicalButtonActivityCancelsTap(_ tap: TrackpadSingleTap, _ delay: UInt64) throws {
        let mailbox = mailbox()
        let runtime = try #require(mailbox.trackpadRuntime())
        let buffer = NativeTrackpadBuffer(mailbox: mailbox)
        buffer.setAccepting(true)
        var session = TrackpadTapSession(runtime: runtime, foreground: 100, startedAt: 0)
        complete(&session, fingers: tap.rawValue, at: lift, runtime: runtime)
        #expect(session.takeReadyTap(from: buffer, at: lift + delay - 1) == nil)
        var next = runtime; next.inputActivity += 1
        session.update(runtime: next, foreground: 100)
        #expect(session.takeReadyTap(from: buffer, at: lift + 60_000_000) == nil)
    }

    @Test(arguments: TrackpadSingleTap.allCases, 0...8)
    func pendingOutputHonorsMailboxCancellation(_ tap: TrackpadSingleTap, _ cause: Int) throws {
        let mailbox = mailbox()
        let runtime = try #require(mailbox.trackpadRuntime())
        #expect(mailbox.submitTrackpad(runtime, tap: tap, pid: 100, at: 0))
        switch cause {
        case 0: mailbox.configure(Configuration(isEnabled: false, bindings: [binding(tap)]))
        case 1: mailbox.setEditing(true)
        case 2: mailbox.record(RecordingRequest(target: .output))
        case 3: mailbox.suspend(true)
        case 4: mailbox.stop()
        case 5: mailbox.captureLost(status: .secureInput)
        case 6: mailbox.updateTrackpadForeground(101)
        case 7: _ = mailbox.handle(InputEvent(trigger: .mouseButton(0), phase: .down), secureInput: false)
        default: _ = mailbox.handle(InputEvent(trigger: .key(0), phase: .down), secureInput: false)
        }
        #expect(mailbox.nextAction() == nil)
        #expect(mailbox.submitTrackpad(runtime, tap: tap, pid: 100, at: 0) == false)
    }

    @Test func disabledAndInactiveProfileRulesDoNotArmCapture() throws {
        var disabled = binding(.threeFinger); disabled.isEnabled = false
        var config = Configuration(isEnabled: true, bindings: [disabled])
        config.profiles.append(RuleProfile(name: "Inactive", bindings: [binding(.threeFinger), binding(.fourFinger)]))
        let mailbox = EngineMailbox()
        mailbox.configure(config)
        mailbox.state.withLock { $0.status = .active }
        #expect(mailbox.trackpadRuntime() == nil)
        try config.selectProfile(config.profiles[1].id)
        mailbox.configure(config)
        #expect(mailbox.trackpadRuntime()?.threeFingerShortcut == threeOutput)
        #expect(mailbox.trackpadRuntime()?.fourFingerShortcut == fourOutput)
    }

    @Test func profileSwitchCancelsOldThreeFingerActionAndSelectsNewRule() throws {
        let mailbox = mailbox([.threeFinger])
        let runtime = try #require(mailbox.trackpadRuntime())
        #expect(mailbox.submitTrackpad(runtime, tap: .threeFinger, pid: 100, at: 0))
        var config = Configuration(isEnabled: true, bindings: [binding(.threeFinger)])
        try config.createProfile(name: "Other", copying: config.selectedProfileID)
        config.bindings[0].action = .shortcut(fourOutput)
        mailbox.configure(config)
        #expect(mailbox.nextAction() == nil)
        #expect(mailbox.submitTrackpad(runtime, tap: .threeFinger, pid: 100, at: 0) == false)
        let current = try #require(mailbox.trackpadRuntime())
        #expect(current.threeFingerShortcut == fourOutput)
        #expect(mailbox.submitTrackpad(current, tap: .threeFinger, pid: 100, at: 0))
        #expect(mailbox.nextAction()?.action == .shortcut(fourOutput))
    }

    @Test func forgedShortcutSnapshotCannotSubmitAnotherAction() throws {
        let mailbox = mailbox([.threeFinger])
        var runtime = try #require(mailbox.trackpadRuntime())
        runtime.threeFingerShortcut = fourOutput
        #expect(mailbox.submitTrackpad(runtime, tap: .threeFinger, pid: 100, at: 0) == false)
    }

    @Test(arguments: TrackpadSingleTap.allCases)
    func quartzCannotSuppressOrDispatchTouchTriggers(_ tap: TrackpadSingleTap) {
        let mailbox = mailbox()
        #expect(mailbox.handle(InputEvent(trigger: tap.trigger, phase: .down), secureInput: false) == false)
        #expect(mailbox.nextAction() == nil)
    }

    @Test(arguments: [1, 2])
    func ordinaryContactsNeverBecomeThreeOrFourFingerTaps(_ fingers: Int) throws {
        let mailbox = mailbox()
        let runtime = try #require(mailbox.trackpadRuntime())
        let buffer = NativeTrackpadBuffer(mailbox: mailbox)
        buffer.setAccepting(true)
        var session = TrackpadTapSession(runtime: runtime, foreground: 100, startedAt: 0)
        complete(&session, fingers: fingers, at: lift, runtime: runtime)
        #expect(session.takeReadyTap(from: buffer, at: lift + 60_000_000) == nil)
    }

    @Test(arguments: TrackpadSingleTap.allCases, [false, true])
    func movementOrLongContactCannotQualify(_ tap: TrackpadSingleTap, _ longContact: Bool) throws {
        let mailbox = mailbox()
        let runtime = try #require(mailbox.trackpadRuntime())
        let buffer = NativeTrackpadBuffer(mailbox: mailbox)
        buffer.setAccepting(true)
        var session = TrackpadTapSession(runtime: runtime, foreground: 100, startedAt: 0)
        for index in 0...(longContact ? 24 : 3) {
            let end = longContact ? 24 : 3
            let time = lift + UInt64(index) * 20_000_000
            var value = frame(Int32(index), count: index == 0 || index == end ? 0 : tap.rawValue,
                              at: time, runtime: runtime)
            if !longContact && index == 2 { value.first = .init(id: 0, x: 0.4, y: 0.5, pressure: 45) }
            session.consume(value, at: time)
        }
        #expect(session.takeReadyTap(from: buffer, at: lift + (longContact ? 540_000_000 : 120_000_000)) == nil)
    }

    @Test(arguments: TrackpadSingleTap.allCases)
    func expiredOutputIsDroppedAndCancellationDuringPreparationIsRechecked(_ tap: TrackpadSingleTap) throws {
        let mailbox = mailbox()
        let runtime = try #require(mailbox.trackpadRuntime())
        let calls = Mutex(0)
        let worker = ActionWorker(mailbox: mailbox, capabilities: { AudioOutputCapabilities() },
            sendTrackpadShortcut: { _, _, canPerform in
                calls.withLock { $0 += 1 }
                #expect(canPerform())
                mailbox.setEditing(true)
                #expect(canPerform() == false)
                return .cancelled
            }, secureInput: { false }, postingAllowed: { true })
        #expect(mailbox.submitTrackpad(runtime, tap: tap, pid: 100, at: 0))
        worker.service(at: 100_000_001)
        #expect(calls.withLock { $0 } == 0)
        #expect(mailbox.submitTrackpad(runtime, tap: tap, pid: 100, at: 200_000_000))
        worker.service(at: 220_000_000)
        #expect(calls.withLock { $0 } == 1)
        #expect(mailbox.state.withLock { $0.emergencyPause } == false)
    }
}
