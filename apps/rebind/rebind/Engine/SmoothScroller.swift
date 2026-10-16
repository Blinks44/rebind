import CoreGraphics
import Dispatch
import Foundation
import Synchronization
import Carbon

nonisolated struct SmoothScrollDispatch: Equatable, Sendable {
    let sender: UInt64
    let revision: UInt64
    let settings: SmoothScrollingSettings
}

/// Turns mouse wheel clicks into a short glide of continuous scroll events, as LinearMouse's
/// smoothed scrolling does, with a plain exponential ease-out instead of its velocity model.
/// The tap swallows the click and adds its distance here under a short lock; a dedicated
/// thread posts tagged pixel events at 120 Hz while distance remains and sleeps otherwise.
/// The tap passes tagged events on untouched, so a glide is never matched or adjusted again.
nonisolated final class SmoothScroller: Sendable {
    private struct Glide {
        var remainingX = 0.0
        var remainingY = 0.0
        var timeConstant = SmoothScrollingGlide.standard.timeConstant
        var flags: CGEventFlags = []
        var dispatch: SmoothScrollDispatch?
        var generation: UInt64 = 0

        var isIdle: Bool { remainingX == 0 && remainingY == 0 }
    }

    static let frameInterval = 1.0 / 120
    private let glide = Mutex(Glide())
    private let wake = DispatchSemaphore(value: 0)
    private let mailbox: EngineMailbox

    private init(mailbox: EngineMailbox) { self.mailbox = mailbox }

    /// Starts the posting thread, which lives as long as the process (like the tap thread).
    static func start(mailbox: EngineMailbox) -> SmoothScroller {
        let scroller = SmoothScroller(mailbox: mailbox)
        let thread = Thread { scroller.run() }
        thread.name = "Rebind smooth scrolling"
        thread.qualityOfService = .userInteractive
        thread.start()
        return scroller
    }

    /// Whether the tap should glide this wheel event instead of passing it on.
    static func applies(to event: CGEvent) -> Bool {
        guard ScrollEventAdapter.isMouseWheel(event) else { return false }
        // Zoom and other modified wheel actions keep the original, exact clicks, and so does
        // Shift: apps turn a Shift+wheel click into horizontal scrolling, not a precise glide.
        return event.flags.isDisjoint(with: [.maskCommand, .maskControl, .maskShift])
    }

    /// Adds one wheel event's distance (after reverse and speed). Tap callback: no I/O.
    func feed(_ event: CGEvent, dispatch: SmoothScrollDispatch) {
        let (x, y) = Self.distance(of: event, settings: dispatch.settings)
        let wasIdle = glide.withLock { glide in
            let wasIdle = glide.isIdle
            if glide.dispatch != dispatch { glide = Glide(generation: glide.generation &+ 1) }
            glide.dispatch = dispatch
            glide.remainingX = Self.add(x, to: glide.remainingX)
            glide.remainingY = Self.add(y, to: glide.remainingY)
            glide.timeConstant = dispatch.settings.glide.timeConstant
            glide.flags = event.flags
            return wasIdle
        }
        if wasIdle { wake.signal() }
    }

    /// Points to glide for one event. A stepped click counts its accelerated lines (the fixed-point
    /// delta, already reversed or sped up); a continuous wheel keeps its own points, scaled so that
    /// Standard matches it.
    static func distance(of event: CGEvent, settings: SmoothScrollingSettings) -> (x: Double, y: Double) {
        if event.getIntegerValueField(.scrollWheelEventIsContinuous) != 0 {
            let scale = settings.pointsPerLine / Double(SmoothScrollingDistance.standard)
            return (event.getDoubleValueField(.scrollWheelEventPointDeltaAxis2) * scale,
                    event.getDoubleValueField(.scrollWheelEventPointDeltaAxis1) * scale)
        }
        return (event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis2) * settings.pointsPerLine,
                event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1) * settings.pointsPerLine)
    }

    /// Stops a glide at once, for example when the tap is removed.
    func cancel() { glide.withLock { $0 = Glide(generation: $0.generation &+ 1) } }

    /// A click the other way stops the glide instead of fighting it.
    static func add(_ delta: Double, to remaining: Double) -> Double {
        guard delta.isFinite, remaining.isFinite else { return 0 }
        // Bound malformed/accelerated driver values before conversion to integer pixels.
        let distance = remaining * delta < 0 ? delta : remaining + delta
        return min(max(distance, -100_000), 100_000)
    }

    /// The part of the remaining distance to move in one frame; the last point goes at once.
    static func step(remaining: Double, interval: Double, timeConstant: Double) -> Double {
        abs(remaining) <= 1 ? remaining : remaining * (1 - exp(-interval / timeConstant))
    }

    private func run() {
        while true {
            wake.wait()
            var carryX = 0.0
            var carryY = 0.0
            var dispatch: SmoothScrollDispatch?
            var generation: UInt64?
            var previous = DispatchTime.now().uptimeNanoseconds
            while true {
                Thread.sleep(forTimeInterval: Self.frameInterval)
                let now = DispatchTime.now().uptimeNanoseconds
                let interval = Double(now - previous) / 1_000_000_000
                previous = now
                let frame = glide.withLock { glide -> (x: Double, y: Double, flags: CGEventFlags, dispatch: SmoothScrollDispatch?, generation: UInt64, done: Bool) in
                    let x = Self.step(remaining: glide.remainingX, interval: interval, timeConstant: glide.timeConstant)
                    let y = Self.step(remaining: glide.remainingY, interval: interval, timeConstant: glide.timeConstant)
                    glide.remainingX -= x
                    glide.remainingY -= y
                    return (x, y, glide.flags, glide.dispatch, glide.generation, glide.isIdle)
                }
                if dispatch != frame.dispatch || generation != frame.generation {
                    carryX = 0; carryY = 0; dispatch = frame.dispatch; generation = frame.generation
                }
                guard let current = frame.dispatch, mailbox.smoothScrollIsCurrent(current),
                      !IsSecureEventInputEnabled(), CGPreflightPostEventAccess() else {
                    glide.withLock {
                        if $0.generation == frame.generation { $0 = Glide(generation: $0.generation &+ 1) }
                    }
                    carryX = 0; carryY = 0
                    if glide.withLock({ $0.isIdle }) { break }
                    continue
                }
                // Events carry whole pixels; the fraction moves with the next frame.
                carryX += frame.x
                carryY += frame.y
                let pixelsX = carryX.rounded(.towardZero)
                let pixelsY = carryY.rounded(.towardZero)
                carryX -= pixelsX
                carryY -= pixelsY
                if pixelsX != 0 || pixelsY != 0 { Self.post(x: pixelsX, y: pixelsY, flags: frame.flags) }
                if frame.done { break }
            }
        }
    }

    private static func post(x: Double, y: Double, flags: CGEventFlags) {
        guard let event = CGEvent(scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 2,
                                  wheel1: Int32(clamping: Int(y)), wheel2: Int32(clamping: Int(x)), wheel3: 0) else { return }
        event.setIntegerValueField(.eventSourceUserData, value: ShortcutSender.eventTag)
        event.flags = flags
        event.post(tap: .cgSessionEventTap)
    }
}
