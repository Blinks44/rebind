import Foundation
import Dispatch
import Synchronization

// Developer-only opt-in aggregate report. No contacts, coordinates, IDs,
// keyboard codes, text, application identity or user rules enter this type.
nonisolated struct TrackpadDiagnostics: Sendable {
    static let duration: UInt64 = 60_000_000_000
    let startedAt: UInt64
    private(set) var counts: [String: UInt64] = [:]

    mutating func record(_ event: TrackpadDiagnosticEvent, at now: UInt64) {
        guard now >= startedAt, now - startedAt < Self.duration else { return }
        counts[event.key, default: 0] &+= 1
    }

    func report() -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard let data = try? encoder.encode(counts) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

nonisolated enum TrackpadDiagnosticEvent: Sendable {
    case frame, candidate, queued, queueUnavailable, outputPosted, outputCancelled, outputUnavailable, outputExpired
    case captureInactive, captureRestarted, captureUnavailable, captureFailed, runtimeChanged
    case heldModifier, heldButton, heldKey, protectedContext, targetChanged, activityChanged, outputTargetInactive
    case invalidFrame, obsoleteFrame, staleFrame, futureReceipt, overflow
    case recognition(ShortContactRecognizer.Rejection)
    case gate(FourFingerTapGate.Reason)

    var key: String {
        switch self {
        case .frame: "frames"
        case .candidate: "qualified-taps"
        case .queued: "queued"
        case .queueUnavailable: "queue-unavailable"
        case .outputPosted: "output-posted"
        case .outputCancelled: "output-cancelled"
        case .outputUnavailable: "output-unavailable"
        case .outputExpired: "output-expired"
        case .captureInactive: "capture-inactive-polls"
        case .captureRestarted: "capture-starts"
        case .captureUnavailable: "capture-unavailable"
        case .captureFailed: "capture-failed"
        case .runtimeChanged: "output-runtime-changed"
        case .heldModifier: "output-held-modifier"
        case .heldButton: "output-held-button"
        case .heldKey: "output-held-key"
        case .protectedContext: "output-protected-context"
        case .targetChanged: "foreground-changed"
        case .outputTargetInactive: "output-target-inactive"
        case .activityChanged: "input-activity-changed"
        case .invalidFrame: "invalid-frame"
        case .obsoleteFrame: "obsolete-frame"
        case .staleFrame: "stale-frame"
        case .futureReceipt: "future-receipt"
        case .overflow: "buffer-overflow"
        case .recognition(let reason): "recognition-" + reason.rawValue
        case .gate(let reason): "gate-" + reason.rawValue
        }
    }
}

extension EngineMailbox {
    nonisolated func recordTrackpadDiagnostic(_ event: TrackpadDiagnosticEvent) {
        state.withLock { $0.trackpadDiagnostics?.record(event, at: DispatchTime.now().uptimeNanoseconds) }
    }

    nonisolated func takeTrackpadDiagnosticReport(at now: UInt64, finishing: Bool = false) -> String? {
        let diagnostics: TrackpadDiagnostics? = state.withLock {
            guard let diagnostics = $0.trackpadDiagnostics,
                  finishing || now < diagnostics.startedAt || now - diagnostics.startedAt >= TrackpadDiagnostics.duration else { return nil }
            $0.trackpadDiagnostics = nil
            return diagnostics
        }
        // Serialize after releasing the lock shared with the input callback.
        return diagnostics?.report()
    }
}
