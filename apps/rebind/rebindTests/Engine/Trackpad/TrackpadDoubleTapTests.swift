import Foundation
import Synchronization
import Testing
@testable import rebind

struct TrackpadDoubleTapTests {
    private let lift: UInt64 = 4_000_000_000

    private struct Harness {
        let mailbox: EngineMailbox
        var runtime: TrackpadRuntime
        let buffer: NativeTrackpadBuffer
        var session: TrackpadTapSession
        var nextID: Int32 = 1

        init(singles: [TrackpadSingleTap] = TrackpadSingleTap.allCases,
             doubles: [TrackpadSingleTap] = TrackpadSingleTap.allCases,
             twoFingerDouble: Bool = false,
             interval: UInt64 = 500_000_000) throws {
            mailbox = EngineMailbox()
            let gestures = singles.map(TrackpadTapGesture.single) + doubles.map(TrackpadTapGesture.double)
                + (twoFingerDouble ? [TrackpadTapGesture.twoFingerDouble] : [])
            let rules = gestures.enumerated().map { index, gesture in
                rebind.Binding(scope: .builtInTrackpad, trigger: gesture.trigger, modifiers: [],
                               action: .shortcut(.init(keyCode: UInt16(13 + index), modifiers: .command)))
            }
            mailbox.configure(Configuration(isEnabled: true, bindings: rules), doublePressIntervalNanoseconds: interval)
            mailbox.state.withLock { $0.status = .active; $0.foregroundPID = 100 }
            runtime = try #require(mailbox.trackpadRuntime())
            buffer = NativeTrackpadBuffer(mailbox: mailbox)
            buffer.setAccepting(true)
            session = TrackpadTapSession(runtime: runtime, foreground: 100, startedAt: 0)
            let neutral = NativeTrackpadFrame(receipt: 3_900_000_000, revision: runtime.revision,
                activity: runtime.inputActivity, frame: 0, time: 3.9, count: 0)
            session.consume(neutral, at: neutral.receipt)
        }

        mutating func frame(fingers: Int, at time: UInt64, offset: Float = 0,
                            moved: Bool = false, gap: Bool = false) -> NativeTrackpadFrame {
            if gap { nextID += 1 }
            var value = NativeTrackpadFrame(receipt: time, revision: runtime.revision,
                activity: runtime.inputActivity, frame: nextID, time: Double(time) / 1_000_000_000, count: fingers)
            nextID += 1
            if fingers > 0 { value.first = .init(id: 0, x: (moved ? 0.45 : 0.2) + offset, y: 0.5, pressure: 45) }
            if fingers > 1 { value.second = .init(id: 1, x: 0.3 + offset, y: 0.5, pressure: 45) }
            if fingers > 2 { value.third = .init(id: 2, x: 0.4 + offset, y: 0.5, pressure: 45) }
            if fingers > 3 { value.fourth = .init(id: 3, x: 0.5 + offset, y: 0.5, pressure: 45) }
            return value
        }

        mutating func consume(fingers: Int, at time: UInt64, offset: Float = 0,
                              moved: Bool = false, gap: Bool = false) {
            let value = frame(fingers: fingers, at: time, offset: offset, moved: moved, gap: gap)
            session.consume(value, at: time)
        }

        mutating func tap(_ tap: TrackpadSingleTap, endingAt time: UInt64, offset: Float = 0,
                          moved: Bool = false, gap: Bool = false) {
            consume(fingers: tap.rawValue, at: time - 40_000_000, offset: offset)
            consume(fingers: tap.rawValue, at: time - 20_000_000, offset: offset, moved: moved, gap: gap)
            consume(fingers: 0, at: time)
        }

        mutating func tapTwoFinger(endingAt time: UInt64, offset: Float = 0,
                                  moved: Bool = false, gap: Bool = false) {
            consume(fingers: 2, at: time - 40_000_000, offset: offset)
            consume(fingers: 2, at: time - 20_000_000, offset: offset, moved: moved, gap: gap)
            consume(fingers: 0, at: time)
        }

