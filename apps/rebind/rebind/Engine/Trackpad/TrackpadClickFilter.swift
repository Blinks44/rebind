// Decides, on the event-tap path, which trackpad clicks a rule replaces.
//
// Tap to click: macOS turns a tap into a click that arrives after the fingers lift
// (a one-finger tap into a primary click, a two-finger tap into a secondary click).
// No finger touches the surface when it arrives, so it is not a physical press: it
// must not cancel a light-tap rule the way a real click does. For a one-finger tap
// inside a corner that has an enabled rule, the click is consumed so the rule
// (dispatched by the tap session) replaces it. A qualified three-finger tap rule
// also replaces its native Touch primary click, including while a double-tap pair
// waits. That narrower path validates per-finger motion/identity/continuity and
// capture arming/revision/activity; it never consumes other mouse subtypes.
//
// Physical clicks: a press while 2–4 fingers rest on the surface runs the matching
// click rule instead of the click. Two fingers count only for the secondary button,
// which is macOS's own decision that the press was a two-finger click rather than a
// click with a resting thumb.
//
// Three-finger drag: macOS also presses the button by itself about half a second
// after three or four fingers come to rest, and releases it when they lift. That
// press looks exactly like a physical one, so a three/four-finger rule runs only for
// a deliberate press: on a Force Touch surface, finger force at the press; elsewhere
// (a Magic Trackpad reports no force here), a still press soon after the fingers land.
//
// Thresholds mirror ShortContactRecognizer or come from the click probe (INPUT-013,
// one built-in trackpad and one Magic Trackpad); they need wider hardware confirmation.
nonisolated struct TrackpadClickFilter: Sendable {
    /// `tapClick` passes the click on, but it is not physical input activity.
    enum Decision: Equatable, Sendable { case pass, consume, tapClick, run(fingers: Int) }

    static let tapClickWindow: UInt64 = 350_000_000
    static let maximumFrameAge: UInt64 = 100_000_000
    /// Probe: resting fingers peaked at 59, physical presses measured 129–295.
    static let pressForce: Float = 90
    /// Probe: macOS pressed for resting fingers after 495–538 ms; physical presses came at 104–291 ms.
    static let maximumRestBeforePress: UInt64 = 400_000_000

    private struct Stroke: Sendable {
        let started: Double
        let startedAt: UInt64
        let id: Int32
        let x: Float
        let y: Float
        var frames = 1
        var fingers: Int
        /// One stationary finger: the only stroke that can be a corner tap.
        var valid: Bool
        /// Where each finger (at most four) first touched, to notice a drag.
        var origins: NativeTrackpadFrame
        var moved = false
        var tapValid = true
        var peakFrames = 1
        var firstLift: Double?
        var last: NativeTrackpadFrame
        var peakForce: Float

        func continues(with frame: NativeTrackpadFrame) -> Bool {
            guard let previousID = last.frame, let id = frame.frame,
                  let previousTime = last.time, let time = frame.time else { return false }
            return Int64(id) == Int64(previousID) + 1 && time > previousTime && time - previousTime <= 0.05
                && frame.revision == last.revision && frame.activity == last.activity
        }
    }

    private var stroke: Stroke?
    private var neutral = false
    private var release: (corner: TrackpadCorner?, tapFingers: Int?, at: UInt64, revision: UInt64, activity: UInt64)?
    private var touching: (count: Int, at: UInt64, force: Float)?
    private var reportsForce = false
    private var tapReplacementStartsAt: UInt64?
    private var consumedButton: UInt32?
    private var tapClickButton: UInt32?

    /// Restart tap attribution with the session's independent three-second arming gate.
    /// Keep ownership of already swallowed button releases across capture restarts.
    mutating func beginCapture(at now: UInt64) {
        stroke = nil
        neutral = false
        release = nil
        touching = nil
        tapReplacementStartsAt = now <= UInt64.max - TrackpadTapGate.armingDelay
            ? now + TrackpadTapGate.armingDelay : nil
    }

    func canReplaceThreeFingerTap(revision: UInt64, activity: UInt64, at now: UInt64) -> Bool {
        guard let tapReplacementStartsAt, now >= tapReplacementStartsAt, let release else { return false }
        return release.revision == revision && release.activity == activity
    }

    /// Whether a recent frame shows fingers on this surface.
    func isTouching(at now: UInt64) -> Bool {
        guard let touching, touching.count > 0, now >= touching.at else { return false }
        return now - touching.at <= Self.maximumFrameAge
    }

    /// Bounded per-frame bookkeeping for the native contact callback.
    mutating func observe(_ frame: NativeTrackpadFrame, reportsForce: Bool = false) {
        self.reportsForce = reportsForce
        var force: Float = 0
        frame.forEachContact { force = max(force, $0.pressure) }
        touching = frame.valid ? (frame.count, frame.receipt, force) : nil
        guard frame.valid, let time = frame.time else {
            stroke = nil
            neutral = frame.valid && frame.count == 0
            if !neutral { release = nil }
            return
        }
        guard frame.count > 0, let contact = frame.first else {
            if let stroke, stroke.frames >= 2, (0.03...0.4).contains(time - stroke.started) {
                let tapValid = stroke.tapValid && !stroke.moved && stroke.peakFrames >= 2
                    && stroke.origins.count == stroke.fingers && stroke.continues(with: frame)
                    && (stroke.firstLift.map { time - $0 <= 0.15 } ?? true)
                    && (!reportsForce || stroke.peakForce < Self.pressForce)
                release = (stroke.valid ? TrackpadCorner.containing(x: stroke.x, y: stroke.y) : nil,
                           tapValid ? stroke.fingers : nil, frame.receipt, frame.revision, frame.activity)
            }
            stroke = nil
            neutral = true
            return
        }
        release = nil
        guard var current = stroke else {
            if neutral {
                stroke = Stroke(started: time, startedAt: frame.receipt, id: contact.id, x: contact.x, y: contact.y,
                                fingers: frame.count, valid: frame.count == 1, origins: frame, last: frame, peakForce: force)
            }
            neutral = false
            return
        }
        if !current.continues(with: frame) { current.tapValid = false }
        current.last.forEachContact { previous in
            if frame.contact(previous.id) == nil, current.firstLift == nil { current.firstLift = time }
        }
        if current.firstLift != nil, frame.count > current.last.count { current.tapValid = false }
        if frame.count > current.fingers { current.peakFrames = 0 }
        if frame.count >= current.fingers { current.peakFrames += 1 }
        let dx = contact.x - current.x, dy = contact.y - current.y
        if frame.count != 1 || contact.id != current.id || dx * dx + dy * dy > 0.04 * 0.04 { current.valid = false }
        frame.forEachContact { contact in
            if let origin = current.origins.contact(contact.id) {
                let dx = contact.x - origin.x, dy = contact.y - origin.y
                if dx * dx + dy * dy > 0.04 * 0.04 { current.moved = true }
            } else {
                if time - current.started > 0.15 || current.firstLift != nil || current.origins.count >= 4 {
                    current.tapValid = false
                }
                current.origins.add(contact)
            }
        }
        current.fingers = max(current.fingers, frame.count)
        current.frames += 1
        current.last = frame
        current.peakForce = max(current.peakForce, force)
        stroke = current
    }

    /// Whether a press with three or four fingers is the user's, not three-finger drag's.
    private func isDeliberatePress(at now: UInt64) -> Bool {
        if reportsForce { return (touching?.force ?? 0) >= Self.pressForce }
        guard let stroke, !stroke.moved, now >= stroke.startedAt else { return false }
        return now - stroke.startedAt < Self.maximumRestBeforePress
    }

    /// Resolves one primary/secondary button event. A consumed press also consumes its drags and release.
    mutating func resolve(button: UInt32, phase: InputEvent.Phase, at now: UInt64,
                          hasCornerRule: (TrackpadCorner) -> Bool, hasClickRule: (Int) -> Bool,
                          replacesThreeFingerTap: Bool = false) -> Decision {
        switch phase {
        case .up:
            if tapClickButton == button { tapClickButton = nil; return .tapClick }
            guard consumedButton == button else { return .pass }
            consumedButton = nil
            return .consume
        case .drag:
            return consumedButton == button ? .consume : .pass
        case .down:
            defer { release = nil }
            consumedButton = nil
            tapClickButton = nil
            // A press while the finger is down is a physical click, not a tap.
            stroke?.valid = false
            stroke?.tapValid = false
            if stroke == nil, neutral, let release, now >= release.at, now - release.at <= Self.tapClickWindow {
                let replacesCorner = button == 0 && release.corner.map(hasCornerRule) == true
                let replacesTap = button == 0 && release.tapFingers == 3 && replacesThreeFingerTap
                if replacesCorner || replacesTap {
                    consumedButton = button
                    return .consume
                }
                tapClickButton = button
                return .tapClick
            }
            guard let touching, now >= touching.at, now - touching.at <= Self.maximumFrameAge,
                  touching.count == 2 ? button == 1 : (3...4).contains(touching.count),
                  hasClickRule(touching.count), touching.count == 2 || isDeliberatePress(at: now) else { return .pass }
            consumedButton = button
            return .run(fingers: touching.count)
        default:
            return .pass
        }
    }
}

