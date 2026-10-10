import Foundation
import Synchronization
import Testing
@testable import rebind

struct TrackpadIntegrationTests {
    private let shortcut = KeyboardShortcut(keyCode: 13, modifiers: .command)
    private let lift: UInt64 = 4_000_000_000
    private var runtime: TrackpadRuntime { .init(revision: 1, inputActivity: 0, shortcut: shortcut) }
    private var binding: rebind.Binding { .init(scope: .builtInTrackpad, trigger: .fourFingerTap, modifiers: [], action: .shortcut(shortcut)) }

    private func frame(_ id: Int32?, count: Int, at receipt: UInt64) -> NativeTrackpadFrame {
        var value = NativeTrackpadFrame(receipt: receipt, revision: 1, activity: 0,
                                       frame: id, time: id.map { Double($0) * 0.02 }, count: count)
        if count > 0 { value.first = .init(id: 0, x: 0.2, y: 0.5, pressure: 45) }
        if count > 1 { value.second = .init(id: 1, x: 0.3, y: 0.5, pressure: 45) }
        if count > 2 { value.third = .init(id: 2, x: 0.4, y: 0.5, pressure: 45) }
        if count > 3 { value.fourth = .init(id: 3, x: 0.5, y: 0.5, pressure: 45) }
        return value
    }

    private func completed(_ session: inout TrackpadTapSession, at lift: UInt64) {
        for (id, count) in [0, 4, 4, 0].enumerated() {
            let time = lift - UInt64(3 - id) * 20_000_000
            session.consume(frame(Int32(id), count: count, at: time), at: time)
        }
    }

    @Test func callbackReceivedBeforePollingDecisionCanBeConsumedOnNextPoll() {
        var session = TrackpadTapSession(runtime: runtime, foreground: 100, startedAt: 0)
        session.consume(frame(0, count: 0, at: lift - 100_000_000), at: lift - 100_000_000)
        // The producer can enqueue a frame after the consumer drains, before
        // its readiness check. Delivery time must not reorder receipt time.
        let idle = session.takeReady(at: lift - 70_000_000)
        #expect(idle == false)
        session.consume(frame(1, count: 4, at: lift - 80_000_000), at: lift - 60_000_000)
        session.consume(frame(2, count: 4, at: lift - 60_000_000), at: lift - 60_000_000)
        session.consume(frame(3, count: 0, at: lift), at: lift)
        let ready = session.takeReady(at: lift + 60_000_000)
        #expect(ready)
    }

    @Test func newContactQueuedBeforePendingReadinessPollCancelsAndNextTapRecovers() {
        var session = TrackpadTapSession(runtime: runtime, foreground: 100, startedAt: 0)
        completed(&session, at: lift)
        let waiting = session.takeReady(at: lift + 30_000_000)
        #expect(waiting == false)
        session.consume(frame(4, count: 4, at: lift + 20_000_000), at: lift + 40_000_000)
        session.consume(frame(5, count: 4, at: lift + 40_000_000), at: lift + 40_000_000)
        session.consume(frame(6, count: 0, at: lift + 60_000_000), at: lift + 60_000_000)
        let replacement = session.takeReady(at: lift + 120_000_000)
        #expect(replacement)
        let duplicate = session.takeReady(at: lift + 130_000_000)
        #expect(duplicate == false)
    }

    @Test func bufferedConsumptionSamplesClockAfterDequeueAndReportsReasons() {
        let mailbox = EngineMailbox()
        let buffer = NativeTrackpadBuffer(mailbox: mailbox)
        for (id, count) in [0, 4, 4, 0].enumerated() {
            let value = frame(Int32(id), count: count, at: lift - UInt64(3 - id) * 20_000_000)
            buffer.state.withLock { $0.frames[id] = value; $0.count += 1 }
        }
        var session = TrackpadTapSession(runtime: runtime, foreground: 100, startedAt: 0)
        var clockCalls = 0
        var events: [String] = []
        session.consumeBufferedFrames(from: buffer, clock: { clockCalls += 1; return lift },
                                      diagnose: { events.append($0.key) })
        let ready = session.takeReady(at: lift + 60_000_000)
        #expect(ready)
        #expect(clockCalls == 4)
        #expect(events.filter { $0 == "frames" }.count == 4)
        #expect(events.contains("qualified-taps"))
        #expect(events.contains("future-receipt") == false)
    }

