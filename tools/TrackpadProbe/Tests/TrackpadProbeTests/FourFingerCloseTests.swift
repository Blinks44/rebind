import CoreGraphics
import Testing
@testable import TrackpadProbe

struct FourFingerCloseTests {
    private let lift: UInt64 = 4_000_000_000

    private func completedStroke(_ gate: inout FourFingerCloseGate, at time: UInt64, buttons: Int = 0) {
        gate.contacts(0, at: time - 200_000_000, buttons: buttons, observerReady: true)
        gate.contacts(4, at: time - 100_000_000, buttons: buttons, observerReady: true)
        gate.contacts(0, at: time, buttons: buttons, observerReady: true)
    }

    private func armedGate() -> FourFingerCloseGate {
        var gate = FourFingerCloseGate(startedAt: 0)
        completedStroke(&gate, at: lift)
        let result1 = gate.candidate(fingers: 4, at: lift, buttons: 0, observerReady: true)
        #expect(result1)
        return gate
    }

    @Test func postingRequiresOnlyTheExplicitTestMode() throws {
        for arguments in [[], ["--check"], ["--help"], ["--capture"], ["--capture-default"], ["--capture-clicks-default"]] {
            #expect(try !ProbeOptions(arguments: arguments).postsTestShortcut)
        }
        let options = try ProbeOptions(arguments: ["--test-four-finger-close"])
        #expect(options == .testFourFingerClose(seconds: 20))
        #expect(options.postsTestShortcut && options.observesButtons)
        #expect(try ProbeOptions(arguments: ["--test-four-finger-close", "--seconds", "30"]) == .testFourFingerClose(seconds: 30))
        for seconds in ["0", "31", "-1", "0.5"] {
            #expect(throws: ProbeOptions.InvalidArguments.self) {
                try ProbeOptions(arguments: ["--test-four-finger-close", "--seconds", seconds])
            }
        }
        #expect(throws: ProbeOptions.InvalidArguments.self) {
            try ProbeOptions(arguments: ["--capture-default", "--test-four-finger-close"])
        }
    }

    @Test func outputWaitsForSettlingAndIsConsumedOnceEvenAfterCancellation() {
        var gate = armedGate()
        let result2 = gate.takeReady(at: lift + 499_999_999, buttons: 0, observerReady: true)
        #expect(!result2)
        let result3 = gate.takeReady(at: lift + 500_000_000, buttons: 0, observerReady: true)
        #expect(result3)
        #expect(gate.consumed)
        gate.cancel()
        completedStroke(&gate, at: lift + 1_000_000_000)
        let result4 = gate.candidate(fingers: 4, at: lift + 1_000_000_000, buttons: 0, observerReady: true)
        #expect(!result4)
        let result5 = gate.takeReady(at: lift + 1_500_000_000, buttons: 0, observerReady: true)
        #expect(!result5)
    }

    @Test func startingMidContactCannotArm() {
        var gate = FourFingerCloseGate(startedAt: 0)
        gate.contacts(4, at: lift - 100_000_000, buttons: 0, observerReady: true)
        gate.contacts(0, at: lift, buttons: 0, observerReady: true)
        let result6 = gate.candidate(fingers: 4, at: lift, buttons: 0, observerReady: true)
        #expect(!result6)
    }

    @Test func aReportedCandidateWithoutAnObservedCompleteStrokeCannotArm() {
        var gate = FourFingerCloseGate(startedAt: 0)
        gate.contacts(0, at: lift, buttons: 0, observerReady: true)
        let result7 = gate.candidate(fingers: 4, at: lift, buttons: 0, observerReady: true)
        #expect(!result7)
    }

    @Test func threeFingerCandidateNeverArmsAndDoesNotPreventTheNextFourFingerStroke() {
        var gate = FourFingerCloseGate(startedAt: 0)
        completedStroke(&gate, at: lift)
        let result8 = gate.candidate(fingers: 3, at: lift, buttons: 0, observerReady: true)
        #expect(!result8)
        let result9 = gate.takeReady(at: lift + 500_000_000, buttons: 0, observerReady: true)
        #expect(!result9)
        gate.contacts(4, at: lift + 1_000_000_000, buttons: 0, observerReady: true)
        gate.contacts(0, at: lift + 1_100_000_000, buttons: 0, observerReady: true)
        let result10 = gate.candidate(fingers: 4, at: lift + 1_100_000_000, buttons: 0, observerReady: true)
        #expect(result10)
    }

    @Test func theInitialArmingDelayIsMeasuredFromTestStartup() {
        var gate = FourFingerCloseGate(startedAt: 1_000_000_000)
        completedStroke(&gate, at: lift - 1)
        let result11 = gate.candidate(fingers: 4, at: lift - 1, buttons: 0, observerReady: true)
        #expect(!result11)
        completedStroke(&gate, at: lift + 200_000_000)
        let result12 = gate.candidate(fingers: 4, at: lift + 200_000_000, buttons: 0, observerReady: true)
        #expect(result12)
    }

    @Test func aButtonDuringContactInvalidatesTheStrokeEvenIfReleasedBeforeLift() {
        var gate = FourFingerCloseGate(startedAt: 0)
        gate.contacts(0, at: lift - 200_000_000, buttons: 0, observerReady: true)
        gate.contacts(4, at: lift - 100_000_000, buttons: 0, observerReady: true)
        gate.contacts(4, at: lift - 50_000_000, buttons: 1, observerReady: true)
        gate.contacts(0, at: lift, buttons: 2, observerReady: true)
        let result13 = gate.candidate(fingers: 4, at: lift, buttons: 2, observerReady: true)
        #expect(!result13)
    }

    @Test func theObservedTwelveMillisecondPostLiftButtonCancelsPendingOutput() {
        var gate = armedGate()
        let result14 = gate.takeReady(at: lift + 12_000_000, buttons: 1, observerReady: true)
        #expect(!result14)
        #expect(!gate.hasPending)
        let result15 = gate.takeReady(at: lift + 500_000_000, buttons: 2, observerReady: true)
        #expect(!result15)
        #expect(!gate.consumed)
    }

    @Test func aNewContactCancelsPendingOutput() {
        var gate = armedGate()
        gate.contacts(1, at: lift + 50_000_000, buttons: 0, observerReady: true)
        let result16 = gate.takeReady(at: lift + 500_000_000, buttons: 0, observerReady: true)
        #expect(!result16)
    }

    @Test func lossOfObservationCancelsWithoutRecoveryPosting() {
        var gate = armedGate()
        let result17 = gate.takeReady(at: lift + 100_000_000, buttons: 0, observerReady: false)
        #expect(!result17)
        let result18 = gate.takeReady(at: lift + 500_000_000, buttons: 0, observerReady: true)
        #expect(!result18)
    }

    @Test(arguments: [nil, -1, 17]) func unknownOrInvalidContactCountCancels(count: Int?) {
        var gate = armedGate()
        gate.contacts(count, at: lift + 50_000_000, buttons: 0, observerReady: true)
        let result19 = gate.takeReady(at: lift + 500_000_000, buttons: 0, observerReady: true)
        #expect(!result19)
    }

    @Test func explicitCancellationCanEstablishNeutralForAFreshStroke() {
        var gate = armedGate()
        gate.cancel(isNeutral: true)
        let result20 = gate.takeReady(at: lift + 500_000_000, buttons: 0, observerReady: true)
        #expect(!result20)
        gate.contacts(4, at: lift + 1_000_000_000, buttons: 0, observerReady: true)
        gate.contacts(0, at: lift + 1_100_000_000, buttons: 0, observerReady: true)
        let result21 = gate.candidate(fingers: 4, at: lift + 1_100_000_000, buttons: 0, observerReady: true)
        #expect(result21)
    }

    @Test func emptyFramesAfterQualifiedReleasePreservePendingAction() {
        var gate = armedGate()
        for offset in stride(from: UInt64(10_000_000), to: 500_000_000, by: 10_000_000) {
            gate.emptyFrame(at: lift + offset, buttons: 0, observerReady: true)
            let early = gate.takeReady(at: lift + offset, buttons: 0, observerReady: true)
            #expect(!early && gate.hasPending)
        }
        let ready = gate.takeReady(at: lift + 500_000_000, buttons: 0, observerReady: true)
        #expect(ready && gate.consumed)
        let cancellation = gate.takeCancellation()
        #expect(cancellation == nil)
    }

    @Test func emptyFrameCannotCompleteAnUnqualifiedActiveStroke() {
        var gate = FourFingerCloseGate(startedAt: 0)
        gate.contacts(0, at: lift - 200_000_000, buttons: 0, observerReady: true)
        gate.contacts(4, at: lift - 100_000_000, buttons: 0, observerReady: true)
        gate.emptyFrame(at: lift, buttons: 0, observerReady: true)
        let armed = gate.candidate(fingers: 4, at: lift, buttons: 0, observerReady: true)
        #expect(!armed && gate.rejection == .noCompleteStroke)
    }

    @Test func emptyFrameDoesNotHideADelayedButton() {
        var gate = armedGate()
        gate.emptyFrame(at: lift + 12_000_000, buttons: 1, observerReady: true)
        let ready = gate.takeReady(at: lift + 500_000_000, buttons: 2, observerReady: true)
        #expect(!ready && !gate.hasPending)
        let reason = gate.takeCancellation()
        #expect(reason == .buttonEvent)
        let cleared = gate.takeCancellation()
        #expect(cleared == nil)
    }

    @Test func emptyFrameDoesNotHideFailedObservation() {
        var gate = armedGate()
        gate.emptyFrame(at: lift + 50_000_000, buttons: 0, observerReady: false)
        let ready = gate.takeReady(at: lift + 500_000_000, buttons: 0, observerReady: true)
        #expect(!ready)
        let reason = gate.takeCancellation()
        #expect(reason == .observerUnavailable)
    }

    @Test func frameGapStillCancelsAfterEmptyNeutralFrame() {
        var gate = armedGate()
        gate.emptyFrame(at: lift + 50_000_000, buttons: 0, observerReady: true)
        gate.cancel(reason: .frameGap)
        let ready = gate.takeReady(at: lift + 500_000_000, buttons: 0, observerReady: true)
        #expect(!ready)
        let reason = gate.takeCancellation()
        #expect(reason == .frameGap)
    }

    @Test func newContactAfterEmptyNeutralFrameStillCancels() {
        var gate = armedGate()
        gate.emptyFrame(at: lift + 50_000_000, buttons: 0, observerReady: true)
        gate.contacts(1, at: lift + 100_000_000, buttons: 0, observerReady: true)
        let ready = gate.takeReady(at: lift + 500_000_000, buttons: 0, observerReady: true)
        #expect(!ready)
        let reason = gate.takeCancellation()
        #expect(reason == .newContact)
    }

    @Test func completedRecognizerReleaseSurvivesTheUpstreamEmptyTail() throws {
        var recognizer = ShortContactRecognizer()
        var gate = FourFingerCloseGate(startedAt: 0)
        let neutral = recognizer.consume(frame: 0, time: 0, contacts: [])
        #expect(neutral == nil)
        gate.emptyFrame(at: 3_000_000_000, buttons: 2, observerReady: true)
        let contacts = (1...4).map {
            ShortContactRecognizer.Contact(id: Int32($0), x: 0.5, y: 0.5, pressure: 30)
        }
        for frame in 1...20 {
            let time = 4 + Double(frame) * 0.008
            let receipt = lift + UInt64(frame) * 8_000_000
            gate.contacts(4, at: receipt, buttons: 2, observerReady: true)
            let candidate = recognizer.consume(frame: Int32(frame), time: time, contacts: contacts)
            #expect(candidate == nil)
        }
        let release = lift + 168_000_000
        gate.contacts(0, at: release, buttons: 2, observerReady: true)
        let completed = recognizer.consume(frame: 21, time: 4.168, contacts: [])
        let candidate = try #require(completed)
        let armed = gate.candidate(fingers: candidate.fingers, at: release, buttons: 2, observerReady: true)
        try #require(armed)
        recognizer.interrupt(isNeutral: true)
        gate.emptyFrame(at: release + 8_000_000, buttons: 2, observerReady: true)
        let ready = gate.takeReady(at: release + 500_000_000, buttons: 2, observerReady: true)
        #expect(ready)
    }

    @Test(arguments: [UInt64(0), 100_000_000, 100_000_001])
    func aDelayedPollDropsStaleOutput(lateness: UInt64) {
        var gate = armedGate()
        let ready = gate.takeReady(at: lift + 500_000_000 + lateness, buttons: 0, observerReady: true)
        #expect(ready == (lateness <= 100_000_000))
        #expect(!gate.hasPending)
    }

    @Test func aRegressedReceiptClockCancels() {
        var gate = armedGate()
        let result22 = gate.takeReady(at: lift - 1, buttons: 0, observerReady: true)
        #expect(!result22)
        let result23 = gate.takeReady(at: lift + 500_000_000, buttons: 0, observerReady: true)
        #expect(!result23)
    }

    @Test func nearMaximumReceiptTimeCannotOverflowTheDeadline() {
        var gate = FourFingerCloseGate(startedAt: 0)
        completedStroke(&gate, at: .max - 100)
        let result24 = gate.candidate(fingers: 4, at: .max - 100, buttons: 0, observerReady: true)
        #expect(!result24)
        let result25 = gate.takeReady(at: .max, buttons: 0, observerReady: true)
        #expect(!result25)
    }

    @Test @MainActor func preparedShortcutIsBalancedPlainCommandWAndTaggedWithoutPosting() throws {
        let events = try #require(FourFingerCloseSender.events())
        #expect(events.count == 2)
        #expect(events.map(\.type) == [.keyDown, .keyUp])
        for event in events {
            #expect(event.getIntegerValueField(.keyboardEventKeycode) == 13)
            #expect(event.flags == .maskCommand)
            #expect(event.getIntegerValueField(.eventSourceUserData) == PassiveButtonProbe.rebindTag)
        }
    }
}
