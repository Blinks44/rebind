import Synchronization
import Foundation
import Testing
@testable import rebind

struct MagicMouseNativeTests {
    private let now: UInt64 = 4_000_000_000

    private func frame(_ count: Int, at time: UInt64, revision: UInt64 = 0) -> NativeTrackpadFrame {
        NativeTrackpadFrame(receipt: time, revision: revision, activity: 0, count: count)
    }

    private func filter(count: Int = 3) -> MagicMouseNativeFilter {
        var filter = MagicMouseNativeFilter()
        filter.begin(sources: [42], at: 0)
        filter.observe(frame(count, at: now))
        return filter
    }

    @Test(arguments: [UInt32(0), 1])
    func physicalClickOwnsOnlyItsSourceAndPairedRelease(_ button: UInt32) {
        var f = filter()
        var actions = 0
        let firstDownConsumed = f.click(sender: 42, button: button, phase: .down, revision: 0, at: now) { actions += 1; return true }
        #expect(firstDownConsumed)
        let repeatedDownConsumed = f.click(sender: 42, button: button, phase: .down, revision: 0, at: now) { actions += 1; return true }
        #expect(repeatedDownConsumed)
        #expect(actions == 1)
        f.invalidateContacts()
        let otherReleasePassed = f.click(sender: 99, button: button, phase: .up, revision: 9, at: now + 1, admit: { false }) == false
        #expect(otherReleasePassed)
        let dragConsumed = f.click(sender: 42, button: button, phase: .drag, revision: 9, at: now + 1, admit: { false })
        #expect(dragConsumed)
        let releaseConsumed = f.click(sender: 42, button: button, phase: .up, revision: 9, at: now + 2, admit: { false })
        #expect(releaseConsumed)
        #expect(f.hasOwnedInput == false)
        let unmatchedReleasePassed = f.click(sender: 42, button: button, phase: .up, revision: 9, at: now + 3, admit: { false }) == false
        #expect(unmatchedReleasePassed)
    }

    @Test(arguments: 0...7)
    func uncertainOrInactiveClickPassesItsWholePair(_ cause: Int) {
        var f = filter(count: cause < 3 ? cause : 3)
        let sender: UInt64? = cause == 3 ? 99 : cause == 4 ? nil : 42
        let revision: UInt64 = cause == 5 ? 1 : 0
        let time = cause == 6 ? now + 100_000_001 : now
        let downPassed = f.click(sender: sender, button: 0, phase: .down, revision: revision, at: time, admit: { cause != 7 }) == false
        #expect(downPassed)
        let upPassed = f.click(sender: sender, button: 0, phase: .up, revision: revision, at: time + 1, admit: { true }) == false
        #expect(upPassed)
    }

    @Test func replacementConnectionDoesNotInheritOldPressOwnership() {
        var f = filter()
        let downConsumed = f.click(sender: 42, button: 0, phase: .down, revision: 0, at: now, admit: { true })
        #expect(downConsumed)
        f.begin(sources: [77], at: now)
        #expect(f.hasOwnedInput == false)
        let reconnectTime = now + 4_000_000_000
        f.observe(frame(3, at: reconnectTime))
        let newDownConsumed = f.click(sender: 77, button: 0, phase: .down, revision: 0, at: reconnectTime, admit: { true })
        #expect(newDownConsumed)
    }

    @Test func captureArmingAndInvalidFramesDoNotAttributeClicks() {
        var f = filter()
        f.begin(sources: [42], at: now)
        f.observe(frame(3, at: now))
        let armingPassed = f.click(sender: 42, button: 0, phase: .down, revision: 0, at: now, admit: { true }) == false
        #expect(armingPassed)
        var bad = frame(3, at: now + 4_000_000_000); bad.valid = false
        f.observe(bad)
        let invalidFramePassed = f.click(sender: 42, button: 0, phase: .down, revision: 0, at: bad.receipt, admit: { true }) == false
        #expect(invalidFramePassed)
    }