    @Test func malformedStaleAndObsoleteFramesHaveDistinctDiagnosticReasons() {
        for scenario in 0...3 {
            var session = TrackpadTapSession(runtime: runtime, foreground: 100, startedAt: 0)
            var value = frame(0, count: 0, at: lift)
            if scenario == 0 { value.valid = false }
            if scenario == 1 { value.activity = 1 }
            let now = scenario == 2 ? lift + 100_000_001 : scenario == 3 ? lift - 1 : lift
            let reason = session.consume(value, at: now)
            #expect(reason?.key == ["invalid-frame", "obsolete-frame", "stale-frame", "future-receipt"][scenario])
            let ready = session.takeReady(at: lift + 160_000_000)
            #expect(ready == false)
        }
    }

    @Test func mouseUpAfterKnownReleaseDoesNotRequireAnotherEmptyCallback() {
        var session = TrackpadTapSession(runtime: runtime, foreground: 100, startedAt: 0)
        var current = runtime
        session.consume(frame(0, count: 0, at: lift - 100_000_000), at: lift - 100_000_000)
        session.consume(frame(1, count: 4, at: lift - 80_000_000), at: lift - 80_000_000)
        current.inputActivity = 1 // physical button-down
        session.update(runtime: current, foreground: 100)
        var release = frame(2, count: 0, at: lift)
        release.activity = 1
        session.consume(release, at: lift)
        current.inputActivity = 2 // physical up after contact release
        session.update(runtime: current, foreground: 100)
        let click = session.takeReady(at: lift + 60_000_000)
        #expect(click == false)
        // The native stream can be silent while idle; no extra zero callback.
        for (offset, count) in [4, 4, 0].enumerated() {
            var value = frame(Int32(100 + offset), count: count, at: lift + 1_000_000_000 + UInt64(offset) * 20_000_000)
            value.activity = 2
            session.consume(value, at: value.receipt)
        }
        let nextTap = session.takeReady(at: lift + 1_100_000_000)
        #expect(nextTap)
    }

    @Test(arguments: [false, true]) func backwardsReceiptOrPollingStillCancels(_ backwardsReceipt: Bool) {
        var session = TrackpadTapSession(runtime: runtime, foreground: 100, startedAt: 0)
        completed(&session, at: lift)
        if backwardsReceipt {
            session.consume(frame(4, count: 0, at: lift - 1), at: lift + 20_000_000)
        } else {
            _ = session.takeReady(at: lift + 30_000_000)
            _ = session.takeReady(at: lift + 20_000_000)
        }
        let ready = session.takeReady(at: lift + 60_000_000)
        #expect(ready == false)
    }

    @Test func qualifiedReleaseSurvivesEmptyTailAndCanRepeat() {
        var session = TrackpadTapSession(runtime: runtime, foreground: 100, startedAt: 0)
        completed(&session, at: lift)
        session.consume(frame(nil, count: 0, at: lift + 20_000_000), at: lift + 20_000_000)
        let early = session.takeReady(at: lift + 59_999_999)
        let ready = session.takeReady(at: lift + 60_000_000)
        let duplicate = session.takeReady(at: lift + 70_000_000)
        #expect(!early && ready && !duplicate)
        completed(&session, at: lift + 1_000_000_000)
        let second = session.takeReady(at: lift + 1_060_000_000)
        #expect(second)
    }

    @Test func timestampedEmptyCallbackCompletesTapWithoutATerminalContactRecord() {
        var session = TrackpadTapSession(runtime: runtime, foreground: 100, startedAt: 0)
        for (id, count) in [0, 4, 4].enumerated() {
            let time = lift - UInt64(3 - id) * 20_000_000
            session.consume(frame(Int32(id), count: count, at: time), at: time)
        }
        let empty = NativeTrackpadFrame.read(nil, count: 0, receipt: lift, revision: 1, activity: 0,
                                            callbackFrame: 3, callbackTime: 0.06)
        session.consume(empty, at: lift)
        let ready = session.takeReady(at: lift + 60_000_000)
        #expect(ready)
    }