// Fixed slots, no arrays: this runs in the native contact callback.
nonisolated private extension NativeTrackpadFrame {
    func forEachContact(_ body: (ShortContactRecognizer.Contact) -> Void) {
        if let first { body(first) }
        if let second { body(second) }
        if let third { body(third) }
        if let fourth { body(fourth) }
    }

    func contact(_ id: Int32) -> ShortContactRecognizer.Contact? {
        if first?.id == id { return first }
        if second?.id == id { return second }
        if third?.id == id { return third }
        return fourth?.id == id ? fourth : nil
    }

    /// Keeps at most four origins; later fingers beyond that are not tracked.
    mutating func add(_ contact: ShortContactRecognizer.Contact) {
        if first == nil { first = contact } else if second == nil { second = contact }
        else if third == nil { third = contact } else if fourth == nil { fourth = contact }
        else { return }
        count += 1
    }
}

extension EngineMailbox.State {
    /// Runs inside the mailbox lock on the event-tap thread; no I/O, one bounded append.
    /// Returns `consume` for a click a rule replaced, never `run`.
    nonisolated mutating func resolveTrackpadClick(button: UInt32, event: InputEvent) -> TrackpadClickFilter.Decision {
        let active = canDispatch && foregroundPID != nil
        let rules = rules
        func rule(_ trigger: InputTrigger, _ magic: Bool) -> RebindAction? {
            active ? rules[MatchKey(trigger: trigger, modifiers: event.modifiers, isMagicTrackpad: magic)]?.action : nil
        }
        // Only a fresh, stationary, fully released three-finger stroke may explain
        // a native Touch click. Non-Touch events and presses with fingers still down
        // retain passthrough; the Touch subtype is not physical-device attribution.
        let now = event.receivedAt ?? event.timestamp
        let revision = actionRevision, activity = inputActivity
        let canReplaceTap = event.isTouchClick && event.phase == .down
            && !trackpadClicks.isTouching(at: now) && !magicTrackpadClicks.isTouching(at: now)
        func replacesTap(_ magic: Bool) -> Bool {
            canReplaceTap && (rule(.threeFingerTap, magic) != nil || rule(.threeFingerDoubleTap, magic) != nil)
        }
        // Each surface keeps its own contact state; the one that explains the press decides.
        var decision = trackpadClicks.resolve(button: button, phase: event.phase, at: now,
            hasCornerRule: { rule(.cornerTap($0), false) != nil },
            hasClickRule: { rule(.trackpadClick(fingers: $0), false) != nil },
            replacesThreeFingerTap: replacesTap(false)
                && trackpadClicks.canReplaceThreeFingerTap(revision: revision, activity: activity, at: now))
        var magic = false
        if decision == .pass || decision == .tapClick {
            let other = magicTrackpadClicks.resolve(button: button, phase: event.phase, at: now,
                hasCornerRule: { rule(.cornerTap($0), true) != nil },
                hasClickRule: { rule(.trackpadClick(fingers: $0), true) != nil },
                replacesThreeFingerTap: replacesTap(true)
                    && magicTrackpadClicks.canReplaceThreeFingerTap(revision: revision, activity: activity, at: now))
            if other != .pass, other != .tapClick {
                decision = other
                magic = true
            } else if decision == .tapClick || other == .tapClick {
                // A finger on either surface makes the press possibly physical.
                let touched = event.phase == .down
                    && (trackpadClicks.isTouching(at: now) || magicTrackpadClicks.isTouching(at: now))
                decision = touched ? .pass : .tapClick
            }
        }
        guard case .run(let fingers) = decision else { return decision }
        // A press is still real activity: it must cancel any pending light-tap output.
        inputActivity &+= 1
        trackpadDispatch = nil
        if hasQueueSpace, let action = rule(.trackpadClick(fingers: fingers), magic) { pending.append(action) }
        return .consume
    }
}
