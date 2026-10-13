// Decides, on the event-tap path, which trackpad clicks a rule replaces.
//
// Corner taps: with Tap to click enabled, macOS turns a one-finger tap into a left
// click that arrives after the finger lifts. For a tap inside a corner that has an
// enabled rule, that click is consumed so the rule (dispatched by the tap session)
// replaces it instead of being cancelled by it.
//
// Physical clicks: a press while 2–4 fingers rest on the surface runs the matching
// click rule instead of the click. Two fingers count only for the secondary button,
// which is macOS's own decision that the press was a two-finger click rather than a
// click with a resting thumb.
//
// Thresholds mirror ShortContactRecognizer; both time windows are provisional
// values that need hardware confirmation.
nonisolated struct TrackpadClickFilter: Sendable {
    enum Decision: Equatable, Sendable { case pass, consume, run(fingers: Int) }

    static let tapClickWindow: UInt64 = 350_000_000
    static let maximumFrameAge: UInt64 = 100_000_000

    private struct Stroke: Sendable {
        let started: Double
        let id: Int32
        let x: Float
        let y: Float
        var frames = 1
        var valid: Bool
    }

    private var stroke: Stroke?
    private var neutral = false
    private var release: (corner: TrackpadCorner, at: UInt64)?
    private var touching: (count: Int, at: UInt64)?
    private var consumedButton: UInt32?

    /// Bounded per-frame bookkeeping for the native contact callback.
    mutating func observe(_ frame: NativeTrackpadFrame) {
        touching = frame.valid ? (frame.count, frame.receipt) : nil
        guard frame.valid, let time = frame.time else {
            stroke = nil
            neutral = frame.valid && frame.count == 0
            if !neutral { release = nil }
            return
        }
        guard frame.count > 0, let contact = frame.first else {
            if let stroke, stroke.valid, stroke.frames >= 2, (0.03...0.4).contains(time - stroke.started),
               let corner = TrackpadCorner.containing(x: stroke.x, y: stroke.y) {
                release = (corner, frame.receipt)
            }
            stroke = nil
            neutral = true
            return
        }
        release = nil
        guard var current = stroke else {
            if neutral { stroke = Stroke(started: time, id: contact.id, x: contact.x, y: contact.y, valid: frame.count == 1) }
            neutral = false
            return
        }
        let dx = contact.x - current.x, dy = contact.y - current.y
        if frame.count != 1 || contact.id != current.id || dx * dx + dy * dy > 0.04 * 0.04 { current.valid = false }
        current.frames += 1
        stroke = current
    }

    /// Resolves one primary/secondary button event. A consumed press also consumes its drags and release.
    mutating func resolve(button: UInt32, phase: InputEvent.Phase, at now: UInt64,
                          hasCornerRule: (TrackpadCorner) -> Bool, hasClickRule: (Int) -> Bool) -> Decision {
        switch phase {
        case .up:
            guard consumedButton == button else { return .pass }
            consumedButton = nil
            return .consume
        case .drag:
            return consumedButton == button ? .consume : .pass
        case .down:
            defer { release = nil }
            consumedButton = nil
            // A press while the finger is down is a physical click, not a tap.
            stroke?.valid = false
            if button == 0, stroke == nil, neutral, let release, now >= release.at,
               now - release.at <= Self.tapClickWindow, hasCornerRule(release.corner) {
                consumedButton = button
                return .consume
            }
            guard let touching, now >= touching.at, now - touching.at <= Self.maximumFrameAge,
                  touching.count == 2 ? button == 1 : (3...4).contains(touching.count),
                  hasClickRule(touching.count) else { return .pass }
            consumedButton = button
            return .run(fingers: touching.count)
        default:
            return .pass
        }
    }
}

extension EngineMailbox.State {
    /// Runs inside the mailbox lock on the event-tap thread; no I/O, one bounded append.
    nonisolated mutating func consumesTrackpadClick(button: UInt32, event: InputEvent) -> Bool {
        let active = status == .active && enabled && !editing && !suspended && !stopped
            && recording == nil && foregroundPID != nil
        let rules = rules
        func rule(_ trigger: InputTrigger) -> RebindAction? {
            active ? rules[MatchKey(trigger: trigger, modifiers: [])]?.action : nil
        }
        let decision = trackpadClicks.resolve(button: button, phase: event.phase, at: event.receivedAt ?? event.timestamp,
            hasCornerRule: { rule(.cornerTap($0)) != nil },
            hasClickRule: { rule(.trackpadClick(fingers: $0)) != nil })
        switch decision {
        case .pass: return false
        case .consume: return true
        case .run(let fingers):
            // A press is still real activity: it must cancel any pending light-tap output.
            inputActivity &+= 1
            trackpadDispatch = nil
            if pending.count < 16, let action = rule(.trackpadClick(fingers: fingers)) { pending.append(action) }
            return true
        }
    }
}
