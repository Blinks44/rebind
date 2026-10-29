import Foundation
import Testing
@testable import rebind

/// Exercises the production controller without native discovery, permissions or input posting.
@MainActor struct MagicMouseCaptureTests {
    private final class Surface: MagicMouseCaptureDevice {
        let buffer: NativeTrackpadBuffer
        var starts = 0
        var stops = 0
        var canStart = true
        init(mailbox: EngineMailbox) { buffer = NativeTrackpadBuffer(mailbox: mailbox, isMagicMouse: true) }
        func start() -> Bool {
            starts += 1
            buffer.setAccepting(canStart)
            return canStart
        }
        func stop() { stops += 1; buffer.setAccepting(false) }
    }

    @MainActor private final class Harness {
        let mailbox = EngineMailbox()
        let surface: Surface
        var connected: Surface?
        var now: UInt64 = 0
        var frameID: Int32 = 0
        var discoveries = 0
        lazy var capture = MagicMouseCapture(mailbox: mailbox, acquireDevice: { [unowned self] in
            discoveries += 1
            return connected
        }, clock: { [unowned self] in now })

        init() {
            surface = Surface(mailbox: mailbox)
            connected = surface
            mailbox.configure(Configuration(isEnabled: true, bindings: [
                rebind.Binding(scope: .magicMouse, trigger: .magicMouseTap(fingers: 1), modifiers: [], action: .doNothing),
                rebind.Binding(scope: .magicMouse, trigger: .magicMouseTap(fingers: 2), modifiers: .option, action: .doNothing),
                rebind.Binding(scope: .builtInTrackpad, trigger: .threeFingerTap, modifiers: [], action: .doNothing)
            ]))
            mailbox.state.withLock { $0.status = .active }
        }

        func service(allowingInput: Bool = true, modifiers: ModifierSet = [], buttonsDown: Bool = false) {
            capture.service(allowingInput: allowingInput, foregroundPID: 100, modifiers: modifiers, buttonsDown: buttonsDown)
        }

        func tap(_ fingers: Int = 1, endingAt end: UInt64) throws {
            let device = try #require(connected)
            let control = mailbox.state.withLock { ($0.actionRevision, $0.magicMouseActivity) }
            for (index, count) in [0, fingers, fingers, 0].enumerated() {
                let receipt = end - UInt64(3 - index) * 20_000_000
                var frame = NativeTrackpadFrame(receipt: receipt, revision: control.0, activity: control.1,
                    frame: frameID, time: Double(receipt) / 1_000_000_000, count: count)
                frameID += 1
                if count > 0 { frame.first = .init(id: 1, x: 0.4, y: 0.5, pressure: 0) }
                if count > 1 { frame.second = .init(id: 2, x: 0.6, y: 0.5, pressure: 0) }
                device.buffer.state.withLock {
                    $0.lastReceipt = receipt
                    $0.append(frame, generation: $0.generation)
                }
            }
            now = end
            service(modifiers: fingers == 2 ? .option : [])
        }
    }

    @Test(arguments: [1, 2])
    func idleDiscoveryKeepsTheObserverAndDeliversOnlyOnce(_ fingers: Int) throws {
        let h = Harness()
        h.service()
        h.now = 2_000_000_000
        h.service()
        #expect(h.discoveries == 2 && h.surface.starts == 1)
        try h.tap(fingers, endingAt: 4_000_000_000)
        #expect(h.mailbox.nextAction() == nil)
        h.now += 60_000_000
        h.service(modifiers: fingers == 2 ? .option : [])
        let output = try #require(h.mailbox.nextAction())
        #expect(output.trackpadTarget?.isMagicMouse == true)
        #expect(output.trackpadTarget?.modifiers == (fingers == 2 ? .option : []))
        h.now += 10_000_000
        h.service(modifiers: fingers == 2 ? .option : [])
        #expect(h.mailbox.nextAction() == nil)
        h.capture.stop()
    }

