import Synchronization
import Foundation

/// Synchronous ownership of source-attributed mouse presses and phased scrolling.
/// Contact observation and resolution are serialized by EngineMailbox's lock.
nonisolated struct MagicMouseNativeFilter: Sendable {
    private var sources: Set<UInt64> = []
    private var contact: (count: Int, receipt: UInt64, revision: UInt64)?
    private var armedAt: UInt64?
    private var stroke: UInt64 = 0
    private var touching = false
    private var firedStroke: UInt64?
    private var passedStroke: UInt64?
    private var leftOwner: UInt64?
    private var rightOwner: UInt64?
    private var scrollOwner: UInt64?
    private var lastScrollAt: UInt64?

    func containsSource(_ sender: UInt64?) -> Bool { sender.map(sources.contains) ?? false }

    var hasOwnedInput: Bool { leftOwner != nil || rightOwner != nil || scrollOwner != nil }

    /// New capture needs fresh contacts; already consumed input keeps its trailing events.
    mutating func begin(sources: Set<UInt64>, at now: UInt64) {
        self.sources = sources
        if let leftOwner, !sources.contains(leftOwner) { self.leftOwner = nil }
        if let rightOwner, !sources.contains(rightOwner) { self.rightOwner = nil }
        if let scrollOwner, !sources.contains(scrollOwner) { self.scrollOwner = nil }
        invalidateContacts()
        armedAt = now.addingReportingOverflow(TrackpadTapGate.armingDelay).overflow ? nil : now + TrackpadTapGate.armingDelay
    }

    mutating func invalidateContacts() { contact = nil; touching = false; armedAt = nil }

    mutating func observe(_ frame: NativeTrackpadFrame) {
        guard frame.valid else { contact = nil; return }
        if frame.count > 0, !touching { stroke &+= 1 }
        touching = frame.count > 0
        contact = (frame.count, frame.receipt, frame.revision)
    }

    private func count(sender: UInt64, revision: UInt64, at now: UInt64) -> Int? {
        guard sources.contains(sender), let armedAt, now >= armedAt, let contact,
              contact.revision == revision, now >= contact.receipt, now - contact.receipt <= 100_000_000 else { return nil }
        return contact.count
    }

    /// Only a matched down acquires ownership; its release/drag survives rule/context changes.
    mutating func click(sender: UInt64?, button: UInt32, phase: InputEvent.Phase,
                        revision: UInt64, at now: UInt64, admit: () -> Bool) -> Bool {
        guard let sender, button <= 1 else { return false }
        let owner = button == 0 ? leftOwner : rightOwner
        if owner == sender {
            if phase == .up {
                if button == 0 { leftOwner = nil } else { rightOwner = nil }
            }
            return true
        }
        guard phase == .down, owner == nil, count(sender: sender, revision: revision, at: now) == 3,
              admit() else { return false }
        if button == 0 { leftOwner = sender } else { rightOwner = sender }
        return true
    }

    /// No momentum is guaranteed after Ended. Release dormant ownership without idle polling.
    mutating func expireScroll(at now: UInt64) {
        if let lastScrollAt, now < lastScrollAt || now - lastScrollAt > 1_000_000_000 {
            scrollOwner = nil
            self.lastScrollAt = nil
        }
    }

    /// A stream that began ambiguously is passed in full. Never take over at a changed event.
    /// Momentum remains owned after fingers lift; another device never shares that ownership.
    mutating func scroll(sender: UInt64?, phase: Int64, momentum: Int64,
                         direction: ScrollDirection?, revision: UInt64, at now: UInt64,
                         admit: (ScrollDirection) -> Bool) -> Bool {
        guard let sender, sources.contains(sender) || scrollOwner == sender else { return false }
        expireScroll(at: now)
        if phase & 1 != 0 {
            if firedStroke == stroke, touching {
                scrollOwner = sender
                lastScrollAt = now
                return true
            }
            scrollOwner = nil
            guard let direction, count(sender: sender, revision: revision, at: now) == 2,
                  firedStroke != stroke, passedStroke != stroke, admit(direction) else {
                passedStroke = stroke
                return false
            }
            scrollOwner = sender
            lastScrollAt = now
            firedStroke = stroke
            return true
        }
        if scrollOwner == sender {
            lastScrollAt = now
            if momentum == 3 || phase & 8 != 0 { scrollOwner = nil }
            return true
        }
        return false
    }
}

extension EngineMailbox {
    /// Runs before the conventional wheel adapter; no UI, registry access or event posting.
    nonisolated func handleMagicMouseScroll(sender: UInt64?, phase: Int64, momentum: Int64,
                                             direction: ScrollDirection?, modifiers: ModifierSet,
                                             at now: UInt64, secureInput: Bool) -> Bool {
        let consumed = state.withLock { state in
            let actionRules = state.rules
            let active = !secureInput && state.canDispatch && state.foregroundPID != nil && state.hasQueueSpace
            var queued: RebindAction?
            let consumed = state.magicMouseNative.scroll(sender: sender, phase: phase, momentum: momentum,
                direction: direction, revision: state.actionRevision, at: now) { direction in
                    guard active, let action = actionRules[MatchKey(trigger: .magicMouseScroll(direction), modifiers: modifiers)]?.action else { return false }
                    queued = action
                    return true
                }
            if let queued { state.pending.append(queued) }
            if consumed {
                state.inputActivity &+= 1
                state.magicMouseActivity &+= 1
                state.trackpadDispatch = nil
                state.matcher.cancelHold()
            }
            return consumed
        }
        if consumed { signalWork() }
        return consumed
    }
}