        mutating func ready(at time: UInt64) -> TrackpadTapGesture? {
            session.takeReadyGesture(from: buffer, at: time)
        }
    }

    @Test(arguments: TrackpadSingleTap.allCases, [false, true])
    func pairProducesOnlyItsDoubleOnceIncludingFastSecondContact(_ tap: TrackpadSingleTap, _ fast: Bool) throws {
        var h = try Harness()
        h.tap(tap, endingAt: lift)
        #expect(h.ready(at: lift + 40_000_000) == nil)
        let end = lift + (fast ? 90_000_000 : 250_000_000)
        if !fast { #expect(h.ready(at: lift + 60_000_000) == nil) }
        h.tap(tap, endingAt: end)
        #expect(h.ready(at: end + 59_999_999) == nil)
        #expect(h.ready(at: end + 60_000_000) == .double(tap))
        #expect(h.ready(at: end + 500_000_000) == nil)
        h.tap(tap, endingAt: end + 600_000_000)
        #expect(h.ready(at: end + 660_000_000) == nil)
        #expect(h.ready(at: end + 1_100_000_000) == .single(tap))
        #expect(h.ready(at: end + 1_110_000_000) == nil)
    }

    @Test(arguments: TrackpadSingleTap.allCases, [80_000_000 as UInt64, 500_000_000, 900_000_000])
    func loneTapWaitsForConfiguredSystemInterval(_ tap: TrackpadSingleTap, _ interval: UInt64) throws {
        var h = try Harness(interval: interval)
        #expect(h.runtime.doubleTapIntervalNanoseconds == interval)
        h.tap(tap, endingAt: lift)
        #expect(h.ready(at: lift + 60_000_000) == nil)
        #expect(h.ready(at: lift + interval - 1) == nil)
        #expect(h.ready(at: lift + interval) == .single(tap))
        #expect(h.ready(at: lift + interval + 1) == nil)
    }

    @Test(arguments: TrackpadSingleTap.allCases)
    func doubleOnlyNeverFallsBackAndOtherFingerSingleDoesNotWait(_ tap: TrackpadSingleTap) throws {
        let other: TrackpadSingleTap = tap == .threeFinger ? .fourFinger : .threeFinger
        var h = try Harness(singles: [other], doubles: [tap])
        h.tap(tap, endingAt: lift)
        #expect(h.ready(at: lift + 60_000_000) == nil)
        #expect(h.ready(at: lift + 500_000_000) == nil)
        h.tap(other, endingAt: lift + 600_000_000)
        #expect(h.ready(at: lift + 660_000_000) == .single(other))
        #expect(h.mailbox.submitTrackpad(h.runtime, gesture: .double(other), pid: 100, at: lift) == false)
    }

    @Test(arguments: TrackpadSingleTap.allCases, [false, true])
    func secondStartDeadlineIsExclusiveButItsReleaseCanFinishLater(_ tap: TrackpadSingleTap, _ exact: Bool) throws {
        var h = try Harness()
        h.tap(tap, endingAt: lift)
        #expect(h.ready(at: lift + 60_000_000) == nil)
        let end = lift + 540_000_000 - (exact ? 0 : 1)
        h.tap(tap, endingAt: end)
        #expect(h.ready(at: end + 60_000_000) == (exact ? nil : .double(tap)))
        if exact { #expect(h.ready(at: end + 500_000_000) == .single(tap)) }
    }

    @Test(arguments: TrackpadSingleTap.allCases, [false, true])
    func mismatchedPairDropsOlderFallbackAndStartsNewSingle(_ tap: TrackpadSingleTap, _ distant: Bool) throws {
        var h = try Harness()
        h.tap(tap, endingAt: lift)
        #expect(h.ready(at: lift + 60_000_000) == nil)
        let next: TrackpadSingleTap = distant ? tap : tap == .threeFinger ? .fourFinger : .threeFinger
        h.tap(next, endingAt: lift + 250_000_000, offset: distant ? 0.2 : 0)
        #expect(h.ready(at: lift + 310_000_000) == nil)
        #expect(h.ready(at: lift + 750_000_000) == .single(next))
        #expect(h.ready(at: lift + 760_000_000) == nil)
    }

    @Test(arguments: TrackpadSingleTap.allCases, 0...4)
    func uncertainSecondContactCancelsWholePairAndFreshTapsRecover(_ tap: TrackpadSingleTap, _ defect: Int) throws {
        var h = try Harness()
        h.tap(tap, endingAt: lift)
        #expect(h.ready(at: lift + 60_000_000) == nil)
        switch defect {
        case 0: h.tap(tap, endingAt: lift + 250_000_000, moved: true)
        case 1: h.tap(tap, endingAt: lift + 250_000_000, gap: true)
        case 2:
            h.consume(fingers: 1, at: lift + 210_000_000)
            h.consume(fingers: 1, at: lift + 230_000_000)
            h.consume(fingers: 0, at: lift + 250_000_000)
        case 3:
            h.consume(fingers: tap.rawValue, at: lift + 210_000_000)
            var empty = h.frame(fingers: 0, at: lift + 250_000_000)
            empty.frame = nil; empty.time = nil
            h.session.consume(empty, at: empty.receipt)
        default:
            h.consume(fingers: tap.rawValue, at: lift + 210_000_000)
            #expect(h.ready(at: lift + 650_000_000) == nil)
            h.consume(fingers: 0, at: lift + 660_000_000)
        }
        #expect(h.ready(at: lift + 750_000_000) == nil)
        h.consume(fingers: 0, at: lift + 800_000_000)
        h.tap(tap, endingAt: lift + 900_000_000)
        #expect(h.ready(at: lift + 960_000_000) == nil)
        h.tap(tap, endingAt: lift + 1_150_000_000)
        #expect(h.ready(at: lift + 1_210_000_000) == .double(tap))
    }

    @Test(arguments: TrackpadSingleTap.allCases, [false, true])
    func clickActivityBeforeOrAfterPairCancelsAllOutput(_ tap: TrackpadSingleTap, _ afterPair: Bool) throws {
        var h = try Harness()
        h.tap(tap, endingAt: lift)
        if afterPair { h.tap(tap, endingAt: lift + 90_000_000) }
        _ = h.mailbox.handle(InputEvent(trigger: .mouseButton(0), phase: .down), secureInput: false)
        h.runtime = try #require(h.mailbox.trackpadRuntime())
        h.session.update(runtime: h.runtime, foreground: 100)
        #expect(h.ready(at: lift + 150_000_000) == nil)
        #expect(h.ready(at: lift + 600_000_000) == nil)
        h.tap(tap, endingAt: lift + 700_000_000)
        h.tap(tap, endingAt: lift + 790_000_000)
        #expect(h.ready(at: lift + 850_000_000) == .double(tap))
    }

    @Test(arguments: TrackpadSingleTap.allCases, 0...3)
    func bufferedContactLossAndStoppedProducerPreventDispatch(_ tap: TrackpadSingleTap, _ defect: Int) throws {
        var h = try Harness()
        h.tap(tap, endingAt: lift)
        h.tap(tap, endingAt: lift + 90_000_000)
        switch defect {
        case 0:
            let contact = h.frame(fingers: tap.rawValue, at: lift + 145_000_000)
            h.buffer.state.withLock { $0.frames[0] = contact; $0.head = 0; $0.count = 1 }
        case 1: h.buffer.state.withLock { $0.overflow = true }
        case 2: h.buffer.setAccepting(false)
        default: break
        }
        let ready = h.ready(at: lift + (defect == 3 ? 250_000_001 : 150_000_000))
        #expect(ready == nil)
    }

    @Test(arguments: TrackpadSingleTap.allCases)
    func targetedWorkerDeliversDoubleIdentityAndNeverUsesGlobalSender(_ tap: TrackpadSingleTap) throws {
        var h = try Harness()
        h.tap(tap, endingAt: lift)
        h.tap(tap, endingAt: lift + 90_000_000)
        let result = h.ready(at: lift + 150_000_000)
        let gesture = try #require(result)
        let outputs = Mutex<[KeyboardShortcut]>([])
        let worker = ActionWorker(mailbox: h.mailbox, capabilities: { AudioOutputCapabilities() },
            sendTrackpadShortcut: { shortcut, target, canPerform in
                #expect(target.pid == 100 && canPerform())
                outputs.withLock { $0.append(shortcut) }
                return .performed
            }, sendShortcut: { _ in Issue.record("Trackpad used global output"); return false },
            secureInput: { false }, postingAllowed: { true })
        #expect(h.mailbox.submitTrackpad(h.runtime, gesture: gesture, pid: 100, at: lift + 150_000_000))
        worker.service(at: lift + 160_000_000)
        worker.service(at: lift + 170_000_000)
        #expect(outputs.withLock { $0 } == [h.runtime.shortcut(for: .double(tap))].compactMap { $0 })
    }

    @Test(arguments: TrackpadSingleTap.allCases)
    func receiptJustBeforePreviousPollStillCompletesPair(_ tap: TrackpadSingleTap) throws {
        var h = try Harness()
        h.tap(tap, endingAt: lift)
        #expect(h.ready(at: lift + 60_000_000) == nil)
        #expect(h.ready(at: lift + 200_000_000) == nil)
        h.tap(tap, endingAt: lift + 239_000_000)
        #expect(h.ready(at: lift + 299_000_000) == .double(tap))
    }

    @Test(arguments: TrackpadSingleTap.allCases, [false, true])
    func delayedSingleLatenessIsBoundedAfterSuccessfulSettling(_ tap: TrackpadSingleTap, _ late: Bool) throws {
        var h = try Harness()
        h.tap(tap, endingAt: lift)
        #expect(h.ready(at: lift + 60_000_000) == nil)
        #expect(h.ready(at: lift + 600_000_000 + (late ? 1 : 0)) == (late ? nil : .single(tap)))
        #expect(h.ready(at: lift + 610_000_000) == nil)
    }

    @Test(arguments: TrackpadSingleTap.allCases, 0...3)
    func discontinuityWhileWaitingCancelsOldSingle(_ tap: TrackpadSingleTap, _ defect: Int) throws {
        var h = try Harness()
        h.tap(tap, endingAt: lift)
        #expect(h.ready(at: lift + 60_000_000) == nil)
        var value = h.frame(fingers: 0, at: lift + 200_000_000)
        switch defect {
        case 0: value.valid = false
        case 1: value.revision &+= 1
        case 2: value.receipt = lift + 400_000_000
        default: value.receipt = lift + 99_999_999
        }
        h.session.consume(value, at: lift + 200_000_000)
        #expect(h.ready(at: lift + 500_000_000) == nil)
    }

    // The device goes silent after a release, so the next frame ID jumps. That
    // silence must neither break a pair nor cancel the pending single.
    @Test(arguments: TrackpadSingleTap.allCases, [false, true])
    func idleSilenceBetweenTapsKeepsPairAndPendingSingle(_ tap: TrackpadSingleTap, _ secondTap: Bool) throws {
        var h = try Harness()
        h.tap(tap, endingAt: lift)
        #expect(h.ready(at: lift + 60_000_000) == nil)
        h.nextID += 25
        if secondTap {
            h.tap(tap, endingAt: lift + 250_000_000)
            #expect(h.ready(at: lift + 310_000_000) == .double(tap))
        } else {
            h.consume(fingers: 0, at: lift + 200_000_000)
            #expect(h.ready(at: lift + 500_000_000) == .single(tap))
        }
    }

    @Test(arguments: [false, true])
    func idleSilenceBetweenTwoFingerTapsKeepsPair(_ slow: Bool) throws {
        var h = try Harness(singles: [], doubles: [], twoFingerDouble: true)
        h.tapTwoFinger(endingAt: lift)
        #expect(h.ready(at: lift + 60_000_000) == nil)
        h.nextID += 40
        let end = lift + (slow ? 400_000_000 : 200_000_000)
        h.tapTwoFinger(endingAt: end)
        #expect(h.ready(at: end + 60_000_000) == .twoFingerDouble)
    }

    @Test(arguments: TrackpadSingleTap.allCases)
    func trailingUntimedNeutralDoesNotErasePair(_ tap: TrackpadSingleTap) throws {
        var h = try Harness()
        h.tap(tap, endingAt: lift)
        var empty = h.frame(fingers: 0, at: lift + 10_000_000)
        empty.frame = nil; empty.time = nil
        h.session.consume(empty, at: empty.receipt)
        // Untimed neutrality resets the native frame clock, not the completed tap.
        #expect(h.ready(at: lift + 60_000_000) == nil)
        h.tap(tap, endingAt: lift + 250_000_000)
        #expect(h.ready(at: lift + 310_000_000) == .double(tap))
    }

    @Test(arguments: TrackpadSingleTap.allCases, 0...3)
    func focusConfigurationAndSessionEndCancelPendingSingleAndPair(_ tap: TrackpadSingleTap, _ kind: Int) throws {
        var h = try Harness()
        h.tap(tap, endingAt: lift)
        #expect(h.ready(at: lift + 60_000_000) == nil)
        switch kind {
        case 0: h.session.update(runtime: h.runtime, foreground: 200)
        case 1: h.session.update(runtime: h.runtime, foreground: nil)
        case 2:
            h.runtime.revision &+= 1
            h.session.update(runtime: h.runtime, foreground: 100)
        default: h.session.interrupt()
        }
        #expect(h.ready(at: lift + 500_000_000) == nil)
        // A partial second stroke after invalidation cannot be paired with old output.
        h.tap(tap, endingAt: lift + 600_000_000)
        #expect(h.ready(at: lift + 660_000_000) == nil)
    }

    @Test(arguments: TrackpadSingleTap.allCases)
    func disabledAndInactiveDoubleRulesDoNotDelaySingle(_ tap: TrackpadSingleTap) throws {
        var h = try Harness(singles: [tap], doubles: [tap])
        let shortcut = try #require(h.runtime.shortcut(for: .double(tap)))
        var disabled = rebind.Binding(scope: .builtInTrackpad, trigger: TrackpadTapGesture.double(tap).trigger,
            modifiers: [], action: .shortcut(shortcut))
        disabled.isEnabled = false
        let single = rebind.Binding(scope: .builtInTrackpad, trigger: tap.trigger, modifiers: [],
                                   action: .shortcut(shortcut))
        var config = Configuration(isEnabled: true, bindings: [single, disabled])
        var active = disabled; active.id = UUID(); active.isEnabled = true
        config.profiles.append(RuleProfile(name: "Inactive", bindings: [active]))
        try config.validate()
        h.mailbox.configure(config)
        h.runtime = try #require(h.mailbox.trackpadRuntime())
        h.session.update(runtime: h.runtime, foreground: 100)
        h.consume(fingers: 0, at: lift - 60_000_000)
        h.tap(tap, endingAt: lift)
        #expect(h.runtime.shortcut(for: .double(tap)) == nil)
        #expect(h.ready(at: lift + 60_000_000) == .single(tap))
        #expect(h.mailbox.submitTrackpad(h.runtime, gesture: .double(tap), pid: 100, at: lift) == false)
    }

    @Test(arguments: TrackpadSingleTap.allCases)
    func spoofedShortcutAndQuartzDoubleTriggerCannotDispatch(_ tap: TrackpadSingleTap) throws {
        let h = try Harness()
        var spoofed = h.runtime
        if tap == .threeFinger { spoofed.threeFingerDoubleShortcut = .init(keyCode: 0, modifiers: .command) }
        else { spoofed.fourFingerDoubleShortcut = .init(keyCode: 0, modifiers: .command) }
        #expect(h.mailbox.submitTrackpad(spoofed, gesture: .double(tap), pid: 100, at: lift) == false)
        #expect(h.mailbox.handle(InputEvent(trigger: TrackpadTapGesture.double(tap).trigger, phase: .down),
                                 secureInput: false) == false)
        #expect(h.mailbox.nextAction() == nil)
    }

