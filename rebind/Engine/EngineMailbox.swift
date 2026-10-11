import Foundation
import Synchronization

nonisolated enum EngineStatus: Sendable {
    case paused, active, permissionRequired, secureInput, tapFailed, interrupted, outputFailed
}

nonisolated enum RecordingTarget: Hashable, Sendable { case keyboardTrigger, mouseTrigger, gestureTrigger, scrollTrigger, output }

nonisolated struct RecordingRequest: Sendable, Equatable {
    var id = UUID()
    var target: RecordingTarget
}

nonisolated struct RecordedInput: Sendable {
    var request: RecordingRequest
    var input: MatchKey?
}

nonisolated final class EngineMailbox: Sendable {
    struct State: Sendable {
        var rules: [MatchKey: CompiledBinding] = [:]
        var allRules: [MatchKey: CompiledBinding] = [:]
        var windowDisplays = WindowDisplaySnapshot()
        var audioCapabilities = AudioOutputCapabilities()
        var actionRevision: UInt64 = 0
        var actionFailed: RebindAction?
        var hasPointerGestureRules = false
        var enabled = false
        var suspended = false
        var stopped = false
        var status: EngineStatus = .paused
        var recording: RecordingRequest?
        var editing = false
        var recorded: RecordedInput?
        var matcher = InputMatcher()
        var pending: [RebindAction] = []
        var trackpadDispatch: ActionDispatch?
        var trackpadStatus: TrackpadCaptureStatus = .idle
        var trackpadDiagnostics: TrackpadDiagnostics?
        var inputActivity: UInt64 = 0
        var foregroundPID: Int32?
        var workspaceRequest: WorkspaceRequest?
        var workspaceClaimed = false
        var appleShortcutInProgress = false
        var emergencyPause = false
        var retryID: UInt64 = 0
        var diagnostics = InputDiagnostics()
        var profileID = RuleProfile.defaultID

        init() { pending.reserveCapacity(16) }

        func dispatchIsCurrent(_ dispatch: ActionDispatch) -> Bool {
            actionRevision == dispatch.revision && status == .active && enabled
                && !editing && !suspended && !stopped && recording == nil
                && audioCapabilities.supports(dispatch.action)
                && (dispatch.trackpadTarget.map {
                    $0.pid == foregroundPID && $0.inputActivity == inputActivity
                } ?? true)
        }

        mutating func resetCapture(status: EngineStatus) {
            if status == .secureInput || status == .permissionRequired || status == .interrupted {
                trackpadDiagnostics = nil
            }
            if let request = recording {
                recorded = RecordedInput(request: request, input: nil)
                recording = nil
            }
            actionRevision &+= 1
            pending.removeAll(keepingCapacity: true)
            trackpadDispatch = nil
            matcher.resetAfterCaptureLoss()
            diagnostics.stop(clear: true)
            self.status = status
        }
    }

    let state = Mutex(State())

    /// Explicit UI recovery only; no automatic retry or enable-state mutation.
    func retryCapture() {
        state.withLock {
            guard $0.enabled, !$0.suspended, !$0.stopped,
                  $0.status == .tapFailed || $0.status == .interrupted || $0.status == .outputFailed else { return }
            $0.retryID &+= 1
        }
    }

    func configure(_ configuration: Configuration, doublePressIntervalNanoseconds: UInt64 = 500_000_000) {
        let compiled = InputMatcher.compile(configuration.bindings)
        state.withLock {
            if $0.profileID != configuration.selectedProfileID {
                $0.profileID = configuration.selectedProfileID
                $0.recording = nil
                $0.recorded = nil
            }
            if configuration.isEnabled && !$0.enabled { $0.retryID &+= 1 }
            $0.actionRevision &+= 1
            $0.actionFailed = nil
            $0.allRules = compiled
            let capabilities = $0.audioCapabilities
            $0.rules = compiled.filter { capabilities.supports($0.value.action) }
            $0.hasPointerGestureRules = $0.rules.keys.contains { $0.trigger.isPointerGesture }
            $0.enabled = configuration.isEnabled
            $0.pending.removeAll(keepingCapacity: true)
            $0.trackpadDispatch = nil
            $0.matcher.cancelPendingActivation()
            $0.matcher.doublePressIntervalNanoseconds = max(1, doublePressIntervalNanoseconds)
        }
    }

    func updateWindowDisplays(_ snapshot: WindowDisplaySnapshot) {
        // Screen refreshes must not invalidate queued unrelated actions or holds.
        state.withLock { $0.windowDisplays = snapshot }
    }

    func updateAudioCapabilities(_ capabilities: AudioOutputCapabilities) {
        state.withLock {
            guard $0.audioCapabilities != capabilities else { return }
            $0.audioCapabilities = capabilities
            $0.rules = $0.allRules.filter { capabilities.supports($0.value.action) }
            $0.hasPointerGestureRules = $0.rules.keys.contains { $0.trigger.isPointerGesture }
            $0.actionRevision &+= 1
            $0.pending.removeAll(keepingCapacity: true)
            $0.trackpadDispatch = nil
            $0.matcher.cancelPendingActivation()
        }
    }

    func nextAction() -> ActionDispatch? {
        state.withLock {
            // An unclaimed stale request can be discarded immediately. A native
            // request already accepted must finish before another action starts.
            if let request = $0.workspaceRequest, !$0.workspaceClaimed,
               !$0.dispatchIsCurrent(request.dispatch) { $0.workspaceRequest = nil }
            guard $0.status == .active, $0.enabled, !$0.editing, !$0.suspended,
                  !$0.stopped, $0.recording == nil,
                  $0.workspaceRequest == nil else { return nil }
            if let dispatch = $0.trackpadDispatch {
                $0.trackpadDispatch = nil
                if $0.dispatchIsCurrent(dispatch) { return dispatch }
            }
            guard !$0.pending.isEmpty else { return nil }
            return ActionDispatch(action: $0.pending.removeFirst(), revision: $0.actionRevision,
                                  deviceID: $0.audioCapabilities.deviceID)
        }
    }

    func dispatchIsCurrent(_ dispatch: ActionDispatch) -> Bool {
        state.withLock { $0.dispatchIsCurrent(dispatch) }
    }

    func systemTransitionRequested(_ dispatch: ActionDispatch) {
        state.withLock {
            guard $0.actionRevision == dispatch.revision else { return }
            // Do not run already queued work or delayed recognition during the
            // transition to sleep/lock. Keep suppressed press ownership until up.
            $0.diagnostics.stop(clear: true)
            $0.actionRevision &+= 1
            $0.pending.removeAll(keepingCapacity: true)
            $0.trackpadDispatch = nil
            $0.matcher.cancelPendingActivation()
        }
    }

    func submitWorkspace(_ request: WorkspaceRequest) {
        state.withLock {
            guard $0.workspaceRequest == nil, $0.dispatchIsCurrent(request.dispatch) else { return }
            $0.workspaceRequest = request
        }
    }

    var hasWorkspaceRequest: Bool { state.withLock { $0.workspaceRequest != nil && !$0.workspaceClaimed } }

    func claimWorkspace() -> WorkspaceRequest? {
        state.withLock {
            guard let request = $0.workspaceRequest, !$0.workspaceClaimed else { return nil }
            guard $0.dispatchIsCurrent(request.dispatch) else { $0.workspaceRequest = nil; return nil }
            $0.workspaceClaimed = true
            return request
        }
    }

    func finishWorkspace(_ request: WorkspaceRequest, failed: Bool) {
        state.withLock {
            guard $0.workspaceRequest?.dispatch.id == request.dispatch.id else { return }
            if failed && $0.dispatchIsCurrent(request.dispatch) { $0.actionFailed = request.dispatch.action }
            $0.workspaceRequest = nil
            $0.workspaceClaimed = false
        }
    }

    func actionFailed(_ dispatch: ActionDispatch) {
        state.withLock {
            guard $0.actionRevision == dispatch.revision else { return }
            $0.actionFailed = dispatch.action
            switch dispatch.action {
            case .shortcut, .desktop:
                $0.resetCapture(status: .outputFailed)
                $0.enabled = false
                $0.emergencyPause = true
            default: break
            }
        }
    }

    func record(_ request: RecordingRequest?) {
        state.withLock {
            if request != nil { $0.retryID &+= 1 }
            $0.actionRevision &+= 1
            $0.recording = request
            $0.recorded = nil
            $0.pending.removeAll(keepingCapacity: true)
            $0.trackpadDispatch = nil
            $0.matcher.cancelPendingActivation()
        }
    }

    func setEditing(_ editing: Bool) {
        state.withLock {
            $0.actionRevision &+= 1
            $0.editing = editing
            $0.pending.removeAll(keepingCapacity: true)
            $0.trackpadDispatch = nil
            $0.matcher.cancelPendingActivation()
        }
    }

    func suspend(_ suspended: Bool) {
        state.withLock {
            guard $0.suspended != suspended else { return }
            $0.suspended = suspended
            $0.resetCapture(status: .paused)
        }
    }

    func captureLost(status: EngineStatus, pause: Bool = false) {
        state.withLock {
            $0.resetCapture(status: status)
            if pause {
                $0.enabled = false
                $0.emergencyPause = true
            }
        }
    }

    func stop() {
        state.withLock {
            $0.stopped = true
            $0.resetCapture(status: .paused)
        }
    }

    func handle(_ event: InputEvent, secureInput: Bool) -> Bool {
        guard !event.isSynthetic, !event.trigger.isTrackpad else { return false }
        return state.withLock { Self.handleAndDiagnose(event, state: &$0, secureInput: secureInput) }
    }

    func handlePointerMotion(_ motion: PointerMotion, modifiers: ModifierSet, receivedAt: UInt64,
                             secureInput: Bool) -> Bool {
        state.withLock { state in
            guard !state.stopped, !state.suspended, !secureInput else {
                state.resetCapture(status: secureInput ? .secureInput : .paused)
                return false
            }
            guard let source = state.matcher.pointerGestureSource else { return false }
            let event = InputEvent(trigger: source, modifiers: modifiers, phase: .drag,
                                   receivedAt: receivedAt, motion: motion)
            return Self.handleAndDiagnose(event, state: &state, secureInput: secureInput)
        }
    }

    private static func handleAndDiagnose(_ event: InputEvent, state: inout State, secureInput: Bool) -> Bool {
        // Any real key/button/wheel activity invalidates a delayed touch action.
        // No key code/text is retained by the touch recognizer.
        if event.phase != .drag { state.inputActivity &+= 1; state.trackpadDispatch = nil }
        let pendingCount = state.pending.count
        let suppressed = handle(event, state: &state, secureInput: secureInput)
        state.diagnostics.record(event, suppressed: suppressed, queued: state.pending.count > pendingCount)
        return suppressed
    }

    @discardableResult func startDiagnostics(at now: UInt64) -> Bool {
        state.withLock {
            guard !$0.stopped, !$0.suspended else { return false }
            $0.diagnostics.start(at: now)
            $0.retryID &+= 1
            return true
        }
    }

    func stopDiagnostics(clear: Bool = false) { state.withLock { $0.diagnostics.stop(clear: clear) } }
    func clearDiagnostics() { state.withLock { $0.diagnostics.clear() } }

    func diagnosticSnapshot(since revision: UInt64, at now: UInt64) -> DiagnosticSnapshot? {
        state.withLock {
            $0.diagnostics.expire(at: now)
            guard $0.diagnostics.revision != revision else { return nil }
            return $0.diagnostics.snapshot()
        }
    }

    func handleUnsupportedScroll(modifiers: ModifierSet, at now: UInt64, secureInput: Bool) {
        state.withLock {
            guard !$0.stopped, !$0.suspended, !secureInput else {
                $0.resetCapture(status: secureInput ? .secureInput : .paused)
                return
            }
            $0.inputActivity &+= 1
            $0.trackpadDispatch = nil
            $0.matcher.cancelHold()
            $0.diagnostics.append(kind: .unsupportedScroll, phase: .scroll, modifiers: modifiers,
                                  outcome: .passedThrough, at: now)
        }
    }

    private static func handle(_ event: InputEvent, state: inout State, secureInput: Bool) -> Bool {
        guard !state.stopped, !state.suspended, !secureInput else {
            state.resetCapture(status: secureInput ? .secureInput : .paused)
            return false
        }
        // Evaluate once: a disabled pre-pass would cancel a temporal sequence.
        // Ownership/emergency bypass still work during pause, editing or recording.
        let decision = state.matcher.handle(event, rules: state.recording == nil ? state.rules : [:],
                                            enabled: state.enabled && !state.editing && state.recording == nil,
                                            canDispatch: state.pending.count < 16)
        if decision.emergencyPause {
            state.actionRevision &+= 1
            state.enabled = false
            state.emergencyPause = true
            state.recording = nil
            state.pending.removeAll(keepingCapacity: true)
            state.trackpadDispatch = nil
            state.diagnostics.stop(clear: true)
            return true
        }
        if let action = decision.action { state.pending.append(action) }
        if decision.suppress { return true }
        if let request = state.recording {
            guard event.phase == .down || event.phase == .scroll, !event.isRepeat else { return false }
            if event.trigger == .key(53) {
                state.recorded = RecordedInput(request: request, input: nil)
            } else {
                let matchesCategory: Bool
                switch (request.target, event.trigger) {
                case (.mouseTrigger, .mouseButton), (.gestureTrigger, .mouseButton): matchesCategory = true
                case (.scrollTrigger, .scroll): matchesCategory = true
                case (.keyboardTrigger, .key), (.output, .key): matchesCategory = true
                default: matchesCategory = false
                }
                guard matchesCategory, event.trigger.isSupported,
                      event.modifiers.subtracting(.supported).isEmpty else { return false }
                state.recorded = RecordedInput(request: request,
                                               input: MatchKey(trigger: event.trigger, modifiers: event.modifiers))
            }
            state.recording = nil
            state.matcher.consume(event)
            return true
        }
        return false
    }

    func pollHold(at now: UInt64, secureInput: Bool) {
        state.withLock { state in
            guard !state.stopped, !state.suspended, !secureInput else {
                state.resetCapture(status: secureInput ? .secureInput : .paused)
                return
            }
            state.matcher.expirePointerGesture(at: now)
            let holdKey = state.matcher.holdKey
            if let action = state.matcher.pollHold(at: now, rules: state.rules,
                                                      enabled: state.enabled && !state.editing && state.recording == nil,
                                                      canDispatch: state.pending.count < 16) {
                state.pending.append(action)
                if let holdKey, case .mouseButton(let number) = holdKey.trigger {
                    state.diagnostics.append(kind: .button(number), phase: .activation, modifiers: holdKey.modifiers,
                                             outcome: .queued, at: now)
                }
            }
        }
    }

    func cancelHold() { state.withLock { $0.matcher.cancelHold() } }
}
