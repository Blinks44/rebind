import ApplicationServices
import Carbon
import Foundation
import Dispatch
import Synchronization

// This object, its port, and its callback context belong exclusively to the
// worker thread. Only the checked-Sendable Mutex mailbox crosses threads.
nonisolated final class EventTapWorker {
    private let mailbox: EngineMailbox
    private var port: CFMachPort?
    private var source: CFRunLoopSource?
    private var capturesPointerMotion = false
    private var failureLatched = false
    private var lastPermissionCheck = Date.distantPast
    private var hasPermissions = false
    private var lastRetryID: UInt64 = 0

    init(mailbox: EngineMailbox) { self.mailbox = mailbox }

    static func start(mailbox: EngineMailbox) {
        let thread = Thread {
            let worker = EventTapWorker(mailbox: mailbox)
            worker.run()
        }
        thread.name = "Rebind input tap"
        thread.qualityOfService = .userInteractive
        thread.start()
    }

    private func run() {
        defer { removeTap() }
        while !mailbox.state.withLock({ $0.stopped }) {
            autoreleasepool {
                service()
                if port != nil {
                    CFRunLoopRunInMode(.defaultMode, 0.02, false)
                } else {
                    Thread.sleep(forTimeInterval: 0.05)
                }
            }
        }
    }

    private func service() {
        if Date().timeIntervalSince(lastPermissionCheck) >= 0.5 {
            hasPermissions = InputPermissions.current().allowsRemapping
            lastPermissionCheck = Date()
        }
        let now = DispatchTime.now().uptimeNanoseconds
        let control = mailbox.state.withLock {
            $0.diagnostics.expire(at: now)
            return ($0.enabled, $0.recording != nil, $0.suspended, $0.retryID, $0.matcher.hasSuppressedInput,
                    $0.isMatching && $0.hasPointerGestureRules, $0.diagnostics.isRunning)
        }
        if failureLatched { removeTap() }
        if !hasPermissions || control.2 {
            removeTap()
            mailbox.captureLost(status: hasPermissions ? .paused : .permissionRequired)
            return
        }
        // Explicit Resume/Record is required after failure; avoid retry storms.
        if control.3 != lastRetryID {
            failureLatched = false
            lastRetryID = control.3
        }
        if !control.0 && !control.1 && !control.4 && !control.6 { removeTap() }
        if port != nil, capturesPointerMotion != control.5 { removeTap() }
        // A disabled/invalid tap may stop delivering callbacks altogether. Check
        // on its owning thread before draining output, not just in the callback.
        if let port, !CFMachPortIsValid(port) || !CGEvent.tapIsEnabled(tap: port) {
            failureLatched = true
            mailbox.captureLost(status: .interrupted, pause: true)
            removeTap()
        }
        if port == nil, (control.0 || control.1 || control.4 || control.6), !failureLatched {
            installTap(capturePointerMotion: control.5)
        }
        let secure = IsSecureEventInputEnabled()
        mailbox.state.withLock {
            if secure {
                // Keep a latched failure visible; it still needs explicit retry
                // after Secure Input ends, rather than appearing protected forever.
                $0.resetCapture(status: failureLatched ? $0.status : .secureInput)
            } else if !failureLatched {
                $0.status = control.0 && port != nil ? .active : .paused
            }
        }
        guard port != nil, !secure, !failureLatched else { return }
        mailbox.pollHold(at: DispatchTime.now().uptimeNanoseconds, secureInput: IsSecureEventInputEnabled())
    }

    static func eventMask(capturePointerMotion: Bool) -> CGEventMask {
        var types: [CGEventType] = [.keyDown, .keyUp, .flagsChanged, .leftMouseDown, .rightMouseDown,
                                   .leftMouseUp, .rightMouseUp,
                                   .otherMouseDown, .otherMouseUp, .otherMouseDragged,
                                   .leftMouseDragged, .rightMouseDragged, .scrollWheel]
        // Do not intercept the high-frequency idle motion stream unless enabled
        // gesture rules need it. Some drivers deliver motion instead of dragging.
        if capturePointerMotion { types.append(.mouseMoved) }
        return types.reduce(CGEventMask(0)) { $0 | (CGEventMask(1) << $1.rawValue) }
    }

    private func installTap(capturePointerMotion: Bool) {
        let mask = Self.eventMask(capturePointerMotion: capturePointerMotion)
        let context = Unmanaged.passUnretained(self).toOpaque()
        guard let port = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap,
                                          options: .defaultTap, eventsOfInterest: mask,
                                          callback: { _, type, event, context in
            guard let context else { return Unmanaged.passUnretained(event) }
            let worker = Unmanaged<EventTapWorker>.fromOpaque(context).takeUnretainedValue()
            return worker.receive(type: type, event: event)
        }, userInfo: context), let source = CFMachPortCreateRunLoopSource(nil, port, 0) else {
            failureLatched = true
            mailbox.captureLost(status: .tapFailed)
            return
        }
        self.port = port
        self.source = source
        capturesPointerMotion = capturePointerMotion
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .defaultMode)
        CGEvent.tapEnable(tap: port, enable: true)
    }

    private func removeTap() {
        if let source { CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .defaultMode) }
        if let port { CFMachPortInvalidate(port) }
        source = nil
        port = nil
        capturesPointerMotion = false
    }

    private func receive(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            failureLatched = true
            mailbox.captureLost(status: .interrupted, pause: true)
            // Do not re-enable in the callback. Let the user deliberately resume.
            return Unmanaged.passUnretained(event)
        }
        guard event.getIntegerValueField(.eventSourceUserData) != ShortcutSender.eventTag else {
            return Unmanaged.passUnretained(event)
        }
        if type == .mouseMoved {
            return mailbox.handlePointerMotion(PointerMotion.from(event), modifiers: ModifierSet(flags: event.flags),
                                               receivedAt: DispatchTime.now().uptimeNanoseconds,
                                               secureInput: IsSecureEventInputEnabled()) ? nil : Unmanaged.passUnretained(event)
        }
        if type == .scrollWheel {
            guard var input = ScrollEventAdapter.input(from: event) else {
                // Smooth/momentum/diagonal input still cancels a pending hold,
                // while passing through unchanged and never creating a wheel action.
                mailbox.handleUnsupportedScroll(modifiers: ModifierSet(flags: event.flags),
                                                at: DispatchTime.now().uptimeNanoseconds,
                                                secureInput: IsSecureEventInputEnabled())
                return Unmanaged.passUnretained(event)
            }
            input.receivedAt = DispatchTime.now().uptimeNanoseconds
            return mailbox.handle(input, secureInput: IsSecureEventInputEnabled()) ? nil : Unmanaged.passUnretained(event)
        }
        let trigger: InputTrigger
        let phase: InputEvent.Phase
        switch type {
        case .keyDown, .keyUp, .flagsChanged:
            let code = event.getIntegerValueField(.keyboardEventKeycode)
            guard let value = UInt16(exactly: code) else { return Unmanaged.passUnretained(event) }
            trigger = .key(value)
            phase = type == .flagsChanged ? .modifiersChanged : (type == .keyDown ? .down : .up)
        case .leftMouseDown, .rightMouseDown, .otherMouseDown, .leftMouseUp, .rightMouseUp, .otherMouseUp,
             .otherMouseDragged, .leftMouseDragged, .rightMouseDragged:
            let number = event.getIntegerValueField(.mouseEventButtonNumber)
            guard let value = UInt32(exactly: number) else { return Unmanaged.passUnretained(event) }
            trigger = .mouseButton(value)
            switch type {
            case .leftMouseUp, .rightMouseUp, .otherMouseUp: phase = .up
            case .otherMouseDragged, .leftMouseDragged, .rightMouseDragged: phase = .drag
            default: phase = .down
            }
        default: return Unmanaged.passUnretained(event)
        }
        let input = InputEvent(trigger: trigger, modifiers: ModifierSet(flags: event.flags), phase: phase,
                               isRepeat: type == .keyDown && event.getIntegerValueField(.keyboardEventAutorepeat) != 0,
                               timestamp: event.timestamp, receivedAt: DispatchTime.now().uptimeNanoseconds,
                               motion: phase == .drag ? PointerMotion.from(event) : nil)
        return mailbox.handle(input, secureInput: IsSecureEventInputEnabled()) ? nil : Unmanaged.passUnretained(event)
    }
}
