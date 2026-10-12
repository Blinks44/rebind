import Synchronization

// Pure session orchestration, shared by native capture and synthetic-frame tests.
// An incomplete/uncertain release cannot create a tap. A qualified release can
// survive the native stream's trailing empty arrays during its click check.
nonisolated struct TrackpadTapSession: Sendable {
    private(set) var runtime: TrackpadRuntime
    private(set) var foreground: Int32?
    private var recognizer = ShortContactRecognizer()
    private var gate: TrackpadTapGate
    private var qualifiedGesture: TrackpadTapGesture?
    private var sequence: TrackpadTapSequence?
    private var settled = false
    private var contactInProgress = false
    private var knownNeutral = false

    init(runtime: TrackpadRuntime, foreground: Int32?, startedAt: UInt64) {
        self.runtime = runtime
        self.foreground = foreground
        gate = TrackpadTapGate(startedAt: startedAt)
        sequence = Self.makeSequence(runtime)
    }

    private static func makeSequence(_ runtime: TrackpadRuntime) -> TrackpadTapSequence? {
        TrackpadTapSequence(enabled: runtime.enabledGestures,
                            doubleTapIntervalNanoseconds: runtime.doubleTapIntervalNanoseconds,
                            // Native classification still requires <= 400 ms.
                            // Receipt duration allows the bounded 100 ms dequeue
                            // skew without weakening native contact thresholds.
                            maximumContactDurationNanoseconds: 500_000_000)
    }

    mutating func interrupt(isNeutral: Bool = false) {
        recognizer.interrupt(isNeutral: isNeutral)
        gate.cancel(isNeutral: isNeutral)
        qualifiedGesture = nil
        sequence?.cancel()
        settled = false
        contactInProgress = false
        knownNeutral = isNeutral
    }

    @discardableResult mutating func update(runtime: TrackpadRuntime, foreground: Int32?) -> TrackpadDiagnosticEvent? {
        let event: TrackpadDiagnosticEvent? = self.foreground != foreground ? .targetChanged
            : self.runtime.inputActivity != runtime.inputActivity ? .activityChanged : nil
        if self.runtime != runtime || self.foreground != foreground {
            // A button-up after an observed contact release cancels output, but
            // does not make the idle trackpad unknown. It may emit no more zero
            // frames until the next tap. Never preserve an active/uncertain stroke
            // or neutrality across focus/rule changes.
            let preserveNeutral = knownNeutral && self.runtime.revision == runtime.revision
                && self.runtime.fourFingerShortcut == runtime.fourFingerShortcut
                && self.runtime.threeFingerShortcut == runtime.threeFingerShortcut
                && self.runtime.threeFingerDoubleShortcut == runtime.threeFingerDoubleShortcut
                && self.runtime.fourFingerDoubleShortcut == runtime.fourFingerDoubleShortcut
                && self.runtime.doubleTapIntervalNanoseconds == runtime.doubleTapIntervalNanoseconds
                && self.foreground == foreground
            interrupt(isNeutral: preserveNeutral)
            sequence = Self.makeSequence(runtime)
        }
        self.runtime = runtime
        self.foreground = foreground
        return event
    }

    @discardableResult mutating func consume(_ frame: NativeTrackpadFrame, at now: UInt64) -> TrackpadDiagnosticEvent? {
        guard frame.valid else { interrupt(); return .invalidFrame }
        guard frame.revision == runtime.revision else { interrupt(); return .obsoleteFrame }
        guard frame.receipt <= now else { interrupt(); return .futureReceipt }
        guard now - frame.receipt <= 100_000_000 else { interrupt(); return .staleFrame }
        guard frame.activity == runtime.inputActivity else {
            // Mouse-up can advance activity after a release was buffered but
            // before it is consumed. That release cannot qualify output, yet
            // its fresh zero-contact observation still rearms the next stroke.
            // Idle devices need not emit a second release with the new counter.
            interrupt(isNeutral: frame.count == 0)
            return .obsoleteFrame
        }
        if frame.count > 0, knownNeutral {
            // A contact starting after the pair deadline cancels the older
            // single instead of replaying it into an already active gesture.
            _ = sequence?.beginContact(at: frame.receipt)
            contactInProgress = true
        }
        knownNeutral = frame.count == 0
        gate.contacts(frame.count, at: frame.receipt, buttons: frame.activity, observerReady: true)
        if frame.count > 0 { qualifiedGesture = nil; settled = false }
        guard let nativeFrame = frame.frame, let nativeTime = frame.time else {
            guard frame.count == 0 else { interrupt(); return .invalidFrame }
            if contactInProgress { interrupt(isNeutral: frame.count == 0) }
            recognizer.interrupt(isNeutral: true)
            gate.emptyFrame(at: frame.receipt, buttons: frame.activity, observerReady: true)
            return gate.takeCancellation().map { .gate($0) }
        }
        let continuity = recognizer.continuity
        let candidate = recognizer.consume(frame: nativeFrame, time: nativeTime, contacts: frame.contacts,
                                           allowIdleFrameGaps: qualifiedGesture == nil && sequence?.hasPending != true)
        if continuity != recognizer.continuity { interrupt(isNeutral: frame.count == 0) }
        if let candidate, let tap = TrackpadSingleTap(rawValue: candidate.fingers),
           runtime.recognizes(tap), let origin = recognizer.origin,
           gate.candidate(fingers: candidate.fingers, at: frame.receipt,
                          buttons: frame.activity, observerReady: true) {
            guard foreground != nil else { interrupt(isNeutral: true); return .targetChanged }
            // Retain a preliminary pair, but never dispatch before the final
            // release's independent 60 ms click settling. Activity cancels both.
            let results = sequence?.finishContact(.init(fingers: candidate.fingers, x: origin.x, y: origin.y),
                                                  at: frame.receipt, buttonActivityUnchanged: true) ?? []
            contactInProgress = false
            settled = false
            // The native mailbox owns one bounded slot. Drop an older fallback
            // on a mismatched pair; only this release's identity is admissible.
            qualifiedGesture = results.compactMap(TrackpadTapGesture.init).last.flatMap { gesture in
                let admissible: TrackpadTapGesture = runtime.shortcut(for: .double(tap)) == nil ? .single(tap) : .double(tap)
                return gesture == admissible ? gesture : nil
            }
            return .candidate
        }
        if let reason = recognizer.rejection { interrupt(isNeutral: frame.count == 0); return .recognition(reason) }
        if frame.count == 0, contactInProgress || candidate != nil {
            let reason = gate.rejection
            interrupt(isNeutral: true)
            if let reason { return .gate(reason) }
        }
        return gate.takeCancellation().map { .gate($0) }
    }

    mutating func consumeBufferedFrames(from buffer: NativeTrackpadBuffer, clock: () -> UInt64,
                                       diagnose: (TrackpadDiagnosticEvent) -> Void = { _ in }) {
        // The producer remains active while the consumer drains. Sample after
        // each dequeue instead of comparing fresh receipts with poll-entry time.
        // Bound a turn even when the producer keeps adding frames.
        for _ in 0..<64 {
            if buffer.takeOverflow() { interrupt(); diagnose(.overflow); return }
            guard let frame = buffer.pop() else { break }
            diagnose(.frame)
            let now = clock()
            if frame.receipt <= now { diagnose(.frameAge(nanoseconds: now - frame.receipt)) }
            if let event = consume(frame, at: now) { diagnose(event) }
        }
        // Loss can occur after the last dequeue, including at the turn limit.
        if buffer.takeOverflow() { interrupt(); diagnose(.overflow) }
    }

    /// Returns the exact qualified preset only after the atomic buffer readiness check.
    mutating func takeReadyTap(from buffer: NativeTrackpadBuffer, at now: UInt64,
                              diagnose: (TrackpadDiagnosticEvent) -> Void = { _ in }) -> TrackpadSingleTap? {
        guard case .single(let tap) = takeReadyGesture(from: buffer, at: now, diagnose: diagnose) else { return nil }
        return tap
    }

    mutating func takeReadyGesture(from buffer: NativeTrackpadBuffer, at now: UInt64,
                                  diagnose: (TrackpadDiagnosticEvent) -> Void = { _ in }) -> TrackpadTapGesture? {
        // Commit readiness against the producer in one bounded critical section;
        // clocks, diagnostics and mailbox operations remain outside this lock.
        var result: TrackpadTapGesture?
        let decision = buffer.state.withLock { state -> Bool in
            if state.overflow { state.clear(); interrupt(); return true }
            guard state.accepting else { interrupt(); return false }
            guard state.count == 0 else { return false }
            result = takeReadyGesture(at: now)
            return false
        }
        if decision { diagnose(.overflow) }
        return result
    }

    /// Consumes a ready tap only while the accepting buffer is empty and has no unacknowledged loss.
    mutating func takeReady(from buffer: NativeTrackpadBuffer, at now: UInt64,
                            diagnose: (TrackpadDiagnosticEvent) -> Void = { _ in }) -> Bool {
        takeReadyGesture(from: buffer, at: now, diagnose: diagnose) != nil
    }

    mutating func takeCancellation() -> TrackpadDiagnosticEvent? { gate.takeCancellation().map { .gate($0) } }

    mutating func takeReady(at now: UInt64) -> Bool {
        takeReadyGesture(at: now) != nil
    }

    mutating func takeReadyGesture(at now: UInt64) -> TrackpadTapGesture? {
        if !settled {
            if gate.takeReady(at: now, buttons: runtime.inputActivity, observerReady: true) {
                settled = true
            } else {
                if !gate.hasPending, !contactInProgress {
                    sequence?.cancel()
                    qualifiedGesture = nil
                }
                return nil
            }
        }
        if qualifiedGesture == nil {
            qualifiedGesture = sequence?.poll(at: now).first.flatMap(TrackpadTapGesture.init)
        }
        guard let result = qualifiedGesture else { return nil }
        qualifiedGesture = nil
        settled = false
        return result
    }
}
