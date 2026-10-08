import Foundation
import Synchronization

nonisolated enum EngineStatus: Sendable {
    case paused, active, permissionRequired, secureInput, tapFailed, interrupted, outputFailed
}

nonisolated enum RecordingTarget: Sendable { case keyboardTrigger, mouseTrigger, output }

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
        var rules: [MatchKey: KeyboardShortcut] = [:]
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

    func configure(_ configuration: Configuration) {
        let compiled = InputMatcher.compile(configuration.bindings)
        state.withLock {
            if configuration.isEnabled && !$0.enabled { $0.retryID &+= 1 }
            $0.rules = compiled
            $0.enabled = configuration.isEnabled
            $0.pending.removeAll(keepingCapacity: true)
        }
    }

    func record(_ request: RecordingRequest?) {
        state.withLock {
            if request != nil { $0.retryID &+= 1 }
            $0.recording = request
            $0.recorded = nil
            $0.pending.removeAll(keepingCapacity: true)
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
        return state.withLock { state in
            guard !state.stopped, !state.suspended, !secureInput else {
                state.pending.removeAll(keepingCapacity: true)
                state.matcher.resetAfterCaptureLoss()
                return false
            }
            // Resolve releases/repeats first, including a key recorded before cancellation.
            let release = state.matcher.handle(event, rules: [:], enabled: false)
            if release.emergencyPause {
                state.enabled = false
                state.emergencyPause = true
                state.recording = nil
                state.pending.removeAll(keepingCapacity: true)
                return true
            }
            if release.suppress { return true }
            if let request = state.recording {
                guard event.phase == .down, !event.isRepeat else { return false }
                if event.trigger == .key(53) {
                    state.recorded = RecordedInput(request: request, input: nil)
                } else {
                    let matchesCategory: Bool
                    switch (request.target, event.trigger) {
                    case (.mouseTrigger, .mouseButton): matchesCategory = true
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
            let decision = state.matcher.handle(event, rules: state.rules, enabled: state.enabled && !state.editing,
                                                canDispatch: state.pending.count < 16)
            if let shortcut = decision.shortcut { state.pending.append(shortcut) }
            return decision.suppress
        }
    }
}
