import Foundation

/// Unsaved capture values; cancelled or stale recordings never replace the draft.
nonisolated struct BindingEditorDraft {
    var trigger: MatchKey?
    var output: KeyboardShortcut?
    var mouseTarget: RecordingTarget
    var activation: PressActivation
    var holdDurationMilliseconds: UInt32
    var pointerDirection: PointerDirection

    var trackpadPreset: TrackpadPreset? {
        get { trigger.flatMap { TrackpadPreset(trigger: $0.trigger) } }
        set {
            guard let newValue else { return }
            trigger = MatchKey(trigger: newValue.gesture.trigger, modifiers: [])
            activation = .press
        }
    }

    init(scope: DeviceScope, existing: Binding?) {
        trigger = existing?.matchKey.pressSource
            ?? (scope == .builtInTrackpad ? MatchKey(trigger: .fourFingerTap, modifiers: []) : nil)
        output = existing?.action.shortcut
        activation = existing?.activation ?? .press
        holdDurationMilliseconds = existing?.holdDurationMilliseconds ?? 500
        mouseTarget = .mouseTrigger
        pointerDirection = .left
        if let existing {
            switch existing.trigger {
            case .scroll: mouseTarget = .scrollTrigger
            case .mouseGesture(_, let direction):
                mouseTarget = .gestureTrigger
                pointerDirection = direction
            default: break
            }
        }
    }

    mutating func selectMouseTarget(_ target: RecordingTarget) {
        mouseTarget = target
        trigger = nil
        activation = .press
        holdDurationMilliseconds = 500
        pointerDirection = .left
    }

    mutating func accept(_ recorded: RecordedInput, for request: RecordingRequest?, scope: DeviceScope) {
        guard recorded.request == request, let input = recorded.input else { return }
        switch recorded.request.target {
        case .output:
            guard case .key(let code) = input.trigger else { return }
            output = KeyboardShortcut(keyCode: code, modifiers: input.modifiers)
        case .keyboardTrigger:
            guard scope == .allKeyboards, case .key = input.trigger else { return }
            trigger = input
        case .mouseTrigger, .gestureTrigger:
            guard scope == .allMice, recorded.request.target == mouseTarget,
                  case .mouseButton = input.trigger, input.trigger.isSupported else { return }
            trigger = input
        case .scrollTrigger:
            guard scope == .allMice, mouseTarget == .scrollTrigger, case .scroll = input.trigger else { return }
            trigger = input
        }
    }

    func binding(scope: DeviceScope, action: RebindAction, existing: Binding?) -> Binding? {
        guard let trigger else { return nil }
        var source = trigger.trigger
        if scope == .allMice {
            switch mouseTarget {
            case .gestureTrigger:
                guard case .mouseButton(let button) = source else { return nil }
                source = .mouseGesture(button: button, direction: pointerDirection)
            case .mouseTrigger:
                guard case .mouseButton = source else { return nil }
            case .scrollTrigger:
                guard case .scroll = source else { return nil }
            default: return nil
            }
        }
        var binding = Binding(scope: scope, trigger: source, modifiers: trigger.modifiers, action: action,
            activation: source.isScroll || source.isPointerGesture ? .press : activation,
            holdDurationMilliseconds: holdDurationMilliseconds)
        if let existing { binding.id = existing.id; binding.isEnabled = existing.isEnabled }
        return binding
    }
}
