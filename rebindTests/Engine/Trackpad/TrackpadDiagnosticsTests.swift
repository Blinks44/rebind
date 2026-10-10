import Testing
import Synchronization
@testable import rebind

struct TrackpadDiagnosticsTests {
    @Test func optInAggregatesOnlyFixedReasonsAndStopsAtOneMinute() throws {
        var diagnostics = TrackpadDiagnostics(startedAt: 1_000)
        diagnostics.record(.frame, at: 999)
        diagnostics.record(.frame, at: 1_000)
        diagnostics.record(.recognition(.travel), at: 2_000)
        diagnostics.record(.gate(.newContact), at: 3_000)
        diagnostics.record(.frame, at: 1_000 + TrackpadDiagnostics.duration)
        #expect(diagnostics.counts == ["frames": 1, "recognition-travel": 1, "gate-new-contact": 1])
        let report = try #require(diagnostics.report())
        #expect(report == #"{"frames":1,"gate-new-contact":1,"recognition-travel":1}"#)
    }

    @Test func reportIsOneShotAndProtectedContextClearsIt() {
        let mailbox = EngineMailbox()
        #expect(mailbox.state.withLock { $0.trackpadDiagnostics == nil })
        mailbox.state.withLock {
            $0.trackpadDiagnostics = .init(startedAt: 0)
            $0.trackpadDiagnostics?.record(.candidate, at: 1)
        }
        #expect(mailbox.takeTrackpadDiagnosticReport(at: TrackpadDiagnostics.duration - 1) == nil)
        #expect(mailbox.takeTrackpadDiagnosticReport(at: TrackpadDiagnostics.duration) == #"{"qualified-taps":1}"#)
        #expect(mailbox.takeTrackpadDiagnosticReport(at: TrackpadDiagnostics.duration) == nil)
        mailbox.state.withLock {
            $0.trackpadDiagnostics = .init(startedAt: 0)
            $0.trackpadDiagnostics?.record(.candidate, at: 1)
            $0.resetCapture(status: .secureInput)
        }
        #expect(mailbox.takeTrackpadDiagnosticReport(at: TrackpadDiagnostics.duration, finishing: true) == nil)
    }
}