    @Test(arguments: TrackpadSingleTap.allCases, [false, true])
    func receiptSkewPreservesNativeDurationThreshold(_ tap: TrackpadSingleTap, _ tooLong: Bool) throws {
        var h = try Harness(singles: [tap], doubles: [])
        for index in 0...10 {
            let receipt = lift + UInt64(index) * 45_000_000
            var value = h.frame(fingers: index == 10 ? 0 : tap.rawValue, at: receipt)
            value.time = 4 + Double(index) * (tooLong ? 0.0418 : 0.038)
            h.session.consume(value, at: receipt)
        }
        #expect(h.ready(at: lift + 510_000_000) == (tooLong ? nil : .single(tap)))
    }

    @Test(arguments: TrackpadSingleTap.allCases)
    func untimedContactCannotRearmOrBridgePendingPair(_ tap: TrackpadSingleTap) throws {
        var h = try Harness()
        h.tap(tap, endingAt: lift)
        #expect(h.ready(at: lift + 60_000_000) == nil)
        var value = h.frame(fingers: tap.rawValue, at: lift + 200_000_000)
        value.frame = nil; value.time = nil
        let rejection = h.session.consume(value, at: value.receipt)
        guard case .invalidFrame = rejection else { Issue.record("Untimed contact was not rejected"); return }
        h.consume(fingers: tap.rawValue, at: lift + 220_000_000)
        h.consume(fingers: tap.rawValue, at: lift + 240_000_000)
        h.consume(fingers: 0, at: lift + 260_000_000)
        #expect(h.ready(at: lift + 320_000_000) == nil)
        #expect(h.ready(at: lift + 760_000_000) == nil)
    }