    @Test(arguments: [12_000_000, 28_000_000, 59_000_000])
    func delayedNativeClickCancelsBeforeFastDispatch(_ delay: UInt64) {
        var session = TrackpadTapSession(runtime: runtime, foreground: 100, startedAt: 0)
        completed(&session, at: lift)
        let beforeClick = session.takeReady(at: lift + delay - 1)
        #expect(!beforeClick)
        var next = runtime; next.inputActivity = 1
        session.update(runtime: next, foreground: 100)
        let ready = session.takeReady(at: lift + 60_000_000)
        #expect(!ready)
    }

    @Test func deliberateRepeatedTapsCanEachDispatchWithoutHalfSecondDeadTime() {
        var session = TrackpadTapSession(runtime: runtime, foreground: 100, startedAt: 0)
        for tap in 0..<3 {
            let end = lift + UInt64(tap) * 200_000_000
            completed(&session, at: end)
            let ready = session.takeReady(at: end + 60_000_000)
            let duplicate = session.takeReady(at: end + 70_000_000)
            #expect(ready && !duplicate)
        }
    }

    @Test(arguments: [false, true])
    func physicalClickThenIdleGapsRecoverForSubsequentTaps(_ lateMouseUp: Bool) {
        var session = TrackpadTapSession(runtime: runtime, foreground: 100, startedAt: 0)
        var current = runtime
        func consume(_ id: Int32, count: Int, at time: UInt64, activity: UInt64) {
            var value = frame(id, count: count, at: time)
            value.activity = activity
            session.consume(value, at: time)
        }
        consume(0, count: 0, at: lift - 100_000_000, activity: 0)
        consume(1, count: 4, at: lift - 80_000_000, activity: 0)
        current.inputActivity = 1 // physical down cancels this contact sequence
        session.update(runtime: current, foreground: 100)
        consume(2, count: 4, at: lift - 60_000_000, activity: 1)
        if !lateMouseUp {
            current.inputActivity = 2
            session.update(runtime: current, foreground: 100)
        }
        consume(3, count: 0, at: lift, activity: current.inputActivity)
        if lateMouseUp {
            current.inputActivity = 2
            session.update(runtime: current, foreground: 100)
            // A buffered pre-up release cannot qualify output. A fresh neutral
            // observation rearms without restarting the native device.
            consume(4, count: 0, at: lift + 20_000_000, activity: 1)
            consume(5, count: 0, at: lift + 40_000_000, activity: 2)
        }
        let clickOutput = session.takeReady(at: lift + 60_000_000)
        #expect(!clickOutput)
        for tap in 1...3 {
            let start = lift + UInt64(tap) * 1_000_000_000
            let id = Int32(tap * 100)
            consume(id, count: 4, at: start, activity: 2)
            consume(id + 1, count: 4, at: start + 20_000_000, activity: 2)
            consume(id + 2, count: 0, at: start + 40_000_000, activity: 2)
            let ready = session.takeReady(at: start + 100_000_000)
            let duplicate = session.takeReady(at: start + 110_000_000)
            #expect(ready && !duplicate)
        }
    }

    @Test(arguments: 0...7) func waitingActionIsCancelled(_ scenario: Int) {
        var session = TrackpadTapSession(runtime: runtime, foreground: 100, startedAt: 0)
        completed(&session, at: lift)
        switch scenario {
        case 0:
            var next = runtime; next.inputActivity = 1
            session.update(runtime: next, foreground: 100)
        case 1: session.update(runtime: runtime, foreground: 101)
        case 2: session.consume(frame(4, count: 1, at: lift + 20_000_000), at: lift + 20_000_000)
        case 3: session.interrupt() // overflow, protection, native failure
        case 4:
            var next = frame(4, count: 0, at: lift + 20_000_000); next.valid = false
            session.consume(next, at: lift + 20_000_000)
        case 5: session.consume(frame(7, count: 0, at: lift + 20_000_000), at: lift + 20_000_000)
        case 6:
            var next = runtime; next.revision = 2
            session.update(runtime: next, foreground: 100)
        default: session.consume(frame(4, count: 0, at: lift + 20_000_000), at: lift + 200_000_000)
        }
        let ready = session.takeReady(at: lift + 60_000_000)
        #expect(!ready)
    }

