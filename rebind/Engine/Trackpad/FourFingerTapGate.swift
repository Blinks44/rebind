// Conservative reusable settling gate; it cannot suppress system gestures.
// A button-free interval is a conservative test condition, not source proof.
nonisolated struct FourFingerTapGate: Sendable {
    enum Reason: String, Encodable, Sendable {
        case buttonEvent = "button-event", newContact = "new-contact"
        case observerUnavailable = "observer-unavailable", invalidContacts = "invalid-contacts"
        case receiptTime = "invalid-receipt-time", nativeTime = "invalid-native-time"
        case frameGap = "frame-gap", invalidMetadata = "invalid-metadata"
        case foregroundChanged = "foreground-changed", targetUnavailable = "target-unavailable"
        case noCompleteStroke = "no-complete-stroke", otherFingerCount = "other-finger-count"
        case armingDelay = "arming-delay", deadlineOverflow = "deadline-overflow"
        case latePoll = "late-poll", consumed = "already-consumed", sessionEnded = "session-ended"
    }
    static let armingDelay: UInt64 = 3_000_000_000
    // The hardware probe saw a native button-down 12 ms after lift (up at
    // 28 ms). Keep a short exclusion window, not a double-tap-sized delay.
    // This is a hardware-tuned guard, not proof of universal click separation.
    static let settlingDelay: UInt64 = 60_000_000
    static let maximumLateness: UInt64 = 100_000_000

    private let startedAt: UInt64
    private var lastTime: UInt64?
    private var lastPollTime: UInt64?
    private var neutral = false
    private var inContact = false
    private var strokeButtons: UInt64?
    private var completedButtons: UInt64?
    private var pendingButtons: UInt64?
    private var pendingAt: UInt64?
    private(set) var rejection: Reason?
    private var cancellation: Reason?
    var hasPending: Bool { pendingAt != nil }

    init(startedAt: UInt64) { self.startedAt = startedAt }

    mutating func contacts(_ count: Int?, at time: UInt64, buttons: UInt64, observerReady: Bool) {
        guard validTime(time) else { return }
        guard observerReady else { cancel(reason: .observerUnavailable); return }
        guard let count, (0...16).contains(count) else { cancel(reason: .invalidContacts); return }
        if count == 0 {
            if inContact {
                completedButtons = strokeButtons == buttons ? buttons : nil
                strokeButtons = nil
                inContact = false
            }
            neutral = true
        } else {
            if hasPending { cancellation = .newContact }
            pendingAt = nil
            pendingButtons = nil
            completedButtons = nil
            if !inContact { strokeButtons = neutral ? buttons : nil }
            if strokeButtons != buttons { strokeButtons = nil }
            inContact = true
            neutral = false
        }
    }

    // Zero native contacts are still a known neutral observation. They cannot
    // finish an unqualified stroke (no native time/ID), but do not invalidate a
    // candidate already completed on a timestamped, consecutive release frame.
    mutating func emptyFrame(at time: UInt64, buttons: UInt64, observerReady: Bool) {
        contacts(0, at: time, buttons: buttons, observerReady: observerReady)
        completedButtons = nil
    }

    mutating func candidate(fingers: Int, at time: UInt64, buttons: UInt64, observerReady: Bool) -> Bool {
        defer { completedButtons = nil }
        rejection = nil
        guard validTime(time) else { rejection = .receiptTime; return false }
        guard observerReady else { rejection = .observerUnavailable; return false }
        guard neutral, !inContact, buttons == completedButtons else { rejection = .noCompleteStroke; return false }
        guard fingers == 4 else { rejection = .otherFingerCount; return false }
        guard time - startedAt >= Self.armingDelay else { rejection = .armingDelay; return false }
        guard time <= UInt64.max - Self.settlingDelay else { rejection = .deadlineOverflow; return false }
        pendingAt = time
        pendingButtons = buttons
        return true
    }

    mutating func takeReady(at time: UInt64, buttons: UInt64, observerReady: Bool) -> Bool {
        // Receipt ordering and consumer polling are different timelines. A
        // callback queued just before this check may be consumed next poll.
        // Advancing the receipt clock here would reject that fresh callback.
        guard time >= startedAt, lastTime.map({ time >= $0 }) ?? true,
              lastPollTime.map({ time >= $0 }) ?? true else {
            cancel(reason: .receiptTime)
            return false
        }
        lastPollTime = time
        guard observerReady else { cancel(reason: .observerUnavailable); return false }
        guard let pendingAt else { return false }
        guard neutral, !inContact else { cancel(reason: .newContact); return false }
        guard buttons == pendingButtons else { cancel(reason: .buttonEvent); return false }
        guard time - pendingAt >= Self.settlingDelay else { return false }
        let late = time - pendingAt - Self.settlingDelay
        guard late <= Self.maximumLateness else { cancel(reason: .latePoll); return false }
        self.pendingAt = nil
        pendingButtons = nil
        return true
    }

    mutating func cancel(reason: Reason = .sessionEnded, isNeutral: Bool = false) {
        if hasPending { cancellation = reason }
        neutral = isNeutral
        inContact = false
        strokeButtons = nil
        completedButtons = nil
        pendingButtons = nil
        pendingAt = nil
    }

    mutating func takeCancellation() -> Reason? {
        defer { cancellation = nil }
        return cancellation
    }

    private mutating func validTime(_ time: UInt64) -> Bool {
        guard time >= startedAt, lastTime.map({ time >= $0 }) ?? true else { cancel(reason: .receiptTime); return false }
        lastTime = time
        return true
    }
}