    @Test(arguments: TrackpadSingleTap.allCases, [2_000_000_001 as UInt64, UInt64.max])
    func unsupportedSystemIntervalDisablesOnlyDoubles(_ tap: TrackpadSingleTap, _ interval: UInt64) throws {
        var h = try Harness(interval: interval)
        #expect(h.runtime.shortcut(for: .double(tap)) == nil)
        h.tap(tap, endingAt: lift)
        #expect(h.ready(at: lift + 60_000_000) == .single(tap))
        var spoofed = h.runtime
        let shortcut = try #require(spoofed.shortcut(for: .single(tap)))
        if tap == .threeFinger { spoofed.threeFingerDoubleShortcut = shortcut }
        else { spoofed.fourFingerDoubleShortcut = shortcut }
        #expect(h.mailbox.submitTrackpad(spoofed, gesture: .double(tap), pid: 100, at: lift) == false)
    }

    @Test(arguments: [2_000_000_001 as UInt64, UInt64.max])
    func unsupportedSystemIntervalDisablesTwoFingerDoubleOnly(_ interval: UInt64) throws {
        var h = try Harness(singles: [.threeFinger], doubles: [], twoFingerDouble: true, interval: interval)
        #expect(h.runtime.shortcut(for: .twoFingerDouble) == nil)
        h.tapTwoFinger(endingAt: lift)
        h.tapTwoFinger(endingAt: lift + 90_000_000)
        #expect(h.ready(at: lift + 150_000_000) == nil)
        #expect(h.ready(at: lift + 500_000_000) == nil)
        var spoofed = h.runtime
        spoofed.twoFingerDoubleShortcut = h.runtime.threeFingerShortcut
        #expect(h.mailbox.submitTrackpad(spoofed, gesture: .twoFingerDouble, pid: 100, at: lift) == false)
        h.tap(.threeFinger, endingAt: lift + 700_000_000)
        #expect(h.ready(at: lift + 760_000_000) == .single(.threeFinger))
    }

