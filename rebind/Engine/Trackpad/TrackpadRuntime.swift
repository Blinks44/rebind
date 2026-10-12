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
    /// The existing four-finger rule, if enabled in the selected profile.
    var fourFingerShortcut: KeyboardShortcut?
    var threeFingerShortcut: KeyboardShortcut? = nil
    var threeFingerDoubleShortcut: KeyboardShortcut? = nil
    var fourFingerDoubleShortcut: KeyboardShortcut? = nil
    var doubleTapIntervalNanoseconds: UInt64 = 500_000_000

    var enabledGestures: Set<TrackpadTapSequence.Gesture> {
        Set(TrackpadSingleTap.allCases.flatMap { tap in
            [TrackpadTapGesture.single(tap), .double(tap)].compactMap { gesture in
                shortcut(for: gesture) == nil ? nil : gesture.sequenceGesture
            }
        })
    }

    func shortcut(for gesture: TrackpadTapGesture) -> KeyboardShortcut? {
        switch gesture {
        case .single(let tap): shortcut(for: tap)
        case .double(.threeFinger): threeFingerDoubleShortcut
        case .double(.fourFinger): fourFingerDoubleShortcut
        }
    }

    func recognizes(_ tap: TrackpadSingleTap) -> Bool {
        shortcut(for: .single(tap)) != nil || shortcut(for: .double(tap)) != nil
    }

    func shortcut(for tap: TrackpadSingleTap) -> KeyboardShortcut? {
        switch tap {
        case .threeFinger: threeFingerShortcut
        case .fourFinger: fourFingerShortcut
        }
    }
}

extension EngineMailbox {
    nonisolated func trackpadRuntime() -> TrackpadRuntime? {
        state.withLock {
            guard $0.status == .active, $0.enabled, !$0.editing, !$0.suspended, !$0.stopped,
                  $0.recording == nil else { return nil }
            let four = $0.rules[MatchKey(trigger: .fourFingerTap, modifiers: [])]?.action.shortcut
            let three = $0.rules[MatchKey(trigger: .threeFingerTap, modifiers: [])]?.action.shortcut
            let interval = $0.matcher.doublePressIntervalNanoseconds
            // An unsupported system interval disables only double recognition;
            // existing single-tap rules remain usable without a delayed backlog.
            let supportsDouble = (1...2_000_000_000).contains(interval)
            let doubleThree = supportsDouble ? $0.rules[MatchKey(trigger: .threeFingerDoubleTap, modifiers: [])]?.action.shortcut : nil
            let doubleFour = supportsDouble ? $0.rules[MatchKey(trigger: .fourFingerDoubleTap, modifiers: [])]?.action.shortcut : nil
            guard four != nil || three != nil || doubleThree != nil || doubleFour != nil else { return nil }
            return TrackpadRuntime(revision: $0.actionRevision, inputActivity: $0.inputActivity,
                                   fourFingerShortcut: four, threeFingerShortcut: three,
                                   threeFingerDoubleShortcut: doubleThree, fourFingerDoubleShortcut: doubleFour,
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
            if case .double = gesture {
                guard (1...2_000_000_000).contains($0.matcher.doublePressIntervalNanoseconds),
                      runtime.doubleTapIntervalNanoseconds == $0.matcher.doublePressIntervalNanoseconds else { return false }
            }
            guard now <= UInt64.max - 100_000_000, $0.pending.isEmpty,
                  $0.workspaceRequest == nil, $0.trackpadDispatch == nil,
                  $0.actionRevision == runtime.revision, $0.inputActivity == runtime.inputActivity,
                  $0.foregroundPID == pid, let shortcut = runtime.shortcut(for: gesture),
                  $0.rules[MatchKey(trigger: gesture.trigger, modifiers: [])]?.action.shortcut == shortcut else { return false }
            let dispatch = ActionDispatch(action: .shortcut(shortcut), revision: runtime.revision,
                trackpadTarget: TrackpadDispatchTarget(pid: pid, inputActivity: runtime.inputActivity,
                                                      expiresAt: now + 100_000_000, queuedAt: now))
            guard $0.dispatchIsCurrent(dispatch) else { return false }
            $0.trackpadDispatch = dispatch
            return true
        }
    }
}
