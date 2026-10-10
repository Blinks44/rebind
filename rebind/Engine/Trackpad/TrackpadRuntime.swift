import Synchronization
import Foundation

nonisolated enum TrackpadCaptureStatus: Sendable {
    case idle, active, unavailable, failed
}

nonisolated struct TrackpadDispatchTarget: Equatable, Sendable {
    var pid: Int32
    var inputActivity: UInt64
    var expiresAt: UInt64
}

nonisolated struct TrackpadRuntime: Equatable, Sendable {
    var revision: UInt64
    var inputActivity: UInt64
    var shortcut: KeyboardShortcut
}

extension EngineMailbox {
    nonisolated func trackpadRuntime() -> TrackpadRuntime? {
        state.withLock {
            let key = MatchKey(trigger: .fourFingerTap, modifiers: [])
            guard $0.status == .active, $0.enabled, !$0.editing, !$0.suspended, !$0.stopped,
                  $0.recording == nil, let shortcut = $0.rules[key]?.action.shortcut else { return nil }
            return TrackpadRuntime(revision: $0.actionRevision, inputActivity: $0.inputActivity, shortcut: shortcut)
        }
    }

    nonisolated func updateTrackpadForeground(_ pid: Int32?) {
        state.withLock {
            guard $0.foregroundPID != pid else { return }
            $0.foregroundPID = pid
            $0.trackpadDispatch = nil
        }
    }

    // One extra bounded slot, never a delayed backlog of touch actions. Existing
    // keyboard/mouse dispatch remains unchanged. Focus/activity gates are rechecked
    // by the serial action worker before posting directly to the captured PID.
    @discardableResult nonisolated func submitTrackpad(_ runtime: TrackpadRuntime, pid: Int32, at now: UInt64) -> Bool {
        state.withLock {
            guard now <= UInt64.max - 100_000_000, $0.pending.isEmpty,
                  $0.workspaceRequest == nil, $0.trackpadDispatch == nil,
                  $0.actionRevision == runtime.revision, $0.inputActivity == runtime.inputActivity,
                  $0.foregroundPID == pid else { return false }
            let dispatch = ActionDispatch(action: .shortcut(runtime.shortcut), revision: runtime.revision,
                trackpadTarget: TrackpadDispatchTarget(pid: pid, inputActivity: runtime.inputActivity,
                                                      expiresAt: now + 100_000_000))
            guard $0.dispatchIsCurrent(dispatch) else { return false }
            $0.trackpadDispatch = dispatch
            return true
        }
    }
}