    @Test func twoFingerPairEmitsOneDoubleAndALoneTapNeverFallsBack() throws {
        var h = try Harness(twoFingerDouble: true)
        h.tapTwoFinger(endingAt: lift)
        #expect(h.ready(at: lift + 60_000_000) == nil)
        h.tapTwoFinger(endingAt: lift + 90_000_000)
        #expect(h.ready(at: lift + 149_999_999) == nil)
        #expect(h.ready(at: lift + 150_000_000) == .twoFingerDouble)
        #expect(h.ready(at: lift + 500_000_000) == nil)
        h.tapTwoFinger(endingAt: lift + 700_000_000)
        #expect(h.ready(at: lift + 760_000_000) == nil)
        h.tapTwoFinger(endingAt: lift + 810_000_000)
        #expect(h.ready(at: lift + 870_000_000) == .twoFingerDouble)
        #expect(h.ready(at: lift + 900_000_000) == nil)
        #expect(h.ready(at: lift + 1_700_000_000) == nil)
    }

    @Test func twoFingerPendingDropsOnOtherFingerTapsWithoutSingleFallback() throws {
        var h = try Harness(twoFingerDouble: true)
        h.tapTwoFinger(endingAt: lift)
        #expect(h.ready(at: lift + 60_000_000) == nil)
        h.tap(.threeFinger, endingAt: lift + 250_000_000)
        #expect(h.ready(at: lift + 310_000_000) == nil)
        #expect(h.ready(at: lift + 750_000_000) == .single(.threeFinger))
        #expect(h.ready(at: lift + 760_000_000) == nil)
    }