    @Test func unknownReleaseThreeFingersAndLatePollNeverDispatch() {
        for scenario in 0...2 {
            var session = TrackpadTapSession(runtime: runtime, foreground: 100, startedAt: 0)
            for (id, count) in [0, scenario == 1 ? 3 : 4, scenario == 1 ? 3 : 4, 0].enumerated() {
                let time = lift - UInt64(3 - id) * 20_000_000
                session.consume(frame(scenario == 0 && id == 3 ? nil : Int32(id), count: count, at: time), at: time)
            }
            let ready = session.takeReady(at: lift + (scenario == 2 ? 160_000_001 : 60_000_000))
            #expect(!ready)
        }
    }

    @Test func armingDelayAndMissingForegroundPreventDispatch() {
        for scenario in 0...1 {
            var session = TrackpadTapSession(runtime: runtime, foreground: scenario == 0 ? nil : 100,
                                            startedAt: scenario == 0 ? 0 : lift - 1_000_000_000)
            completed(&session, at: lift)
            let ready = session.takeReady(at: lift + 60_000_000)
            #expect(!ready)
        }
    }

    @Test func persistenceRoundTripPreservesProfilesAndRejectsUnsupportedModes() throws {
        var value = Configuration(isEnabled: true, bindings: [binding])
        try value.createProfile(name: "Other", copying: value.selectedProfileID)
        let decoded = try JSONDecoder().decode(Configuration.self, from: JSONEncoder().encode(value))
        try decoded.validate()
        #expect(decoded == value)
        for scenario in 0...3 {
            var invalid = binding
            switch scenario {
            case 0: invalid.modifiers = .control
            case 1: invalid.activation = .doublePress
            case 2: invalid.activation = .hold
            default: invalid.action = .lockScreen
            }
            #expect(!invalid.isValid)
        }
    }

    @Test(arguments: 1...21) func earlierSchemasRejectTrackpadPayloadInInactiveProfiles(_ version: Int) throws {
        var value = Configuration(schemaVersion: version, bindings: version < 6 ? [binding] : [])
        if version >= 6 { value.profiles.append(RuleProfile(name: "Inactive", bindings: [binding])) }
        let decoded = try JSONDecoder().decode(Configuration.self, from: JSONEncoder().encode(value))
        #expect(throws: ConfigurationError.invalid) { try decoded.migrated() }
    }

    @Test func schema21MigratesWithoutChangingOldRules() throws {
        let oldBinding = rebind.Binding(scope: .allMice, trigger: .mouseButton(3), modifiers: .control,
                                       action: .shortcut(shortcut), activation: .hold, holdDurationMilliseconds: 1000)
        var old = Configuration(isEnabled: true, bindings: [oldBinding])
        try old.createProfile(name: "Other", copying: old.selectedProfileID)
        old.schemaVersion = 21
        let data = try JSONEncoder().encode(old)
        let decoded = try JSONDecoder().decode(Configuration.self, from: data).migrated()
        #expect(decoded.schemaVersion == 22 && decoded.profiles == old.profiles)
        #expect(decoded.selectedProfileID == old.selectedProfileID && decoded.isEnabled)
    }

    private func mailbox() -> EngineMailbox {
        let result = EngineMailbox()
        result.configure(Configuration(isEnabled: true, bindings: [binding]))
        result.state.withLock { $0.status = .active; $0.foregroundPID = 100 }
        return result
    }

    @Test func pulseUsesBoundedSlotAndDoesNotClaimQuartzSuppression() throws {
        let mailbox = mailbox()
        let runtime = try #require(mailbox.trackpadRuntime())
        #expect(!mailbox.handle(InputEvent(trigger: .fourFingerTap, phase: .down), secureInput: false))
        #expect(mailbox.submitTrackpad(runtime, pid: 100, at: 0))
        #expect(!mailbox.submitTrackpad(runtime, pid: 100, at: 0))
        let dispatch = try #require(mailbox.nextAction())
        #expect(dispatch.action == binding.action && dispatch.trackpadTarget?.pid == 100)
        #expect(mailbox.nextAction() == nil)
        mailbox.state.withLock { $0.pending = [binding.action] }
        #expect(!mailbox.submitTrackpad(runtime, pid: 100, at: 0))
    }

