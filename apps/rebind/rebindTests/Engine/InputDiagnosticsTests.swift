import Testing
@testable import rebind

struct InputDiagnosticsTests {
    private func append(_ buffer: inout InputDiagnostics, at time: UInt64) {
        buffer.append(kind: .button(3), phase: .down, modifiers: .control, outcome: .passedThrough, at: time)
    }

    @Test func collectionIsOptInAndStopRetainsRowsUntilClear() {
        var buffer = InputDiagnostics()
        append(&buffer, at: 0)
        #expect(buffer.snapshot().entries.isEmpty)
        buffer.start(at: 100_000_000)
        append(&buffer, at: 120_000_000)
        buffer.stop()
        append(&buffer, at: 130_000_000)
        let snapshot = buffer.snapshot()
        #expect(snapshot.isRunning == false)
        #expect(snapshot.entries.count == 1)
        #expect(snapshot.entries.first?.elapsedMilliseconds == 20)
        buffer.clear()
        #expect(buffer.snapshot().entries.isEmpty)
    }

    @Test func fixedStorageRetainsNewestEntriesInChronologicalOrder() {
        var buffer = InputDiagnostics()
        buffer.start(at: 0)
        for index in 0..<200 { append(&buffer, at: UInt64(index) * 50_000_000) }
        let snapshot = buffer.snapshot()
        #expect(snapshot.entries.count == 128)
        #expect(snapshot.entries.first?.id == 73)
        #expect(snapshot.entries.last?.id == 200)
        #expect(snapshot.entries.first?.elapsedMilliseconds == 3600)
        #expect(snapshot.omitted == 72)
        #expect(Set(snapshot.entries.map(\.id)).count == snapshot.entries.count)
    }

    @Test func burstLimitDoesNotDelayOrAccumulateRows() {
        var buffer = InputDiagnostics()
        buffer.start(at: 0)
        for _ in 0..<1000 { append(&buffer, at: 1) }
        #expect(buffer.snapshot().entries.count == 20)
        #expect(buffer.snapshot().omitted == 980)
        append(&buffer, at: 999_999_999)
        #expect(buffer.snapshot().entries.count == 20)
        append(&buffer, at: 1_000_000_000)
        #expect(buffer.snapshot().entries.count == 21)
    }

    @Test func expiryOccursAtDeadlineWithoutAnotherInputAndDoesNotWrap() {
        var buffer = InputDiagnostics()
        buffer.start(at: 0)
        append(&buffer, at: 1)
        buffer.expire(at: InputDiagnostics.sessionDuration - 1)
        #expect(buffer.isRunning)
        buffer.expire(at: InputDiagnostics.sessionDuration)
        #expect(buffer.isRunning == false)
        append(&buffer, at: InputDiagnostics.sessionDuration + 1)
        #expect(buffer.snapshot().entries.count == 1)
        buffer.start(at: UInt64.max - 10)
        append(&buffer, at: UInt64.max)
        #expect(buffer.snapshot().entries.count == 1)
        buffer.expire(at: 0)
        #expect(buffer.isRunning == false)
        #expect(buffer.snapshot().entries.isEmpty)
    }

    @Test func regressedReceiptTimeStopsAndErasesSession() {
        var buffer = InputDiagnostics()
        buffer.start(at: 100)
        append(&buffer, at: 200)
        append(&buffer, at: 199)
        #expect(buffer.isRunning == false)
        #expect(buffer.snapshot().entries.isEmpty)
    }

    @Test func clearDoesNotExtendSessionOrResetBurstAllowance() {
        var buffer = InputDiagnostics()
        buffer.start(at: 0)
        for _ in 0..<20 { append(&buffer, at: 1) }
        buffer.clear()
        append(&buffer, at: 2)
        #expect(buffer.snapshot().entries.isEmpty)
        #expect(buffer.snapshot().omitted == 1)
        buffer.expire(at: InputDiagnostics.sessionDuration)
        #expect(buffer.isRunning == false)
        buffer.start(at: InputDiagnostics.sessionDuration + 1)
        append(&buffer, at: InputDiagnostics.sessionDuration + 2)
        #expect(buffer.snapshot().omitted == 0)
        #expect(buffer.snapshot().entries.count == 1)
    }

    @Test func keyboardFeedbackAndMissingReceiptNeverEnterTheLogOrConsumeQuota() {
        var buffer = InputDiagnostics()
        buffer.start(at: 0)
        for code in UInt16(0)..<128 {
            buffer.record(InputEvent(trigger: .key(code), phase: .down, receivedAt: 1), suppressed: true, queued: true)
        }
        buffer.record(InputEvent(trigger: .mouseButton(3), phase: .down, isSynthetic: true, receivedAt: 1), suppressed: true, queued: true)
        buffer.record(InputEvent(trigger: .mouseButton(3), phase: .down), suppressed: false, queued: false)
        #expect(buffer.snapshot().entries.isEmpty)
        #expect(buffer.snapshot().omitted == 0)
        append(&buffer, at: 1)
        #expect(buffer.snapshot().entries.count == 1)
    }

    @Test func snapshotRemainsIndependentWhenCallbackOverwritesStorage() {
        var buffer = InputDiagnostics()
        buffer.start(at: 0)
        append(&buffer, at: 1)
        let snapshot = buffer.snapshot()
        for index in 1...200 { append(&buffer, at: UInt64(index) * 50_000_000) }
        #expect(snapshot.entries.count == 1)
        #expect(snapshot.entries.first?.id == 1)
        #expect(buffer.snapshot().entries.first?.id != snapshot.entries.first?.id)
    }
}