    @Test(arguments: [80_000_000 as UInt64, 500_000_000, 900_000_000])
    func loneTwoFingerTapNeverBecomesOutputAtAnyInterval(_ interval: UInt64) throws {
        var h = try Harness(singles: [], doubles: [], twoFingerDouble: true, interval: interval)
        #expect(h.runtime.doubleTapIntervalNanoseconds == interval)
        h.tapTwoFinger(endingAt: lift)
        #expect(h.ready(at: lift + 60_000_000) == nil)
        #expect(h.ready(at: lift + interval) == nil)
        h.tapTwoFinger(endingAt: lift + interval + 20_000_000)
        #expect(h.ready(at: lift + interval + 80_000_000) == nil)
        #expect(h.ready(at: lift + 2 * interval + 120_000_000) == nil)
    }

    @Test(arguments: [false, true])
    func physicalClickAroundTwoFingerPairCancelsAllOutput(_ afterPair: Bool) throws {
        var h = try Harness(singles: [], doubles: [], twoFingerDouble: true)
        h.tapTwoFinger(endingAt: lift)
        if afterPair { h.tapTwoFinger(endingAt: lift + 90_000_000) }
        _ = h.mailbox.handle(InputEvent(trigger: .mouseButton(0), phase: .down), secureInput: false)
        h.runtime = try #require(h.mailbox.trackpadRuntime())
        h.session.update(runtime: h.runtime, foreground: 100)
        #expect(h.ready(at: lift + 150_000_000) == nil)
        #expect(h.ready(at: lift + 700_000_000) == nil)
        h.consume(fingers: 0, at: lift + 710_000_000)
        h.tapTwoFinger(endingAt: lift + 800_000_000)
        h.tapTwoFinger(endingAt: lift + 890_000_000)
        #expect(h.ready(at: lift + 950_000_000) == .twoFingerDouble)
    }

