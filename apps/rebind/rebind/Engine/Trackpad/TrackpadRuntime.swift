import Synchronization
import Foundation

nonisolated enum TrackpadCaptureStatus: Sendable {
    case idle, active, unavailable, failed
}

nonisolated struct TrackpadDispatchTarget: Equatable, Sendable {
    var pid: Int32
    var inputActivity: UInt64
    var expiresAt: UInt64
    /// Monotonic mailbox admission time; transient and never serialized.
    var queuedAt: UInt64 = 0
}

nonisolated struct TrackpadRuntime: Equatable, Sendable {
    var revision: UInt64
    var inputActivity: UInt64
    /// Whether these are the Magic Trackpad's rules rather than the built-in trackpad's.
    var isMagicTrackpad = false
    /// Enabled light-tap rules of the selected profile, by complete gesture.
    var actions: [TrackpadTapGesture: RebindAction] = [:]
    /// Click rules are resolved on the event-tap path; they only need contact frames to keep flowing.
    var hasClickRules = false
    var doubleTapIntervalNanoseconds: UInt64 = 500_000_000

    var enabledGestures: Set<TrackpadTapSequence.Gesture> { Set(actions.keys.map(\.sequenceGesture)) }

    /// The only gesture identity a completed contact of this finger count and
    /// starting centroid may produce under the configured rules; nil when none
    /// is configured. A two-finger contact can never produce a single-tap output,
    /// and a one-finger contact only counts inside a configured corner.
    func admissibleGesture(fingers: Int, x: Float, y: Float) -> TrackpadTapGesture? {
        if fingers == 1 {
            return TrackpadCorner.containing(x: x, y: y).flatMap { actions[.corner($0)] == nil ? nil : .corner($0) }
        }
        if fingers == 2 { return actions[.twoFingerDouble] == nil ? nil : .twoFingerDouble }
        guard let tap = TrackpadSingleTap(rawValue: fingers) else { return nil }
        if actions[.double(tap)] != nil { return .double(tap) }
        return actions[.single(tap)] == nil ? nil : .single(tap)
    }
}

extension EngineMailbox {
    nonisolated func trackpadRuntime(magicTrackpad: Bool = false) -> TrackpadRuntime? {
        state.withLock {
            guard $0.status == .active, $0.isMatching, !$0.editing, !$0.suspended, !$0.stopped,
                  $0.recording == nil else { return nil }
            let rules = $0.rules
            let interval = $0.matcher.doublePressIntervalNanoseconds
            // An unsupported system interval disables only double recognition;
            // existing single-tap rules remain usable without a delayed backlog.
            let supportsDouble = (1...2_000_000_000).contains(interval)
            var actions: [TrackpadTapGesture: RebindAction] = [:]
            for gesture in TrackpadTapGesture.allCases where supportsDouble || !gesture.isDoubleTap {
                actions[gesture] = rules[MatchKey(trigger: gesture.trigger, modifiers: [], isMagicTrackpad: magicTrackpad)]?.action
            }
            let clicks = (2...4).contains { rules[MatchKey(trigger: .trackpadClick(fingers: $0), modifiers: [], isMagicTrackpad: magicTrackpad)] != nil
            }
            guard !actions.isEmpty || clicks else { return nil }
            return TrackpadRuntime(revision: $0.actionRevision, inputActivity: $0.inputActivity,
                                   isMagicTrackpad: magicTrackpad,
                                   actions: actions, hasClickRules: clicks,
                                   doubleTapIntervalNanoseconds: supportsDouble ? interval : 500_000_000)
        }
    }

    /// Invalidates touch input on a changed target or an observed application activation.
    nonisolated func updateTrackpadForeground(_ pid: Int32?, activationChanged: Bool = false) {
        state.withLock {
            guard activationChanged || $0.foregroundPID != pid else { return }
            // A -> B -> A must not revive dequeued output or buffered contacts.
            // Activation notifications can arrive after the final PID is already
            // visible, so the notification itself also invalidates the snapshot.
            $0.inputActivity &+= 1
            $0.foregroundPID = pid
            $0.trackpadDispatch = nil
        }
    }

    // One extra bounded slot, never a delayed backlog of touch actions. Existing
    // keyboard/mouse dispatch remains unchanged. Focus/activity gates are rechecked
    // by the serial action worker before posting directly to the captured PID.
    @discardableResult nonisolated func submitTrackpad(_ runtime: TrackpadRuntime, tap: TrackpadSingleTap = .fourFinger,
                                                     pid: Int32, at now: UInt64) -> Bool {
        submitTrackpad(runtime, gesture: .single(tap), pid: pid, at: now)
    }

    @discardableResult nonisolated func submitTrackpad(_ runtime: TrackpadRuntime, gesture: TrackpadTapGesture,
                                                     pid: Int32, at now: UInt64) -> Bool {
        state.withLock {
            if gesture.isDoubleTap {
                guard (1...2_000_000_000).contains($0.matcher.doublePressIntervalNanoseconds),
                      runtime.doubleTapIntervalNanoseconds == $0.matcher.doublePressIntervalNanoseconds else { return false }
            }
            guard now <= UInt64.max - 100_000_000, $0.pending.isEmpty,
                  $0.workspaceRequest == nil, $0.trackpadDispatch == nil,
                  $0.actionRevision == runtime.revision, $0.inputActivity == runtime.inputActivity,
                  $0.foregroundPID == pid, let action = runtime.actions[gesture],
                  $0.rules[MatchKey(trigger: gesture.trigger, modifiers: [],
                                    isMagicTrackpad: runtime.isMagicTrackpad)]?.action == action else { return false }
            let dispatch = ActionDispatch(action: action, revision: runtime.revision,
                deviceID: $0.audioCapabilities.deviceID, trackpadTarget: TrackpadDispatchTarget(pid: pid, inputActivity: runtime.inputActivity,
                                                      expiresAt: now + 100_000_000, queuedAt: now))
            guard $0.dispatchIsCurrent(dispatch) else { return false }
            $0.trackpadDispatch = dispatch
            return true
        }
    }
}
