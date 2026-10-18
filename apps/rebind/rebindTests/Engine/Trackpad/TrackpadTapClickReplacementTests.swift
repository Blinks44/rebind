import Testing
@testable import rebind

struct TrackpadTapClickReplacementTests {
    private let lift: UInt64 = 4_000_000_000

    private struct Harness {
        let mailbox = EngineMailbox()
        var runtime: TrackpadRuntime
        var session: TrackpadTapSession
        var nextID: Int32 = 0
        let magic: Bool

        init(magic: Bool = false, double: Bool = false, modifiers: ModifierSet = []) throws {
            self.magic = magic
            let triggers: [InputTrigger] = double ? [.threeFingerTap, .threeFingerDoubleTap] : [.threeFingerTap]
            let rules = triggers.map {
                rebind.Binding(scope: magic ? .magicTrackpad : .builtInTrackpad, trigger: $0, modifiers: modifiers,
                               action: .shortcut(.init(keyCode: 13, modifiers: .command)))
            }
            mailbox.configure(Configuration(isEnabled: true, bindings: rules))
            mailbox.state.withLock {
                $0.status = .active; $0.foregroundPID = 100
                if magic { $0.magicTrackpadClicks.beginCapture(at: 0) }
                else { $0.trackpadClicks.beginCapture(at: 0) }
            }
            runtime = try #require(mailbox.trackpadRuntime(magicTrackpad: magic, modifiers: modifiers))
            session = TrackpadTapSession(runtime: runtime, foreground: 100, startedAt: 0)
        }

        mutating func contact(_ count: Int, at time: UInt64, shift: Float = 0, force: Float = 45,
                              reportsForce: Bool = false) {
            var frame = NativeTrackpadFrame(receipt: time, revision: runtime.revision,
                activity: runtime.inputActivity, frame: nextID, time: Double(time) / 1_000_000_000, count: count)
            nextID += 1
            if count > 0 { frame.first = .init(id: 0, x: 0.3 + shift, y: 0.5, pressure: force) }
            if count > 1 { frame.second = .init(id: 1, x: 0.4, y: 0.5, pressure: force) }
            if count > 2 { frame.third = .init(id: 2, x: 0.5, y: 0.5, pressure: force) }
            if count > 3 { frame.fourth = .init(id: 3, x: 0.6, y: 0.5, pressure: force) }
            mailbox.state.withLock {
                if magic { $0.magicTrackpadClicks.observe(frame, reportsForce: reportsForce) }
                else { $0.trackpadClicks.observe(frame, reportsForce: reportsForce) }
            }
            session.consume(frame, at: time)
        }

        mutating func tap(endingAt time: UInt64) {
            contact(0, at: time - 60_000_000)
            contact(3, at: time - 40_000_000)
            contact(3, at: time - 20_000_000)
            contact(0, at: time)
        }

        func button(_ phase: InputEvent.Phase, at time: UInt64, touch: Bool = true,
                    modifiers: ModifierSet = []) -> Bool {
            mailbox.handle(.init(trigger: .mouseButton(0), modifiers: modifiers, phase: phase,
                                 receivedAt: time, isTouchClick: touch), secureInput: false)
        }
    }

    @Test(arguments: [false, true])
    func nativeClickIsReplacedAndSingleNeedsOnlyClickSettling(_ magic: Bool) throws {
        var h = try Harness(magic: magic)
        h.tap(endingAt: lift)
        #expect(h.button(.down, at: lift + 12_000_000))
        #expect(h.button(.up, at: lift + 28_000_000))
        #expect(h.mailbox.trackpadRuntime(magicTrackpad: magic) == h.runtime)
        #expect(h.session.takeReadyGesture(at: lift + 59_999_999) == nil)
        #expect(h.session.takeReadyGesture(at: lift + 60_000_000) == .single(.threeFinger))
        #expect(h.session.takeReadyGesture(at: lift + 500_000_000) == nil)
    }

    @Test(arguments: [false, true])
    func nativeClicksDoNotCancelTheDoubleOrLeakASingle(_ magic: Bool) throws {
        var h = try Harness(magic: magic, double: true)
        for end in [lift, lift + 120_000_000] {
            h.tap(endingAt: end)
            #expect(h.button(.down, at: end + 12_000_000))
            #expect(h.button(.up, at: end + 28_000_000))
            #expect(h.mailbox.trackpadRuntime(magicTrackpad: magic) == h.runtime)
        }
        #expect(h.session.takeReadyGesture(at: lift + 180_000_000) == .double(.threeFinger))
        #expect(h.session.takeReadyGesture(at: lift + 500_000_000) == nil)
    }

    @Test(arguments: 0...9)
    func uncertainOrUnmatchedClicksPassThrough(_ defect: Int) throws {
        var h = try Harness()
        h.contact(0, at: lift - 60_000_000)
        h.contact(defect == 3 ? 4 : 3, at: lift - 40_000_000,
                  force: defect == 4 ? 120 : 45, reportsForce: defect == 4)
        if defect == 1 { h.nextID += 1 }
        h.contact(defect == 3 ? 4 : 3, at: lift - 20_000_000, shift: defect == 2 ? 0.1 : 0,
                  force: defect == 4 ? 120 : 45, reportsForce: defect == 4)
        h.contact(0, at: lift, reportsForce: defect == 4)
        switch defect {
        case 5: h.mailbox.state.withLock { $0.actionRevision += 1 }
        case 6: h.mailbox.state.withLock { $0.inputActivity += 1 }
        case 7: h.mailbox.state.withLock { $0.editing = true }
        case 8: h.contact(1, at: lift + 5_000_000)
        default: break
        }
        #expect(h.button(.down, at: lift + (defect == 9 ? TrackpadClickFilter.tapClickWindow + 1 : 12_000_000),
                         touch: defect != 0) == false)
        if defect == 0 {
            #expect(h.mailbox.trackpadRuntime()?.inputActivity != h.runtime.inputActivity)
        }
    }

    @Test func modifiersAndCaptureArmingMustMatch() throws {
        var h = try Harness(modifiers: .shift)
        h.tap(endingAt: lift)
        #expect(h.button(.down, at: lift + 12_000_000) == false)
        h.tap(endingAt: lift + 500_000_000)
        #expect(h.button(.down, at: lift + 512_000_000, modifiers: .shift))
        h.mailbox.state.withLock { $0.trackpadClicks.beginCapture(at: lift + 1_000_000_000) }
        h.tap(endingAt: lift + 1_100_000_000)
        #expect(h.button(.down, at: lift + 1_112_000_000, modifiers: .shift) == false)
    }

    @Test func consumedReleaseRemainsOwnedAfterPause() throws {
        var h = try Harness()
        h.tap(endingAt: lift)
        #expect(h.button(.down, at: lift + 12_000_000))
        h.mailbox.state.withLock { $0.enabled = false }
        #expect(h.button(.up, at: lift + 28_000_000))
        #expect(h.button(.up, at: lift + 40_000_000) == false)
    }
}