    @Test func disconnectionCancelsQueuedOutputAndReplacementArmsIndependently() throws {
        let h = Harness()
        h.service()
        try h.tap(endingAt: 4_000_000_000)
        h.now += 60_000_000
        h.service()
        try #require(h.mailbox.state.withLock { $0.trackpadDispatch != nil })
        h.connected = nil
        h.now = 6_100_000_000
        h.service()
        #expect(h.mailbox.state.withLock { $0.magicMouseStatus } == .unavailable)
        #expect(h.mailbox.nextAction() == nil)
        #expect(h.surface.buffer.state.withLock { $0.accepting } == false)
        let replacement = Surface(mailbox: h.mailbox)
        h.connected = replacement
        h.now = 8_200_000_000
        h.service()
        try h.tap(endingAt: 9_000_000_000)
        h.now += 60_000_000
        h.service()
        #expect(h.mailbox.nextAction() == nil) // Replacement is still inside the three-second gate.
        try h.tap(endingAt: 12_000_000_000)
        h.now += 60_000_000
        h.service()
        #expect(h.mailbox.nextAction()?.trackpadTarget?.isMagicMouse == true)
        #expect(replacement.starts == 1)
        h.capture.stop()
    }

    @Test(arguments: 0...4)
    func temporaryAdmissionChangesWakeDormantCaptureWithoutATapStatusChange(_ cause: Int) {
        let h = Harness()
        h.capture.start()
        defer { h.capture.stop() }
        h.capture.refreshControl()
        switch cause {
        case 0: h.mailbox.setEditing(true)
        case 1: h.mailbox.record(.init(target: .output))
        case 2: h.mailbox.state.withLock { $0.excludedApplications = ["com.example.excluded"] }
            h.mailbox.setForegroundApplication("com.example.excluded")
        case 3: h.mailbox.configure(Configuration(isEnabled: false))
        default: h.mailbox.suspend(true)
        }
        h.capture.refreshControl()
        h.service()
        #expect((h.capture.nextPollDate ?? .distantPast) > Date().addingTimeInterval(86_400))
        switch cause {
        case 0: h.mailbox.setEditing(false)
        case 1: h.mailbox.record(nil)
        case 2: h.mailbox.setForegroundApplication("com.example.allowed")
        case 3: h.mailbox.configure(Configuration(isEnabled: true, bindings: [
            rebind.Binding(scope: .magicMouse, trigger: .magicMouseTap(fingers: 1), modifiers: [], action: .doNothing)
        ]))
        default: h.mailbox.suspend(false)
            h.mailbox.state.withLock { $0.status = .active }
        }
        h.capture.refreshControl()
        #expect((h.capture.nextPollDate ?? .distantFuture) < Date().addingTimeInterval(1))
        h.service()
        #expect(h.mailbox.state.withLock { $0.magicMouseStatus } == .active)
        let deadline = h.capture.nextPollDate
        h.capture.refreshControl()
        #expect(h.capture.nextPollDate == deadline) // Unchanged model refresh must not poll the surface.
    }

    @Test(arguments: [false, true])
    func permissionLossAndStopClearOnlyMouseOwnedOutput(_ stop: Bool) throws {
        let h = Harness()
        h.service()
        let runtime = try #require(h.mailbox.magicMouseRuntime())
        try #require(h.mailbox.submitMagicMouse(runtime, trigger: .magicMouseTap(fingers: 1), pid: 100, at: 0))
        if stop { h.capture.stop() } else { h.service(allowingInput: false) }
        #expect(h.mailbox.nextAction() == nil)
        let trackpad = try #require(h.mailbox.trackpadRuntime())
        try #require(h.mailbox.submitTrackpad(trackpad, gesture: .single(.threeFinger), pid: 100, at: 0))
        if stop { h.capture.stop() } else { h.service(allowingInput: false) }
        #expect(h.mailbox.nextAction()?.trackpadTarget?.isMagicMouse == false)
        h.capture.stop()
    }

    @Test func failedConnectionRecoversOnlyWithANewObserver() {
        let h = Harness()
        h.surface.canStart = false
        h.service()
        #expect(h.mailbox.state.withLock { $0.magicMouseStatus } == .failed)
        h.now = 2_100_000_000
        h.service()
        #expect(h.surface.starts == 1) // A failed connection is not restarted every poll.
        let replacement = Surface(mailbox: h.mailbox)
        h.connected = replacement
        h.now = 4_200_000_000
        h.service()
        #expect(h.mailbox.state.withLock { $0.magicMouseStatus } == .active)
        #expect(replacement.starts == 1)
        h.capture.stop()
    }
}
