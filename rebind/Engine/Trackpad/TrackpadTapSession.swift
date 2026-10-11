import Synchronization

// Pure session orchestration, shared by native capture and synthetic-frame tests.
// An incomplete/uncertain release cannot create a tap. A qualified release can
// survive the native stream's trailing empty arrays during its click check.
nonisolated struct TrackpadTapSession: Sendable {
    private(set) var runtime: TrackpadRuntime
    private(set) var foreground: Int32?
    private var recognizer = ShortContactRecognizer()
    private var gate: FourFingerTapGate
    private var qualified = false
    private var knownNeutral = false

    init(runtime: TrackpadRuntime, foreground: Int32?, startedAt: UInt64) {
        self.runtime = runtime
        self.foreground = foreground
        gate = FourFingerTapGate(startedAt: startedAt)
    }

    mutating func interrupt(isNeutral: Bool = false) {
        recognizer.interrupt(isNeutral: isNeutral)
        gate.cancel(isNeutral: isNeutral)
        qualified = false
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
                && self.runtime.shortcut == runtime.shortcut && self.foreground == foreground
            interrupt(isNeutral: preserveNeutral)
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
        knownNeutral = frame.count == 0
        gate.contacts(frame.count, at: frame.receipt, buttons: frame.activity, observerReady: true)
        if frame.count > 0 { qualified = false }
        guard let nativeFrame = frame.frame, let nativeTime = frame.time else {
            recognizer.interrupt(isNeutral: true)
            gate.emptyFrame(at: frame.receipt, buttons: frame.activity, observerReady: true)
            return gate.takeCancellation().map { .gate($0) }
        }
        let continuity = recognizer.continuity
        let candidate = recognizer.consume(frame: nativeFrame, time: nativeTime, contacts: frame.contacts,
                                           allowIdleFrameGaps: !qualified)
        if continuity != recognizer.continuity { gate.cancel(isNeutral: frame.count == 0); qualified = false }
        if let candidate,
           gate.candidate(fingers: candidate.fingers, at: frame.receipt,
                          buttons: frame.activity, observerReady: true) {
            guard foreground != nil else { gate.cancel(isNeutral: true); return .targetChanged }
            qualified = true
            return .candidate
        }
        if let reason = recognizer.rejection { return .recognition(reason) }
        if candidate != nil, let reason = gate.rejection { return .gate(reason) }
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
            if let event = consume(frame, at: clock()) { diagnose(event) }
        }
        // Loss can occur after the last dequeue, including at the turn limit.
        if buffer.takeOverflow() { interrupt(); diagnose(.overflow) }
    }

    /// Consumes a ready tap only while the accepting buffer is empty and has no unacknowledged loss.
    mutating func takeReady(from buffer: NativeTrackpadBuffer, at now: UInt64,
                            diagnose: (TrackpadDiagnosticEvent) -> Void = { _ in }) -> Bool {
        // Commit readiness against the producer's queue in one short critical
        // section. A queued contact must be consumed before a pending tap fires.
        // Do not call clocks, diagnostics or mailbox operations under this lock.
        let decision = buffer.state.withLock { state -> (ready: Bool, overflow: Bool) in
            if state.overflow {
                state.clear()
                interrupt()
                return (false, true)
            }
            guard state.accepting else { interrupt(); return (false, false) }
            guard state.count == 0 else { return (false, false) }
            return (takeReady(at: now), false)
        }
        if decision.overflow { diagnose(.overflow) }
        return decision.ready
    }

    mutating func takeCancellation() -> TrackpadDiagnosticEvent? { gate.takeCancellation().map { .gate($0) } }

    mutating func takeReady(at now: UInt64) -> Bool {
        guard gate.takeReady(at: now, buttons: runtime.inputActivity, observerReady: true) else { return false }
        defer { qualified = false }
        return qualified
    }
}