    @Test func targetedWorkerDeliversTwoFingerDoubleAndNeverUsesGlobalSender() throws {
        var h = try Harness(singles: [], doubles: [], twoFingerDouble: true)
        h.tapTwoFinger(endingAt: lift)
        h.tapTwoFinger(endingAt: lift + 90_000_000)
        let result = h.ready(at: lift + 150_000_000)
        #expect(result == .twoFingerDouble)
        let outputs = Mutex<[KeyboardShortcut]>([])
        let worker = ActionWorker(mailbox: h.mailbox, capabilities: { AudioOutputCapabilities() },
            sendTrackpadShortcut: { shortcut, target, canPerform in
                #expect(target.pid == 100 && canPerform())
                outputs.withLock { $0.append(shortcut) }
                return .performed
            }, sendShortcut: { _ in Issue.record("Two-finger double used global output"); return false },
            secureInput: { false }, postingAllowed: { true })
        #expect(h.mailbox.submitTrackpad(h.runtime, gesture: .twoFingerDouble, pid: 100, at: lift + 150_000_000))
        worker.service(at: lift + 160_000_000)
        worker.service(at: lift + 170_000_000)
        #expect(outputs.withLock { $0 } == [h.runtime.shortcut(for: .twoFingerDouble)].compactMap { $0 })
    }

