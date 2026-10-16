import Foundation
import Synchronization

nonisolated enum EngineStatus: Sendable {
    case paused, active, permissionRequired, secureInput, tapFailed, interrupted, outputFailed
}

nonisolated enum RecordingTarget: Hashable, Sendable {
    case keyboardTrigger, mouseTrigger, gestureTrigger, scrollTrigger, buttonScrollTrigger, output, tapOutput
}

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
        /// The rules in effect for the app in front, without actions the audio output cannot do.
        var rules: [MatchKey: CompiledBinding] = [:]
        /// Rules for every app, and the effective set of each app that has rules of its own.
        var generalRules: [MatchKey: CompiledBinding] = [:]
        var applicationRules: [String: [MatchKey: CompiledBinding]] = [:]
        var windowDisplays = WindowDisplaySnapshot()
        var audioCapabilities = AudioOutputCapabilities()
        var actionRevision: UInt64 = 0
        var actionFailed: RebindAction?
        var hasPointerGestureRules = false
        var enabled = false
        /// Bundle identifiers of apps in which Rebind skips bindings, gestures and wheel changes.
        var excludedApplications: Set<String> = []
        /// Bundle identifiers of apps in which wheel clicks are not smoothed.
        var smoothScrollingExclusions: Set<String> = []
        /// The app whose window is under the pointer, while `PointerApplicationTracker` runs.
        var pointerBundleID: String?
        var foregroundBundleID: String?
        /// Enabled and not in front of an excluded app. Pause state itself is `enabled`.
        var isMatching: Bool { enabled && !(foregroundBundleID.map(excludedApplications.contains) ?? false) }
        var suspended = false
        var stopped = false
        var status: EngineStatus = .paused
        var recording: RecordingRequest?
        var editing = false
        var recorded: RecordedInput?
        var matcher = InputMatcher()
        var pending: [RebindAction] = []
        var held: [HeldOutput] = []
        var keyRepeat = KeyRepeatTiming()
        var wheel: WheelAdjustment?
        /// Smooth scrolling of each mouse that has it on, by the registry ID of its HID service.
        var smoothScrollingBySender: [UInt64: SmoothScrollingSettings] = [:]
        var smoothScrollingRevision: UInt64 = 0
        static let maximumHeldOutputs = 4
        var trackpadDispatch: ActionDispatch?
        var trackpadStatus: TrackpadCaptureStatus = .idle
        var trackpadDiagnostics: TrackpadDiagnostics?
        var trackpadClicks = TrackpadClickFilter()
        var magicTrackpadClicks = TrackpadClickFilter()
        var inputActivity: UInt64 = 0
        var foregroundPID: Int32?
        var workspaceRequest: WorkspaceRequest?
        var workspaceClaimed = false
        var appleShortcutInProgress = false
        var emergencyPause = false
        /// Profile steps requested by rules, applied by the UI model: +1 next, -1 previous.
        var profileStep = 0
        var retryID: UInt64 = 0
        var diagnostics = InputDiagnostics()
        var profileID = RuleProfile.defaultID

        init() { pending.reserveCapacity(Self.maximumPending); held.reserveCapacity(Self.maximumHeldOutputs) }

        static let maximumPending = 16

        var canDispatch: Bool {
            status == .active && isMatching && !editing && !suspended && !stopped && recording == nil
        }

        /// The wheel change for an event Rebind passes through, or nil while rules are not running.
        var activeWheelAdjustment: WheelAdjustment? {
            status == .active && isMatching && !suspended && !stopped ? wheel : nil
        }

        /// Smooth scrolling of the mouse that sent a wheel event while Rebind is on, unless the app
        /// under the pointer, which receives the scroll, opts out (the app in front when unknown).
        func activeSmoothScrolling(sender: UInt64?) -> SmoothScrollingSettings? {
            guard let sender, let settings = smoothScrollingBySender[sender], status == .active, enabled,
                  !suspended, !stopped, !editing, recording == nil,
                  !((pointerBundleID ?? foregroundBundleID).map(smoothScrollingExclusions.contains) ?? false) else { return nil }
            return settings
        }

        /// Swaps in the rules of the app in front; called when it, the rules or the audio output change.
        mutating func selectRules() {
            let all = foregroundBundleID.flatMap { applicationRules[$0] } ?? generalRules
            let capabilities = audioCapabilities
            rules = all.filter { capabilities.supports($0.value.action) }
            hasPointerGestureRules = rules.keys.contains { $0.trigger.isPointerGesture }
        }

        /// Whether rules may match at all; ownership and the emergency bypass work regardless.
        var matchesRules: Bool { isMatching && !editing && recording == nil }
        var hasQueueSpace: Bool { pending.count < Self.maximumPending }

        /// Invalidates dispatched and waiting work. Presses already swallowed keep their release.
        mutating func cancelQueuedWork() {
            actionRevision &+= 1
            smoothScrollingRevision &+= 1
            pending.removeAll(keepingCapacity: true)
            cancelHeldOutputs()
            trackpadDispatch = nil
            matcher.cancelPendingActivation()
        }

        /// Turns rules off from the engine side; the UI model persists it on its next refresh.
        mutating func pause() {
            enabled = false
            emergencyPause = true
        }

        /// Ends every held output. A key that is already down still gets its release.
        mutating func cancelHeldOutputs() {
            held.removeAll { $0.pressedAt == nil }
            for index in held.indices { held[index].released = true }
        }

        /// The trigger was physically released. A press the worker has not performed yet
        /// becomes an ordinary single action, so a quick tap is never lost.
        mutating func releaseHeldOutput(for trigger: InputTrigger) {
            guard let index = held.firstIndex(where: { $0.trigger == trigger && !$0.released }) else { return }
            if held[index].pressedAt == nil {
                let action = held.remove(at: index).action
                if !action.requiresHeldOutput, hasQueueSpace { pending.append(action) }
            } else { held[index].released = true }
        }

        /// Modifiers Rebind is holding for the user; the tap adds them to the input it passes on.
        var virtualModifiers: ModifierSet {
            held.reduce(into: ModifierSet()) { result, output in
                if case .modifier(let modifiers) = output.action, output.pressedAt != nil, !output.released {
                    result.formUnion(modifiers)
                }
            }
        }

        /// One step per worker pass: a due release first, then a press or repeat.
        mutating func nextHeldKey(at now: UInt64) -> HeldKeyCommand? {
            while let index = held.firstIndex(where: \.released) {
                let output = held.remove(at: index)
                guard let target = output.action.heldKeyTarget else { continue }
                let others = held.filter { $0.pressedAt != nil }
                let modifiers = others.reduce(into: ModifierSet()) { flags, output in
                    if case .modifier(let held) = output.action { flags.formUnion(held) }
                }
                var command: HeldKeyCommand
                switch target {
                case .shortcut(let shortcut):
                    let sharing = held.indices.filter {
                        held[$0].pressedAt != nil && held[$0].action.shortcut?.keyCode == shortcut.keyCode
                    }
                    guard sharing.isEmpty else {
                        // The remaining owners continue the same repeat stream.
                        let timings = sharing.map { held[$0] } + [output]
                        let pressedAt = timings.compactMap(\.pressedAt).min()
                        let lastRepeatAt = timings.compactMap(\.lastRepeatAt).max()
                        for owner in sharing {
                            held[owner].pressedAt = pressedAt
                            held[owner].lastRepeatAt = lastRepeatAt
                        }
                        continue
                    }
                    command = HeldKeyCommand(target: target, phase: .release)
                case .modifiers(let released):
                    let unowned = released.subtracting(modifiers)
                    guard !unowned.isEmpty else { continue }
                    command = HeldKeyCommand(target: .modifiers(unowned), phase: .release)
                }
                command.otherModifiers = modifiers
                return command
            }
            guard canDispatch else { return nil }
            for index in held.indices {
                let output = held[index]
                let isDue: Bool
                if let pressedAt = output.pressedAt {
                    // A modifier is down once; only keys and step actions repeat.
                    if output.action.requiresHeldOutput { continue }
                    // A shared key repeats once per interval: only its earliest owner repeats.
                    if let keyCode = output.action.shortcut?.keyCode, held[..<index].contains(where: {
                        $0.pressedAt != nil && $0.action.shortcut?.keyCode == keyCode
                    }) { continue }
                    let last = output.lastRepeatAt
                    let next = last.map { $0 &+ keyRepeat.intervalNanoseconds } ?? pressedAt &+ keyRepeat.delayNanoseconds
                    isDue = now >= next
                    if isDue { held[index].lastRepeatAt = now }
                } else {
                    isDue = true
                    held[index].pressedAt = now
                }
                guard isDue else { continue }
                if let target = output.action.heldKeyTarget {
                    let others = held.enumerated().filter { $0.offset != index && $0.element.pressedAt != nil }.map(\.element)
                    let modifiers = others.reduce(into: ModifierSet()) { flags, output in
                        if case .modifier(let held) = output.action { flags.formUnion(held) }
                    }
                    var command = HeldKeyCommand(target: target, phase: output.pressedAt == nil ? .press : .repeatPress)
                    if output.pressedAt == nil {
                        switch target {
                        case .shortcut(let shortcut):
                            if others.contains(where: { $0.action.shortcut?.keyCode == shortcut.keyCode }) { continue }
                        case .modifiers(let pressed):
                            let unowned = pressed.subtracting(modifiers)
                            if unowned.isEmpty { continue }
                            command.target = .modifiers(unowned)
                        }
                    }
                    command.otherModifiers = modifiers
                    return command
                }
                // A step action goes through the ordinary queue each time it is due.
                if hasQueueSpace { pending.append(output.action) }
            }
            return nil
        }

        func dispatchIsCurrent(_ dispatch: ActionDispatch) -> Bool {
            actionRevision == dispatch.revision && canDispatch
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
            smoothScrollingRevision &+= 1
            pending.removeAll(keepingCapacity: true)
            cancelHeldOutputs()
            trackpadDispatch = nil
            matcher.resetAfterCaptureLoss()
            diagnostics.stop(clear: true)
            self.status = status
        }
    }

    let state = Mutex(State())
    private let heldKeyDelivery = Mutex(())

    /// Explicit UI recovery only; no automatic retry or enable-state mutation.
    func retryCapture() {
        state.withLock {
            guard $0.enabled, !$0.suspended, !$0.stopped,
                  $0.status == .tapFailed || $0.status == .interrupted || $0.status == .outputFailed else { return }
            $0.retryID &+= 1
        }
    }

    func configure(_ configuration: Configuration, doublePressIntervalNanoseconds: UInt64 = 500_000_000,
                   keyRepeat: KeyRepeatTiming = KeyRepeatTiming()) {
        let bindings = configuration.bindings
        let general = bindings.filter { $0.application == nil }
        let compiled = InputMatcher.compile(general)
        // An app's rules replace rules for all apps with the same trigger while it is in front.
        var perApplication: [String: [MatchKey: CompiledBinding]] = [:]
        for bundle in Set(bindings.compactMap(\.application?.bundleIdentifier)) {
            let own = bindings.filter { $0.application?.bundleIdentifier == bundle }
            let ownKeys = Set(own.filter(\.isEnabled).map(\.matchKey))
            perApplication[bundle] = InputMatcher.compile(own + general.filter { !ownKeys.contains($0.matchKey) })
        }
        state.withLock {
            if $0.profileID != configuration.selectedProfileID {
                $0.profileID = configuration.selectedProfileID
                $0.profileStep = 0
                $0.recording = nil
                $0.recorded = nil
            }
            if configuration.isEnabled && !$0.enabled { $0.retryID &+= 1 }
            $0.actionFailed = nil
            $0.generalRules = compiled
            $0.applicationRules = perApplication
            $0.selectRules()
            $0.enabled = configuration.isEnabled
            $0.excludedApplications = Set(configuration.excludedApplications.filter { !$0.allowsBindings }.map(\.bundleIdentifier))
            $0.smoothScrollingExclusions = Set(configuration.excludedApplications.filter { !$0.allowsSmoothScrolling }
                .map(\.bundleIdentifier))
            $0.cancelQueuedWork()
            $0.matcher.doublePressIntervalNanoseconds = max(1, doublePressIntervalNanoseconds)
            $0.keyRepeat = keyRepeat
            $0.matcher.pointerThreshold = configuration.pointerGestureDistance.points
            let wheel = WheelAdjustment(reverses: configuration.reversesMouseWheel,
                                        multiplier: configuration.mouseWheelSpeed.multiplier,
                                        reversesHorizontally: configuration.reversesHorizontalScrolling)
            $0.wheel = wheel.changesNothing ? nil : wheel
        }
    }

    /// The app now in front. Entering or leaving an excluded app, or an app with rules of its
    /// own, cancels waiting work; presses Rebind already swallowed keep their release.
    func setForegroundApplication(_ bundleIdentifier: String?) {
        state.withLock { state in
            let wasMatching = state.isMatching
            let previous = state.foregroundBundleID
            state.foregroundBundleID = bundleIdentifier
            if previous != bundleIdentifier { state.smoothScrollingRevision &+= 1 }
            // Only apps with rules of their own change the rule set; other switches keep it.
            let rules = state.applicationRules
            let rulesChanged = previous != bundleIdentifier
                && [previous, bundleIdentifier].contains { $0.map { rules[$0] != nil } ?? false }
            if rulesChanged { state.selectRules() }
            guard state.isMatching != wasMatching || rulesChanged else { return }
            state.cancelQueuedWork()
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
            $0.selectRules()
            $0.cancelQueuedWork()
        }
    }

    func nextAction() -> ActionDispatch? {
        state.withLock {
            // An unclaimed stale request can be discarded immediately. A native
            // request already accepted must finish before another action starts.
            if let request = $0.workspaceRequest, !$0.workspaceClaimed,
               !$0.dispatchIsCurrent(request.dispatch) { $0.workspaceRequest = nil }
            guard $0.canDispatch, $0.workspaceRequest == nil else { return nil }
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

    /// Checked for every event the tap passes on; empty unless a modifier rule is held.
    var virtualModifiers: ModifierSet { state.withLock { $0.held.isEmpty ? [] : $0.virtualModifiers } }

    /// The wheel change for an event Rebind passes through, or nil while rules are not running.
    var wheelAdjustment: WheelAdjustment? {
        state.withLock { $0.activeWheelAdjustment }
    }

    func setPointerApplication(_ bundleIdentifier: String?) {
        state.withLock {
            guard $0.pointerBundleID != bundleIdentifier else { return }
            $0.pointerBundleID = bundleIdentifier
            $0.smoothScrollingRevision &+= 1
        }
    }

    /// Smooth scrolling for a wheel event from this sender, or nil when it is off here.
    func smoothScrolling(sender: UInt64?) -> SmoothScrollingSettings? {
        state.withLock { $0.activeSmoothScrolling(sender: sender) }
    }

    func smoothScrollDispatch(sender: UInt64?) -> SmoothScrollDispatch? {
        state.withLock {
            guard let sender, let settings = $0.activeSmoothScrolling(sender: sender) else { return nil }
            return SmoothScrollDispatch(sender: sender, revision: $0.smoothScrollingRevision, settings: settings)
        }
    }

    func smoothScrollIsCurrent(_ dispatch: SmoothScrollDispatch) -> Bool {
        state.withLock {
            $0.smoothScrollingRevision == dispatch.revision
                && $0.activeSmoothScrolling(sender: dispatch.sender) == dispatch.settings
        }
    }

    func setSmoothScrolling(bySender settings: [UInt64: SmoothScrollingSettings]) {
        state.withLock {
            guard $0.smoothScrollingBySender != settings else { return }
            $0.smoothScrollingBySender = settings
            $0.smoothScrollingRevision &+= 1
        }
    }

    func nextHeldKey(at now: UInt64) -> HeldKeyCommand? { state.withLock { $0.nextHeldKey(at: now) } }

    /// Serializes worker posting with the final quit drain. The state lock is released before
    /// posting; quitting cannot send an up before an already-dequeued down is delivered.
    @discardableResult func deliverNextHeldKey(at now: UInt64, send: (HeldKeyCommand) -> Void) -> Bool {
        heldKeyDelivery.withLock { _ in
            guard let command = nextHeldKey(at: now) else { return false }
            send(command)
            return true
        }
    }

    func systemTransitionRequested(_ dispatch: ActionDispatch) {
        state.withLock {
            guard $0.actionRevision == dispatch.revision else { return }
            // Do not run already queued work or delayed recognition during the
            // transition to sleep/lock. Keep suppressed press ownership until up.
            $0.diagnostics.stop(clear: true)
            $0.cancelQueuedWork()
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
                $0.pause()
            default: break
            }
        }
    }

    /// Pause takes effect here; a profile change is applied by the UI model, which owns storage.
    func requestControl(_ action: ControlAction, for dispatch: ActionDispatch) {
        state.withLock {
            guard $0.dispatchIsCurrent(dispatch) else { return }
            switch action {
            case .pause:
                $0.cancelQueuedWork()
                $0.pause()
            case .nextProfile: $0.profileStep += 1
            case .previousProfile: $0.profileStep -= 1
            }
        }
    }

    func record(_ request: RecordingRequest?) {
        state.withLock {
            if request != nil { $0.retryID &+= 1 }
            $0.recording = request
            $0.recorded = nil
            $0.cancelQueuedWork()
        }
    }

    func setEditing(_ editing: Bool) {
        state.withLock {
            $0.editing = editing
            $0.cancelQueuedWork()
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
            if pause { $0.pause() }
        }
    }

    func stop() {
        state.withLock {
            $0.stopped = true
            $0.resetCapture(status: .paused)
        }
    }

    /// A press or release of a button that reaches Rebind outside the event tap (the diverted
    /// Logitech gesture button, from the HID report thread). It is matched like a tapped button;
    /// there is no system event to suppress or give back.
    func handleOffTapButton(_ button: UInt32, down: Bool, modifiers: ModifierSet, secureInput: Bool) {
        let now = DispatchTime.now().uptimeNanoseconds
        let event = InputEvent(trigger: .mouseButton(button), modifiers: modifiers, phase: down ? .down : .up,
                               timestamp: now, receivedAt: now)
        _ = handle(event, secureInput: secureInput)
    }

    func handle(_ event: InputEvent, secureInput: Bool) -> Bool {
        guard !event.isSynthetic, !event.trigger.isTrackpad else { return false }
        return state.withLock {
            // Trackpad click rules and configured corner taps replace the click itself.
            if case .mouseButton(let button) = event.trigger, button <= 1, !secureInput,
               $0.consumesTrackpadClick(button: button, event: event) { return true }
            return Self.handleAndDiagnose(event, state: &$0, secureInput: secureInput)
        }
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
        let queuedCount = state.pending.count + state.held.count
        let suppressed = handle(event, state: &state, secureInput: secureInput)
        // A wheel event passed on is reversed or sped up by the tap right after this.
        state.diagnostics.record(event, suppressed: suppressed,
                                 queued: state.pending.count + state.held.count > queuedCount,
                                 adjusted: !suppressed && event.phase == .scroll && state.activeWheelAdjustment != nil)
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
                                            enabled: state.matchesRules, canDispatch: state.hasQueueSpace)
        if decision.emergencyPause {
            state.actionRevision &+= 1
            state.pause()
            state.recording = nil
            state.pending.removeAll(keepingCapacity: true)
            state.cancelHeldOutputs()
            state.trackpadDispatch = nil
            state.diagnostics.stop(clear: true)
            return true
        }
        if event.phase == .up { state.releaseHeldOutput(for: event.trigger) }
        if let action = decision.action {
            if decision.holdsOutput, state.held.count < State.maximumHeldOutputs {
                state.held.append(HeldOutput(trigger: event.trigger, action: action))
            } else if !action.requiresHeldOutput { state.pending.append(action) }
        }
        if decision.suppress { return true }
        if let request = state.recording {
            guard event.phase == .down || event.phase == .scroll, !event.isRepeat else { return false }
            if event.trigger == .key(53) {
                state.recorded = RecordedInput(request: request, input: nil)
            } else {
                let matchesCategory: Bool
                switch (request.target, event.trigger) {
                case (.mouseTrigger, .mouseButton), (.gestureTrigger, .mouseButton),
                     (.buttonScrollTrigger, .mouseButton): matchesCategory = true
                case (.scrollTrigger, .scroll): matchesCategory = true
                case (.keyboardTrigger, .key), (.output, .key), (.tapOutput, .key): matchesCategory = true
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
            if let action = state.matcher.pollHold(at: now, rules: state.rules, enabled: state.matchesRules,
                                                   canDispatch: state.hasQueueSpace) {
                // The trigger is still down, so a held output lasts from here to its release.
                if let holdKey, state.rules[holdKey]?.holdsOutput == true, state.held.count < State.maximumHeldOutputs {
                    state.held.append(HeldOutput(trigger: holdKey.trigger, action: action))
                } else if !action.requiresHeldOutput { state.pending.append(action) }
                if let holdKey, case .mouseButton(let number) = holdKey.trigger {
                    state.diagnostics.append(kind: .button(number), phase: .activation, modifiers: holdKey.modifiers,
                                             outcome: .queued, at: now)
                }
            }
        }
    }

    func cancelHold() { state.withLock { $0.matcher.cancelHold() } }
}
