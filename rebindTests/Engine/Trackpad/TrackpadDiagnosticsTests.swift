import Testing
import Synchronization
@testable import rebind

struct TrackpadDiagnosticsTests {
    @Test func timingSamplesHaveFixedCardinalityAndShareOptInLifetime() throws {
        var diagnostics = TrackpadDiagnostics(startedAt: 1_000)
        let durations: [UInt64] = [0, 10_000_000, 10_000_001, 20_000_000, 20_000_001,
                                  60_000_000, 60_000_001, 100_000_000, 100_000_001,
                                  160_000_000, 160_000_001, UInt64.max]
        for duration in durations {
            diagnostics.record(.frameAge(nanoseconds: duration), at: 1_000)
            diagnostics.record(.postedQueueAge(nanoseconds: duration), at: 1_000)
        }
        diagnostics.record(.frameAge(nanoseconds: 0), at: 999)
        diagnostics.record(.postedQueueAge(nanoseconds: 0), at: 1_000 + TrackpadDiagnostics.duration)
        #expect(diagnostics.counts.count == 12)
        for prefix in ["frame-age-", "posted-queue-age-"] {
            for bucket in ["le-10ms", "le-20ms", "le-60ms", "le-100ms", "le-160ms", "gt-160ms"] {
                #expect(diagnostics.counts[prefix + bucket] == 2)
            }
        }
        let report = try #require(diagnostics.report())
        #expect(report.contains("18446744073709551615") == false)
    }

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
