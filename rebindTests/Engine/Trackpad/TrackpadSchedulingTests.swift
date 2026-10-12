import CoreGraphics
import Synchronization
import Testing
@testable import rebind

struct TrackpadSchedulingTests {
    private let lift: UInt64 = 4_000_000_000

    private final class Output: Sendable {
        let clock = Mutex<UInt64>(0)
        let posts = Mutex<[CGEventType]>([])
        let diagnostics = Mutex<[String]>([])
        let preparationDelay = Mutex<UInt64>(0)
    }

    private struct Harness {
        let mailbox: EngineMailbox
        let runtime: TrackpadRuntime
        let buffer: NativeTrackpadBuffer
        let worker: ActionWorker
        let output = Output()
        var session: TrackpadTapSession
        var nextID: Int32 = 0
        var consumerDiagnostics: [String] = []

        init(_ tap: TrackpadSingleTap) throws {
            mailbox = EngineMailbox()
            let binding = rebind.Binding(scope: .builtInTrackpad, trigger: tap.trigger, modifiers: [],
                action: .shortcut(.init(keyCode: 13, modifiers: .command)))
            mailbox.configure(Configuration(isEnabled: true, bindings: [binding]))
            mailbox.state.withLock { $0.status = .active; $0.foregroundPID = 100 }
            runtime = try #require(mailbox.trackpadRuntime())
            buffer = NativeTrackpadBuffer(mailbox: mailbox)
            buffer.setAccepting(true)
            session = TrackpadTapSession(runtime: runtime, foreground: 100, startedAt: 0)
            let output = output
            worker = ActionWorker(mailbox: mailbox, capabilities: { AudioOutputCapabilities() },
                sendTrackpadShortcut: { shortcut, target, canPerform in
                    var activeChecks = 0
                    return ShortcutSender.send(shortcut, to: target, canPerform: canPerform,
                        diagnose: { event in output.diagnostics.withLock { $0.append(event.key) } },
                        allowsInput: { true }, blockedInput: { _ in nil }, targetIsActive: { pid in
                            activeChecks += 1
                            if activeChecks == 2 {
                                let delay = output.preparationDelay.withLock { $0 }
                                output.clock.withLock { $0 += delay }
                            }
                            return pid == 100
                        },
                        clock: { output.clock.withLock { $0 } }, post: { event, pid in
                            #expect(pid == 100)
                            #expect(event.getIntegerValueField(.eventSourceUserData) == ShortcutSender.eventTag)
                            output.posts.withLock { $0.append(event.type) }
                        })
                }, sendShortcut: { _ in Issue.record("Touch used global sender"); return false },
                secureInput: { false }, postingAllowed: { true })
        }

        mutating func enqueueTap(_ tap: TrackpadSingleTap, endingAt lift: UInt64) {
            for (offset, count) in [0, tap.rawValue, tap.rawValue, 0].enumerated() {
                let receipt = lift - UInt64(3 - offset) * 20_000_000
                var frame = NativeTrackpadFrame(receipt: receipt, revision: runtime.revision,
                    activity: runtime.inputActivity, frame: nextID, time: Double(receipt) / 1_000_000_000, count: count)
                nextID += 1
                if count > 0 { frame.first = .init(id: 0, x: 0.2, y: 0.5, pressure: 45) }
                if count > 1 { frame.second = .init(id: 1, x: 0.3, y: 0.5, pressure: 45) }
                if count > 2 { frame.third = .init(id: 2, x: 0.4, y: 0.5, pressure: 45) }
                if count > 3 { frame.fourth = .init(id: 3, x: 0.5, y: 0.5, pressure: 45) }
                buffer.state.withLock { $0.append(frame, generation: $0.generation) }
            }
        }

        mutating func drain(at now: UInt64) {
            var events: [String] = []
            session.consumeBufferedFrames(from: buffer, clock: { now }, diagnose: { events.append($0.key) })
            consumerDiagnostics += events
        }

        mutating func submitReady(at now: UInt64) -> Bool {
            guard let gesture = session.takeReadyGesture(from: buffer, at: now) else { return false }
            return mailbox.submitTrackpad(runtime, gesture: gesture, pid: 100, at: now)
        }

        func service(at now: UInt64) {
            output.clock.withLock { $0 = now }
            worker.service(at: now)
        }
    }

    @Test(arguments: TrackpadSingleTap.allCases, [40_000_000 as UInt64, 40_000_001, 200_000_000])
    func bufferedStallRejectsStaleStrokeAndFreshTapRecovers(_ tap: TrackpadSingleTap, _ delay: UInt64) throws {
        var h = try Harness(tap)
        h.enqueueTap(tap, endingAt: lift)
        h.drain(at: lift + delay)
        // At 40 ms the oldest frame is exactly 100 ms old and remains admissible.
        let accepted = delay == 40_000_000
        #expect(h.submitReady(at: lift + 60_000_000 + delay) == accepted)
        h.service(at: lift + 80_000_000 + delay)
        #expect(h.output.posts.withLock { $0.count } == (accepted ? 2 : 0))
        #expect(h.consumerDiagnostics.contains("stale-frame") == !accepted)
        #expect(h.consumerDiagnostics.filter { $0.hasPrefix("frame-age-") }.count == 4)
        h.enqueueTap(tap, endingAt: lift + 1_000_000_000)
        h.drain(at: lift + 1_000_000_000)
        #expect(h.submitReady(at: lift + 1_060_000_000) == true)
        h.service(at: lift + 1_080_000_000)
        h.service(at: lift + 1_090_000_000)
        #expect(h.output.posts.withLock { $0 } == Array(repeating: [CGEventType.keyDown, .keyUp], count: accepted ? 2 : 1).flatMap { $0 })
    }

