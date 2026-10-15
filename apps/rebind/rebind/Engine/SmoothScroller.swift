import CoreGraphics
import Dispatch
import Foundation
import Synchronization

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

        var isIdle: Bool { remainingX == 0 && remainingY == 0 }
    }

    static let frameInterval = 1.0 / 120
    private let glide = Mutex(Glide())
    private let wake = DispatchSemaphore(value: 0)

    /// Starts the posting thread, which lives as long as the process (like the tap thread).
    static func start() -> SmoothScroller {
        let scroller = SmoothScroller()
        let thread = Thread { scroller.run() }
        thread.name = "Rebind smooth scrolling"
        thread.qualityOfService = .userInteractive
        thread.start()
        return scroller
    }

    /// Whether the tap should glide this wheel event instead of passing it on.
    static func applies(to event: CGEvent, settings: SmoothScrollingSettings) -> Bool {
        guard ScrollEventAdapter.isMouseWheel(event),
              settings.scope == .allWheels || event.getIntegerValueField(.scrollWheelEventIsContinuous) == 0 else {
            return false
        }
        // Zoom and other modified wheel actions keep the original, exact clicks, and so does
        // Shift: apps turn a Shift+wheel click into horizontal scrolling, not a precise glide.
        return event.flags.isDisjoint(with: [.maskCommand, .maskControl, .maskShift])
    }

    /// Adds one wheel event's distance in points (after reverse and speed). Tap callback: no I/O.
    func feed(_ event: CGEvent, settings: SmoothScrollingSettings) {
        let x = event.getDoubleValueField(.scrollWheelEventPointDeltaAxis2)
        let y = event.getDoubleValueField(.scrollWheelEventPointDeltaAxis1)
        let wasIdle = glide.withLock { glide in
            let wasIdle = glide.isIdle
            glide.remainingX = Self.add(x, to: glide.remainingX)
            glide.remainingY = Self.add(y, to: glide.remainingY)
            glide.timeConstant = settings.glide.timeConstant
            glide.flags = event.flags
            return wasIdle
        }
        if wasIdle { wake.signal() }
    }

    /// Stops a glide at once, for example when the tap is removed.
    func cancel() { glide.withLock { $0 = Glide() } }

    /// A click the other way stops the glide instead of fighting it.
    static func add(_ delta: Double, to remaining: Double) -> Double {
        remaining * delta < 0 ? delta : remaining + delta
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
            var previous = DispatchTime.now().uptimeNanoseconds
            while true {
                Thread.sleep(forTimeInterval: Self.frameInterval)
                let now = DispatchTime.now().uptimeNanoseconds
                let interval = Double(now - previous) / 1_000_000_000
                previous = now
                let frame = glide.withLock { glide -> (x: Double, y: Double, flags: CGEventFlags, done: Bool) in
                    let x = Self.step(remaining: glide.remainingX, interval: interval, timeConstant: glide.timeConstant)
                    let y = Self.step(remaining: glide.remainingY, interval: interval, timeConstant: glide.timeConstant)
                    glide.remainingX -= x
                    glide.remainingY -= y
                    return (x, y, glide.flags, glide.isIdle)
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