    @Test func spoofedTwoFingerShortcutAndQuartzTriggerCannotDispatch() throws {
        let h = try Harness(singles: [], doubles: [], twoFingerDouble: true)
        var spoofed = h.runtime
        spoofed.twoFingerDoubleShortcut = .init(keyCode: 0, modifiers: .command)
        #expect(h.mailbox.submitTrackpad(spoofed, gesture: .twoFingerDouble, pid: 100, at: lift) == false)
        var stale = h.runtime
        stale.doubleTapIntervalNanoseconds &+= 1
        #expect(h.mailbox.submitTrackpad(stale, gesture: .twoFingerDouble, pid: 100, at: lift) == false)
        #expect(h.mailbox.handle(InputEvent(trigger: .twoFingerDoubleTap, phase: .down), secureInput: false) == false)
        #expect(h.mailbox.nextAction() == nil)
    }

    @Test func disabledTwoFingerDoubleRuleProducesNoOutputAndKeepsOtherRulesWorking() throws {
        var h = try Harness(singles: [], doubles: [], twoFingerDouble: true)
        let shortcut = try #require(h.runtime.twoFingerDoubleShortcut)
        var disabled = rebind.Binding(scope: .builtInTrackpad, trigger: .twoFingerDoubleTap, modifiers: [],
                                      action: .shortcut(shortcut))
        disabled.isEnabled = false
        let single = rebind.Binding(scope: .builtInTrackpad, trigger: .threeFingerTap, modifiers: [],
                                    action: .shortcut(shortcut))
        let config = Configuration(isEnabled: true, bindings: [single, disabled])
        try config.validate()
        h.mailbox.configure(config)
        h.runtime = try #require(h.mailbox.trackpadRuntime())
        h.session.update(runtime: h.runtime, foreground: 100)
        h.consume(fingers: 0, at: lift - 60_000_000)
        h.tapTwoFinger(endingAt: lift)
        h.tapTwoFinger(endingAt: lift + 90_000_000)
        #expect(h.ready(at: lift + 150_000_000) == nil)
        #expect(h.mailbox.submitTrackpad(h.runtime, gesture: .twoFingerDouble, pid: 100, at: lift) == false)
        h.tap(.threeFinger, endingAt: lift + 400_000_000)
        #expect(h.ready(at: lift + 460_000_000) == .single(.threeFinger))
    }
}