    @Test(arguments: TrackpadSingleTap.allCases, [160_000_000 as UInt64, 160_000_001, 1_000_000_000])
    func stallAfterReleaseBoundsSettlingAndDoesNotReplay(_ tap: TrackpadSingleTap, _ delay: UInt64) throws {
        var h = try Harness(tap)
        h.enqueueTap(tap, endingAt: lift)
        h.drain(at: lift)
        let accepted = delay == 160_000_000
        #expect(h.submitReady(at: lift + delay) == accepted)
        h.service(at: lift + delay)
        #expect(h.submitReady(at: lift + delay + 10_000_000) == false)
        #expect(h.output.posts.withLock { $0.count } == (accepted ? 2 : 0))
        h.enqueueTap(tap, endingAt: lift + 2_000_000_000)
        h.drain(at: lift + 2_000_000_000)
        #expect(h.submitReady(at: lift + 2_060_000_000) == true)
        h.service(at: lift + 2_080_000_000)
        #expect(h.output.posts.withLock { $0.count } == (accepted ? 4 : 2))
    }

    @Test(arguments: TrackpadSingleTap.allCases, [20_000_000 as UInt64, 100_000_000, 100_000_001])
    func workerDelayBoundsOutputAndReportsOnlyPostedQueueAge(_ tap: TrackpadSingleTap, _ delay: UInt64) throws {
        var h = try Harness(tap)
        let queuedAt = lift + 60_000_000
        h.enqueueTap(tap, endingAt: lift)
        h.drain(at: lift)
        try #require(h.submitReady(at: queuedAt) == true)
        h.service(at: queuedAt + delay)
        h.service(at: queuedAt + delay + 10_000_000)
        let accepted = delay <= 100_000_000
        #expect(h.output.posts.withLock { $0.count } == (accepted ? 2 : 0))
        #expect(h.output.diagnostics.withLock { $0 } == (accepted ? [delay == 20_000_000
            ? "posted-queue-age-le-20ms" : "posted-queue-age-le-100ms"] : []))
        #expect(h.mailbox.state.withLock { $0.enabled && !$0.emergencyPause && $0.actionFailed == nil })
        h.enqueueTap(tap, endingAt: lift + 1_000_000_000)
        h.drain(at: lift + 1_000_000_000)
        #expect(h.submitReady(at: lift + 1_060_000_000) == true)
        h.service(at: lift + 1_080_000_000)
        #expect(h.output.posts.withLock { $0.count } == (accepted ? 4 : 2))
    }

    @Test(arguments: TrackpadSingleTap.allCases, [80_000_000 as UInt64, 80_000_001])
    func expiryDuringSenderPreparationCancelsBeforePostingAndRecovers(_ tap: TrackpadSingleTap, _ delay: UInt64) throws {
        var h = try Harness(tap)
        h.enqueueTap(tap, endingAt: lift)
        h.drain(at: lift)
        try #require(h.submitReady(at: lift + 60_000_000) == true)
        h.output.preparationDelay.withLock { $0 = delay }
        h.service(at: lift + 80_000_000)
        let accepted = delay == 80_000_000
        #expect(h.output.posts.withLock { $0.count } == (accepted ? 2 : 0))
        #expect(h.output.diagnostics.withLock { $0 } == [accepted ? "posted-queue-age-le-100ms" : "output-expired"])
        h.output.preparationDelay.withLock { $0 = 0 }
        h.enqueueTap(tap, endingAt: lift + 1_000_000_000)
        h.drain(at: lift + 1_000_000_000)
        #expect(h.submitReady(at: lift + 1_060_000_000) == true)
        h.service(at: lift + 1_080_000_000)
        #expect(h.output.posts.withLock { $0.count } == (accepted ? 4 : 2))
        #expect(h.mailbox.state.withLock { $0.enabled && !$0.emergencyPause && $0.actionFailed == nil })
    }

    @Test(arguments: TrackpadSingleTap.allCases)
    func repeatedBusyConsumersCancelOldOutputAndDeliverOnlyFreshTaps(_ tap: TrackpadSingleTap) throws {
        var h = try Harness(tap)
        for cycle in 0..<200 {
            let end = lift + UInt64(cycle) * 3_000_000_000
            h.enqueueTap(tap, endingAt: end)
            h.drain(at: end + (cycle % 3 == 0 ? 200_000_000 : 0))
            let decision = end + (cycle % 3 == 1 ? 160_000_001 : 260_000_000)
            // The third mode qualifies in time, then expires in the worker.
            if cycle % 3 == 2 {
                try #require(h.submitReady(at: end + 60_000_000) == true)
            } else {
                #expect(h.submitReady(at: decision) == false)
            }
            h.service(at: end + 300_000_000)
            #expect(h.output.posts.withLock { $0.count } == cycle * 2)
            h.enqueueTap(tap, endingAt: end + 1_000_000_000)
            h.drain(at: end + 1_000_000_000)
            try #require(h.submitReady(at: end + 1_060_000_000) == true)
            h.service(at: end + 1_080_000_000)
            h.service(at: end + 1_090_000_000)
            #expect(h.output.posts.withLock { $0.count } == (cycle + 1) * 2)
        }
        #expect(h.output.diagnostics.withLock { $0 } == Array(repeating: "posted-queue-age-le-20ms", count: 200))
        #expect(h.mailbox.state.withLock { $0.enabled && !$0.emergencyPause && $0.actionFailed == nil })
    }
}