    @Test(arguments: 0...8) func mailboxInvalidatesPendingGestureAndRuntime(_ scenario: Int) throws {
        let mailbox = mailbox()
        let runtime = try #require(mailbox.trackpadRuntime())
        #expect(mailbox.submitTrackpad(runtime, pid: 100, at: 0))
        switch scenario {
        case 0: mailbox.configure(Configuration(isEnabled: false, bindings: [binding]))
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
        #expect(!mailbox.submitTrackpad(runtime, pid: 100, at: 0))
    }

    @Test(arguments: [WindowActionResult.performed, .cancelled, .unavailable])
    func workerUsesTargetedSenderAndCancellationDoesNotPause(_ outcome: WindowActionResult) throws {
        let mailbox = mailbox()
        let runtime = try #require(mailbox.trackpadRuntime())
        #expect(mailbox.submitTrackpad(runtime, pid: 100, at: 0))
        let calls = Mutex(0)
        let worker = ActionWorker(mailbox: mailbox, capabilities: { AudioOutputCapabilities() },
            sendTrackpadShortcut: { shortcut, target, canPerform in
                #expect(shortcut.keyCode == 13 && shortcut.modifiers == .command && target.pid == 100 && canPerform())
                calls.withLock { $0 += 1 }; return outcome
            }, sendShortcut: { _ in Issue.record("Touch used global sender"); return false },
            secureInput: { false }, postingAllowed: { true })
        worker.service(at: 20_000_000)
        #expect(calls.withLock { $0 } == 1)
        #expect(mailbox.state.withLock { $0.emergencyPause } == (outcome == .unavailable))
    }

    @Test func switchingProfilesDropsOldTapAndLoadsTheNewShortcut() throws {
        let mailbox = mailbox()
        let oldRuntime = try #require(mailbox.trackpadRuntime())
        #expect(mailbox.submitTrackpad(oldRuntime, pid: 100, at: 0))
        var configuration = Configuration(isEnabled: true, bindings: [binding])
        try configuration.createProfile(name: "Other", copying: configuration.selectedProfileID)
        configuration.bindings[0].action = .shortcut(.init(keyCode: 17, modifiers: [.command, .shift]))
        mailbox.configure(configuration)
        #expect(mailbox.nextAction() == nil)
        let next = try #require(mailbox.trackpadRuntime())
        #expect(next.shortcut.keyCode == 17 && next.revision != oldRuntime.revision)
        #expect(!mailbox.submitTrackpad(oldRuntime, pid: 100, at: 0))
        #expect(mailbox.submitTrackpad(next, pid: 100, at: 0))
    }

    @Test func ownSyntheticEventsDoNotInvalidateTouchAndDuplicateRulesAreRejected() throws {
        let mailbox = mailbox()
        let runtime = try #require(mailbox.trackpadRuntime())
        #expect(mailbox.submitTrackpad(runtime, pid: 100, at: 0))
        #expect(!mailbox.handle(InputEvent(trigger: .key(13), phase: .down, isSynthetic: true), secureInput: false))
        #expect(mailbox.nextAction()?.trackpadTarget != nil)
        var duplicate = binding; duplicate.id = UUID()
        #expect(throws: ConfigurationError.conflict) { try Configuration(bindings: [binding, duplicate]).validate() }
    }

    @Test func cancellationDuringSenderPreparationIsRechecked() throws {
        let mailbox = mailbox()
        let runtime = try #require(mailbox.trackpadRuntime())
        #expect(mailbox.submitTrackpad(runtime, pid: 100, at: 0))
        let worker = ActionWorker(mailbox: mailbox, capabilities: { AudioOutputCapabilities() },
            sendTrackpadShortcut: { _, _, canPerform in
                #expect(canPerform())
                mailbox.setEditing(true)
                #expect(!canPerform())
                return .cancelled
            }, secureInput: { false }, postingAllowed: { true })
        worker.service(at: 20_000_000)
        #expect(mailbox.state.withLock { $0.enabled && !$0.emergencyPause && $0.actionFailed == nil })
    }

    @Test func workerDropsExpiredOutputWithoutPostingOrError() throws {
        let mailbox = mailbox()
        let runtime = try #require(mailbox.trackpadRuntime())
        #expect(mailbox.submitTrackpad(runtime, pid: 100, at: 0))
        let worker = ActionWorker(mailbox: mailbox, capabilities: { AudioOutputCapabilities() },
            sendTrackpadShortcut: { _, _, _ in Issue.record("Expired touch posted"); return .performed },
            secureInput: { false }, postingAllowed: { true })
        worker.service(at: 100_000_001)
        #expect(mailbox.state.withLock { $0.enabled && !$0.emergencyPause && $0.actionFailed == nil })
    }
}
