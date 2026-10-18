import Foundation
import Synchronization
import Testing
@testable import rebind

/// The engine threads sleep while idle and wake on work, not on a fixed poll.
struct IdleWakeTests {
    private let shortcut = KeyboardShortcut(keyCode: 123, modifiers: [])

    private func dispatching() -> EngineMailbox.State {
        var state = EngineMailbox.State()
        state.enabled = true
        state.status = .active
        state.keyRepeat = KeyRepeatTiming(delayNanoseconds: 500, intervalNanoseconds: 80)
        return state
    }

    @Test func nothingIsDueWhileIdle() {
        #expect(dispatching().nextWorkDeadline(at: 1_000) == nil)
    }

    @Test func queuedWorkAndReleasesAreDueAtOnce() {
        var state = dispatching()
        state.pending.append(.shortcut(shortcut))
        #expect(state.nextWorkDeadline(at: 1_000) == 1_000)
        // A release is owed even while rules cannot run.
        var paused = EngineMailbox.State()
        paused.held.append(HeldOutput(trigger: .key(0), action: .shortcut(shortcut), pressedAt: 10, released: true))
        #expect(paused.nextWorkDeadline(at: 1_000) == 1_000)
    }

    @Test func aHeldKeyWakesForItsNextRepeat() {
        var state = dispatching()
        state.held.append(HeldOutput(trigger: .key(0), action: .shortcut(shortcut), pressedAt: 1_000))
        #expect(state.nextWorkDeadline(at: 1_100) == 1_500)
        state.held[0].lastRepeatAt = 1_600
        #expect(state.nextWorkDeadline(at: 1_620) == 1_680)
        // A held modifier is pressed once and needs no wake-up until it is released.
        state.held = [HeldOutput(trigger: .key(0), action: .modifier(.command), pressedAt: 1_000)]
        #expect(state.nextWorkDeadline(at: 1_100) == nil)
    }

    @Test func aSignalEndsTheWaitAtOnceAndIdleWaitsAreBounded() {
        let mailbox = EngineMailbox()
        mailbox.signalWork()
        var start = DispatchTime.now().uptimeNanoseconds
        mailbox.waitForWork(idle: 2_000_000_000)
        #expect(DispatchTime.now().uptimeNanoseconds - start < 500_000_000)
        start = DispatchTime.now().uptimeNanoseconds
        mailbox.waitForWork(idle: 30_000_000)
        #expect(DispatchTime.now().uptimeNanoseconds - start >= 20_000_000)
    }

    @Test func aMatchedPressWakesTheWorker() {
        let mailbox = EngineMailbox()
        let binding = rebind.Binding(scope: .allKeyboards, trigger: .key(0), modifiers: .control,
                                     action: .shortcut(KeyboardShortcut(keyCode: 13, modifiers: .command)))
        mailbox.configure(Configuration(isEnabled: true, bindings: [binding]))
        mailbox.waitForWork(idle: 1) // Consume the configuration's signal.
        #expect(mailbox.handle(InputEvent(trigger: .key(0), modifiers: .control, phase: .down), secureInput: false))
        let start = DispatchTime.now().uptimeNanoseconds
        mailbox.waitForWork(idle: 2_000_000_000)
        #expect(DispatchTime.now().uptimeNanoseconds - start < 500_000_000)
    }

    @Test func thePointerAppRestartsAGlideOnlyWhenItChangesTheDecision() {
        let mailbox = EngineMailbox()
        mailbox.state.withLock {
            $0.smoothScrollingExclusions = ["com.example.excluded"]
            $0.foregroundBundleID = "com.example.front"
        }
        let revision = mailbox.state.withLock { $0.smoothScrollingRevision }
        mailbox.setPointerApplication("com.example.front")
        mailbox.setPointerApplication("com.example.other")
        #expect(mailbox.state.withLock { $0.smoothScrollingRevision } == revision)
        mailbox.setPointerApplication("com.example.excluded")
        #expect(mailbox.state.withLock { $0.smoothScrollingRevision } != revision)
    }

    @Test func aQuietTrackpadBufferWakesItsConsumerOncePerTouch() {
        let buffer = NativeTrackpadBuffer(mailbox: EngineMailbox())
        let wakes = Mutex(0)
        buffer.setWake { wakes.withLock { $0 += 1 } }
        buffer.setAccepting(true)
        #expect(buffer.sleepIfQuiet(since: DispatchTime.now().uptimeNanoseconds + 1))
        buffer.receive(nil, count: 0)
        buffer.receive(nil, count: 0)
        #expect(wakes.withLock { $0 } == 1)
        // A frame newer than the cutoff keeps it awake.
        #expect(!buffer.sleepIfQuiet(since: 0))
    }
}
