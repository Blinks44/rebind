import Synchronization
import Foundation

/// Mouse-specific limits around the shared short-contact classifier and release gate.
/// Contacts never suppress native input; loss/other input cancels instead of replaying output.
nonisolated struct MagicMouseTapSession: Sendable {
    private(set) var runtime: MagicMouseRuntime
    private(set) var foreground: Int32?
    private var recognizer = ShortContactRecognizer(surface: .magicMouse)
    private var gate: TrackpadTapGate
    private var pending: Int?
    private var neutral = false
    private var contactStartedAt: UInt64?

    init(runtime: MagicMouseRuntime, foreground: Int32?, startedAt: UInt64) {
        self.runtime = runtime
        self.foreground = foreground
        gate = TrackpadTapGate(startedAt: startedAt)
    }

    mutating func interrupt(isNeutral: Bool = false) {
        recognizer.interrupt(isNeutral: isNeutral)
        gate.cancel(isNeutral: isNeutral)
        pending = nil
        contactStartedAt = nil
        neutral = isNeutral
    }

    mutating func update(runtime: MagicMouseRuntime, foreground: Int32?) {
        if self.runtime != runtime || self.foreground != foreground {
            // Activity after a known lift cannot revive output, but idle surfaces need
            // not emit another empty frame before the next stroke.
            interrupt(isNeutral: neutral && self.runtime.revision == runtime.revision && self.foreground == foreground)
        }
        self.runtime = runtime
        self.foreground = foreground
    }

    mutating func consume(_ frame: NativeTrackpadFrame, at now: UInt64) {
        guard frame.valid, frame.revision == runtime.revision, frame.receipt <= now,
              now - frame.receipt <= 100_000_000 else { interrupt(); return }
        guard !runtime.buttonsDown, frame.activity == runtime.activity else {
            interrupt(isNeutral: frame.count == 0)
            return
        }
        if frame.count > 0, neutral { contactStartedAt = frame.receipt }
        neutral = frame.count == 0
        gate.contacts(frame.count, at: frame.receipt, buttons: frame.activity, observerReady: true)
        if frame.count > 0 { pending = nil }
        guard let nativeFrame = frame.frame, let time = frame.time else {
            // Untimed empty arrays may preserve an already qualified release only.
            if frame.count == 0 {
                if contactStartedAt != nil { interrupt(isNeutral: true); return }
                recognizer.interrupt(isNeutral: true)
                gate.emptyFrame(at: frame.receipt, buttons: frame.activity, observerReady: true)
            } else { interrupt() }
            return
        }
        let continuity = recognizer.continuity
        let candidate = recognizer.consume(frame: nativeFrame, time: time, contacts: frame.contacts)
        if continuity != recognizer.continuity { interrupt(isNeutral: frame.count == 0); return }
        if let candidate, let start = contactStartedAt, frame.receipt >= start,
           (20_000_000...300_000_000).contains(frame.receipt - start),
           (1...2).contains(candidate.fingers), runtime.actions[candidate.fingers] != nil,
           foreground != nil,
           gate.candidate(fingers: candidate.fingers, at: frame.receipt, buttons: frame.activity, observerReady: true) {
            pending = candidate.fingers
            contactStartedAt = nil
        } else if recognizer.rejection != nil || frame.count == 0 && candidate != nil {
            interrupt(isNeutral: frame.count == 0)
        }
    }

    mutating func consumeBufferedFrames(from buffer: NativeTrackpadBuffer, clock: () -> UInt64) {
        for _ in 0..<64 {
            if buffer.takeOverflow() { interrupt(); return }
            guard let frame = buffer.pop() else { break }
            consume(frame, at: clock())
        }
        if buffer.takeOverflow() { interrupt() }
    }

    mutating func takeReady(from buffer: NativeTrackpadBuffer, at now: UInt64) -> Int? {
        buffer.state.withLock {
            if $0.overflow { $0.clear(); interrupt(); return nil }
            guard $0.accepting else { interrupt(); return nil }
            guard $0.count == 0, !runtime.buttonsDown,
                  gate.takeReady(at: now, buttons: runtime.activity, observerReady: true) else { return nil }
            defer { pending = nil }
            return pending
        }
    }
}