    @Test(arguments: [ScrollDirection.up, .down])
    func scrollRunsOnceAndOwnsItsMomentumAfterContactAndRuleLoss(_ direction: ScrollDirection) {
        var f = filter(count: 2)
        var actions = 0
        let beginConsumed = f.scroll(sender: 42, phase: 1, momentum: 0, direction: direction, revision: 0, at: now) { value in
            #expect(value == direction); actions += 1; return true
        }
        #expect(beginConsumed)
        let repeatBeginConsumed = f.scroll(sender: 42, phase: 1, momentum: 0, direction: direction, revision: 0, at: now + 1) { _ in actions += 1; return true }
        #expect(repeatBeginConsumed)
        #expect(actions == 1)
        let otherDevicePassed = f.scroll(sender: 99, phase: 1, momentum: 0, direction: direction, revision: 0, at: now + 2, admit: { _ in true }) == false
        #expect(otherDevicePassed)
        f.invalidateContacts()
        for (phase, momentum) in [(Int64(2), Int64(0)), (4, 0), (0, 1), (0, 2), (0, 3)] {
            let tailConsumed = f.scroll(sender: 42, phase: phase, momentum: momentum, direction: nil, revision: 99,
                             at: now + 3, admit: { _ in false })
            #expect(tailConsumed)
        }
        #expect(f.hasOwnedInput == false)
    }

    @Test(arguments: [0, 1, 3, 4])
    func ambiguousScrollNeverGetsTakenOverMidstream(_ count: Int) {
        var f = filter(count: count)
        let beginPassed = f.scroll(sender: 42, phase: 1, momentum: 0, direction: .up, revision: 0, at: now, admit: { _ in true }) == false
        #expect(beginPassed)
        f.observe(frame(2, at: now + 1))
        for phase: Int64 in [2, 4] {
            let tailPassed = f.scroll(sender: 42, phase: phase, momentum: 0, direction: .up, revision: 0, at: now + 2, admit: { _ in true }) == false
            #expect(tailPassed)
        }
        let momentumPassed = f.scroll(sender: 42, phase: 0, momentum: 1, direction: .up, revision: 0, at: now + 2, admit: { _ in true }) == false
        #expect(momentumPassed)
    }

    @Test func ambiguousBeganCannotBeReclassifiedWithinTheSameContactStroke() {
        var f = filter(count: 1)
        let ambiguousBeginPassed = f.scroll(sender: 42, phase: 1, momentum: 0, direction: .up, revision: 0, at: now, admit: { _ in true }) == false
        #expect(ambiguousBeginPassed)
        f.observe(frame(2, at: now + 1))
        let laterBeginPassed = f.scroll(sender: 42, phase: 1, momentum: 0, direction: .up, revision: 0, at: now + 2, admit: { _ in true }) == false
        #expect(laterBeginPassed)
    }

    @Test func unassignedDirectionsAndHorizontalStartsRemainNative() {
        var f = filter(count: 2)
        let horizontalPassed = f.scroll(sender: 42, phase: 1, momentum: 0, direction: nil, revision: 0, at: now, admit: { _ in true }) == false
        #expect(horizontalPassed)
        let unassignedPassed = f.scroll(sender: 42, phase: 1, momentum: 0, direction: .down, revision: 0, at: now, admit: { $0 == .up }) == false
        #expect(unassignedPassed)
        let changedPassed = f.scroll(sender: 42, phase: 2, momentum: 0, direction: .up, revision: 0, at: now, admit: { _ in true }) == false
        #expect(changedPassed)
    }

