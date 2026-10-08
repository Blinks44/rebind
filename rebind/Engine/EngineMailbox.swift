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
        var hasPointerGestureRules = false
        var enabled = false
        var suspended = false
        var stopped = false
        var status: EngineStatus = .paused
        var recording: RecordingRequest?
        var editing = false
        var recorded: RecordedInput?
        var matcher = InputMatcher()
        var pending: [KeyboardShortcut] = []
        var emergencyPause = false
        var retryID: UInt64 = 0

        init() { pending.reserveCapacity(16) }
    }

    let state = Mutex(State())

    func configure(_ configuration: Configuration, doublePressIntervalNanoseconds: UInt64 = 500_000_000) {
        let compiled = InputMatcher.compile(configuration.bindings)
        state.withLock {
            if configuration.isEnabled && !$0.enabled { $0.retryID &+= 1 }
            $0.rules = compiled
            $0.hasPointerGestureRules = compiled.keys.contains { $0.trigger.isPointerGesture }
            $0.enabled = configuration.isEnabled
            $0.pending.removeAll(keepingCapacity: true)
            $0.matcher.cancelPendingActivation()
            $0.matcher.doublePressIntervalNanoseconds = max(1, doublePressIntervalNanoseconds)
        }
    }

    func record(_ request: RecordingRequest?) {
        state.withLock {
            if request != nil { $0.retryID &+= 1 }
            $0.recording = request
            $0.recorded = nil
            $0.pending.removeAll(keepingCapacity: true)
            $0.matcher.cancelPendingActivation()
        }
    }

    func setEditing(_ editing: Bool) {
        state.withLock {
            $0.editing = editing
            $0.pending.removeAll(keepingCapacity: true)
            $0.matcher.cancelPendingActivation()
        }
    }

    func suspend(_ suspended: Bool) {
        state.withLock {
            $0.suspended = suspended
            $0.recording = nil
            $0.pending.removeAll(keepingCapacity: true)
            $0.matcher.resetAfterCaptureLoss()
        }
    }

    func handle(_ event: InputEvent, secureInput: Bool) -> Bool {
        guard !event.isSynthetic else { return false }
        return state.withLock { Self.handle(event, state: &$0, secureInput: secureInput) }
    }

    func handlePointerMotion(_ motion: PointerMotion, modifiers: ModifierSet, receivedAt: UInt64,
                             secureInput: Bool) -> Bool {
        state.withLock { state in
            guard let source = state.matcher.pointerGestureSource else { return false }
            let event = InputEvent(trigger: source, modifiers: modifiers, phase: .drag,
                                   receivedAt: receivedAt, motion: motion)
            return Self.handle(event, state: &state, secureInput: secureInput)
        }
    }

    private static func handle(_ event: InputEvent, state: inout State, secureInput: Bool) -> Bool {
        guard !state.stopped, !state.suspended, !secureInput else {
            state.pending.removeAll(keepingCapacity: true)
            state.matcher.resetAfterCaptureLoss()
            return false
        }
        // Evaluate once: a disabled pre-pass would cancel a temporal sequence.
        // Ownership/emergency bypass still work during pause, editing or recording.
        let decision = state.matcher.handle(event, rules: state.recording == nil ? state.rules : [:],
                                            enabled: state.enabled && !state.editing && state.recording == nil,
                                            canDispatch: state.pending.count < 16)
        if decision.emergencyPause {
            state.enabled = false
            state.emergencyPause = true
            state.recording = nil
            state.pending.removeAll(keepingCapacity: true)
            return true
        }
        if let shortcut = decision.shortcut { state.pending.append(shortcut) }
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
                state.pending.removeAll(keepingCapacity: true)
                state.matcher.resetAfterCaptureLoss()
                return
            }
            state.matcher.expirePointerGesture(at: now)
            if let shortcut = state.matcher.pollHold(at: now, rules: state.rules,
                                                      enabled: state.enabled && !state.editing && state.recording == nil,
                                                      canDispatch: state.pending.count < 16) {
                state.pending.append(shortcut)
            }
        }
    }

    func cancelHold() { state.withLock { $0.matcher.cancelHold() } }
}
