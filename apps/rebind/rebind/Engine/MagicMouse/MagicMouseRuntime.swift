import Synchronization
import Foundation

/// Only the current profile/app/modifier rules are admitted to mouse touch recognition.
nonisolated struct MagicMouseRuntime: Equatable, Sendable {
    var revision: UInt64
    var activity: UInt64
    var modifiers: ModifierSet = []
    var buttonsDown = false
    /// Keyed by `magicMouseTap` and `magicMouseSideTap` triggers.
    var actions: [InputTrigger: RebindAction] = [:]

    /// A side rule wins on its half; elsewhere, or without one, the ordinary tap applies.
    func trigger(fingers: Int, x: Float?) -> InputTrigger? {
        if fingers == 1, let side = x.flatMap(MagicMouseSide.containing),
           actions[.magicMouseSideTap(side)] != nil { return .magicMouseSideTap(side) }
        let tap = InputTrigger.magicMouseTap(fingers: fingers)
        return actions[tap] == nil ? nil : tap
    }

    static let tapTriggers: [InputTrigger] = (1...3).map { .magicMouseTap(fingers: $0) }
        + MagicMouseSide.allCases.map { .magicMouseSideTap($0) }
}

extension EngineMailbox {
    nonisolated func magicMouseRuntime(modifiers: ModifierSet = [], buttonsDown: Bool = false) -> MagicMouseRuntime? {
        state.withLock {
            guard $0.canDispatch, $0.hasMagicMouseRules else { return nil }
            var actions: [InputTrigger: RebindAction] = [:]
            for trigger in MagicMouseRuntime.tapTriggers {
                actions[trigger] = $0.rules[MatchKey(trigger: trigger, modifiers: modifiers)]?.action
            }
            return MagicMouseRuntime(revision: $0.actionRevision, activity: $0.magicMouseActivity,
                                     modifiers: modifiers, buttonsDown: buttonsDown, actions: actions)
        }
    }

    @discardableResult nonisolated func submitMagicMouse(_ runtime: MagicMouseRuntime, trigger: InputTrigger,
                                                        pid: Int32, at now: UInt64) -> Bool {
        let queued = state.withLock {
            guard !runtime.buttonsDown, MagicMouseRuntime.tapTriggers.contains(trigger), now <= UInt64.max - 100_000_000,
                  $0.pending.isEmpty, $0.workspaceRequest == nil, $0.trackpadDispatch == nil,
                  $0.actionRevision == runtime.revision, $0.magicMouseActivity == runtime.activity,
                  $0.foregroundPID == pid, let action = runtime.actions[trigger],
                  $0.rules[MatchKey(trigger: trigger, modifiers: runtime.modifiers)]?.action == action
            else { return false }
            let target = TrackpadDispatchTarget(pid: pid, inputActivity: runtime.activity,
                expiresAt: now + 100_000_000, queuedAt: now, modifiers: runtime.modifiers, isMagicMouse: true)
            let dispatch = ActionDispatch(action: action, revision: runtime.revision,
                                          deviceID: $0.audioCapabilities.deviceID(for: action), trackpadTarget: target)
            guard $0.dispatchIsCurrent(dispatch) else { return false }
            $0.trackpadDispatch = dispatch
            return true
        }
        if queued { signalWork() }
        return queued
    }
}