    @Test func completedStrokeNeedsNewContactAndDormantOwnershipExpires() {
        var f = filter(count: 2)
        let beginConsumed = f.scroll(sender: 42, phase: 1, momentum: 0, direction: .up, revision: 0, at: now, admit: { _ in true })
        #expect(beginConsumed)
        f.expireScroll(at: now + 1_000_000_001)
        #expect(f.hasOwnedInput == false)
        f.observe(frame(2, at: now + 2_000_000_000))
        let sameStrokeConsumed = f.scroll(sender: 42, phase: 1, momentum: 0, direction: .up, revision: 0, at: now + 2_000_000_000, admit: { _ in Issue.record("Same contact stroke fired twice"); return false })
        #expect(sameStrokeConsumed)
        f.observe(frame(0, at: now + 2_000_000_001))
        f.observe(frame(2, at: now + 2_000_000_002))
        let nextStrokeConsumed = f.scroll(sender: 42, phase: 1, momentum: 0, direction: .down, revision: 0, at: now + 2_000_000_002, admit: { _ in true })
        #expect(nextStrokeConsumed)
    }

    @Test func fingerDirectionIsIndependentOfNaturalScrolling() {
        #expect(EventTapWorker.fingerScrollDirection(vertical: 5, horizontal: 0, inverted: false) == .up)
        #expect(EventTapWorker.fingerScrollDirection(vertical: -5, horizontal: 0, inverted: true) == .up)
        #expect(EventTapWorker.fingerScrollDirection(vertical: -5, horizontal: 0, inverted: false) == .down)
        #expect(EventTapWorker.fingerScrollDirection(vertical: 5, horizontal: 0, inverted: true) == .down)
        #expect(EventTapWorker.fingerScrollDirection(vertical: 1, horizontal: 2, inverted: false) == nil)
        #expect(EventTapWorker.fingerScrollDirection(vertical: .nan, horizontal: 0, inverted: false) == nil)
    }

    @Test func mailboxOwnsClickReleaseAcrossPauseWithoutDuplicatingAction() throws {
        let mailbox = EngineMailbox()
        let rule = rebind.Binding(scope: .magicMouse, trigger: .magicMouseClick(fingers: 3), modifiers: .option, action: .doNothing)
        mailbox.configure(Configuration(isEnabled: true, bindings: [rule]))
        mailbox.state.withLock {
            $0.status = .active; $0.foregroundPID = 100
            $0.magicMouseNative.begin(sources: [42], at: 0)
            $0.magicMouseNative.observe(frame(3, at: now, revision: $0.actionRevision))
        }
        let down = InputEvent(trigger: .mouseButton(0), modifiers: .option, phase: .down, receivedAt: now)
        #expect(mailbox.handle(down, secureInput: false, sender: 42))
        #expect(mailbox.handle(down, secureInput: false, sender: 42))
        let dispatch = try #require(mailbox.nextAction())
        #expect(dispatch.action == .doNothing)
        #expect(mailbox.nextAction() == nil)
        mailbox.state.withLock { $0.pause() }
        #expect(mailbox.handle(.init(trigger: .mouseButton(0), phase: .up, receivedAt: now + 1), secureInput: true, sender: 42))
    }

    @Test func mailboxQueuesOneScrollActionAndKeepsCancellationOwnership() {
        let mailbox = EngineMailbox()
        let rule = rebind.Binding(scope: .magicMouse, trigger: .magicMouseScroll(.up), modifiers: [], action: .doNothing)
        mailbox.configure(Configuration(isEnabled: true, bindings: [rule]))
        mailbox.state.withLock {
            $0.status = .active; $0.foregroundPID = 100
            $0.magicMouseNative.begin(sources: [42], at: 0)
            $0.magicMouseNative.observe(frame(2, at: now, revision: $0.actionRevision))
        }
        #expect(mailbox.handleMagicMouseScroll(sender: 42, phase: 1, momentum: 0, direction: .up, modifiers: [], at: now, secureInput: false))
        #expect(mailbox.nextAction()?.action == .doNothing)
        mailbox.setEditing(true)
        #expect(mailbox.handleMagicMouseScroll(sender: 42, phase: 2, momentum: 0, direction: .up, modifiers: [], at: now + 1, secureInput: false))
        #expect(mailbox.handleMagicMouseScroll(sender: 42, phase: 0, momentum: 3, direction: nil, modifiers: [], at: now + 2, secureInput: true))
        #expect(mailbox.nextAction() == nil)
    }
}
