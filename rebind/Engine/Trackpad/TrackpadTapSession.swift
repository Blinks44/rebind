// Pure session orchestration, shared by native capture and synthetic-frame tests.
// An incomplete/uncertain release cannot create a tap. A qualified release can
// survive the native stream's trailing empty arrays during its click check.
nonisolated struct TrackpadTapSession: Sendable {
    private(set) var runtime: TrackpadRuntime
    private(set) var foreground: Int32?
    private var recognizer = ShortContactRecognizer()
    private var gate: FourFingerTapGate
    private var qualified = false

    init(runtime: TrackpadRuntime, foreground: Int32?, startedAt: UInt64) {
        self.runtime = runtime
        self.foreground = foreground
        gate = FourFingerTapGate(startedAt: startedAt)
    }

    mutating func interrupt() {
        recognizer.interrupt()
        gate.cancel()
        qualified = false
    }

    mutating func update(runtime: TrackpadRuntime, foreground: Int32?) {
        if self.runtime != runtime || self.foreground != foreground { interrupt() }
        self.runtime = runtime
        self.foreground = foreground
    }

    mutating func consume(_ frame: NativeTrackpadFrame, at now: UInt64) {
        guard frame.valid, frame.revision == runtime.revision, frame.activity == runtime.inputActivity,
              frame.receipt <= now, now - frame.receipt <= 100_000_000 else { interrupt(); return }
        gate.contacts(frame.count, at: frame.receipt, buttons: frame.activity, observerReady: true)
        if frame.count > 0 { qualified = false }
        guard let nativeFrame = frame.frame, let nativeTime = frame.time else {
            recognizer.interrupt(isNeutral: true)
            gate.emptyFrame(at: frame.receipt, buttons: frame.activity, observerReady: true)
            return
        }
        let continuity = recognizer.continuity
        let candidate = recognizer.consume(frame: nativeFrame, time: nativeTime, contacts: frame.contacts,
                                           allowIdleFrameGaps: !qualified)
        if continuity != recognizer.continuity { gate.cancel(isNeutral: frame.count == 0); qualified = false }
        if let candidate,
           gate.candidate(fingers: candidate.fingers, at: frame.receipt,
                          buttons: frame.activity, observerReady: true), foreground != nil { qualified = true }
    }

    mutating func takeReady(at now: UInt64) -> Bool {
        guard gate.takeReady(at: now, buttons: runtime.inputActivity, observerReady: true) else { return false }
        defer { qualified = false }
        return qualified
    }
}
