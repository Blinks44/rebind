import ApplicationServices
import Darwin
import Foundation

enum PassiveButtonProbe {
    // Rebind's existing ShortcutSender tag; this standalone target cannot import
    // the app module. Other apps' synthetic events remain indistinguishable.
    static let rebindTag: Int64 = 0x524542494E443031
    static let eventTypes: [CGEventType] = [.leftMouseDown, .leftMouseUp, .rightMouseDown,
                                           .rightMouseUp, .otherMouseDown, .otherMouseUp]
    static var eventMask: CGEventMask {
        eventTypes.reduce(0) { $0 | (CGEventMask(1) << $1.rawValue) }
    }

    // A CF run loop needs a fixed native thread. Structured cancellation signals
    // its bounded loop; the continuation joins cleanup without blocking a Swift
    // executor or transferring CFMachPort/CFRunLoop state across threads.
    @concurrent static func run(buffer: ButtonObservationBuffer, seconds: Int) async -> String {
        await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                let thread = Thread {
                    continuation.resume(returning: runSynchronously(buffer: buffer, seconds: seconds))
                }
                thread.name = "Rebind click feasibility"
                thread.qualityOfService = .userInteractive
                thread.start()
            }
        } onCancel: {
            buffer.state.withLock { $0.requestStop() }
        }
    }

    private static func runSynchronously(buffer: ButtonObservationBuffer, seconds: Int) -> String {
        guard !buffer.state.withLock({ $0.stopRequested }) else { return "cancelled" }
        guard ProbeSession.allowsCapture() else { return "protected-session" }
        guard let port = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap,
                                          options: .listenOnly, eventsOfInterest: eventMask,
                                          callback: callback,
                                          userInfo: Unmanaged.passUnretained(buffer).toOpaque()) else {
            return "mouse-observation-unavailable"
        }
        defer {
            // Invalidating on the callback's own run loop precedes context release.
            withExtendedLifetime(buffer) {
                CGEvent.tapEnable(tap: port, enable: false)
                CFMachPortInvalidate(port)
            }
        }
        guard let source = CFMachPortCreateRunLoopSource(nil, port, 0) else { return "mouse-run-loop-unavailable" }
        let runLoop = CFRunLoopGetCurrent()
        CFRunLoopAddSource(runLoop, source, .defaultMode)
        defer { CFRunLoopRemoveSource(runLoop, source, .defaultMode) }
        CGEvent.tapEnable(tap: port, enable: true)
        guard CGEvent.tapIsEnabled(tap: port) else { return "mouse-observation-disabled" }
        buffer.state.withLock { $0.markInstalled() }
        let started = clock_gettime_nsec_np(CLOCK_UPTIME_RAW)
        while !buffer.state.withLock({ $0.stopRequested }), clock_gettime_nsec_np(CLOCK_UPTIME_RAW) - started < UInt64(seconds) * 1_000_000_000 {
            guard ProbeSession.allowsCapture() else { buffer.state.withLock { $0.stop() }; return "protected-session" }
            guard CFMachPortIsValid(port), CGEvent.tapIsEnabled(tap: port),
                  !buffer.state.withLock({ $0.disabled }) else { return "mouse-observation-disabled" }
            CFRunLoopRunInMode(.defaultMode, 0.02, false)
        }
        return buffer.state.withLock({ $0.disabled }) ? "mouse-observation-disabled"
            : (buffer.state.withLock({ $0.stopRequested }) ? "cancelled" : "time-limit")
    }

    private static let callback: CGEventTapCallBack = { _, type, event, context in
        receive(type: type, event: event, context: context)
    }

    static func receive(type: CGEventType, event: CGEvent, context: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
        guard let context else { return Unmanaged.passUnretained(event) }
        let buffer = Unmanaged<ButtonObservationBuffer>.fromOpaque(context).takeUnretainedValue()
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            buffer.state.withLock { $0.stop() }
        } else if event.getIntegerValueField(.eventSourceUserData) != rebindTag, let phase = phase(for: type) {
            let button = event.getIntegerValueField(.mouseEventButtonNumber)
            let pressure = event.getDoubleValueField(.mouseEventPressure)
            let now = clock_gettime_nsec_np(CLOCK_UPTIME_RAW)
            buffer.state.withLock { $0.observe(phase: phase, button: button, pressure: pressure, at: now) }
        }
        // Passive observation never changes, retains or suppresses a CGEvent.
        return Unmanaged.passUnretained(event)
    }

    static func phase(for type: CGEventType) -> ButtonObservations.Record.Phase? {
        switch type {
        case .leftMouseDown, .rightMouseDown, .otherMouseDown: .down
        case .leftMouseUp, .rightMouseUp, .otherMouseUp: .up
        default: nil
        }
    }
}
