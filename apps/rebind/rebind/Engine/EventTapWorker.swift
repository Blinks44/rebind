import ApplicationServices
import AppKit
import Carbon
import Foundation
import Dispatch
import Synchronization

// This object, its port, and its callback context belong exclusively to the
// worker thread. Only the checked-Sendable Mutex mailbox crosses threads.
nonisolated final class EventTapWorker {
    private let mailbox: EngineMailbox
    private let scroller: SmoothScroller
    private var port: CFMachPort?
    private var source: CFRunLoopSource?
    private var capturesPointerMotion = false
    private var failureLatched = false
    private var lastPermissionCheck = Date.distantPast
    private var hasPermissions = false
    private var lastRetryID: UInt64 = 0
    /// When macOS last disabled the tap and it was turned back on, newest last.
    private var recoveries: [UInt64] = []

    init(mailbox: EngineMailbox) {
        self.mailbox = mailbox
        scroller = SmoothScroller.start(mailbox: mailbox)
    }

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
        // A port keeps the run loop waiting while no tap is installed.
        RunLoop.current.add(NSMachPort(), forMode: .default)
        mailbox.setTapRunLoop(CFRunLoopGetCurrent())
        defer { removeTap() }
        while !mailbox.state.withLock({ $0.stopped }) {
            autoreleasepool {
                service()
                // Returns after each handled event, so a hold that just began is timed from here;
                // the mailbox stops the loop early when rules, recording or pause change.
                CFRunLoopRunInMode(.defaultMode, pollInterval(), true)
            }
        }
    }

    /// Short slices only while a hold or a pointer gesture is being timed; otherwise the thread
    /// sleeps and still rechecks permissions and Secure Input twice a second.
    private func pollInterval() -> CFTimeInterval {
        mailbox.state.withLock { $0.matcher.holdKey != nil || $0.matcher.pointerGestureSource != nil } ? 0.01 : 0.5
    }

    private func service() {
        if Date().timeIntervalSince(lastPermissionCheck) >= 0.5 {
            hasPermissions = InputPermissions.current().allowsRemapping
            lastPermissionCheck = Date()
        }
        let now = DispatchTime.now().uptimeNanoseconds
        let control = mailbox.state.withLock {
            $0.diagnostics.expire(at: now)
            $0.magicMouseNative.expireScroll(at: now)
            return ($0.enabled, $0.recording != nil, $0.suspended, $0.retryID, $0.matcher.hasSuppressedInput || $0.magicMouseNative.hasOwnedInput,
                    $0.needsPointerMotion, $0.diagnostics.isRunning)
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
            if CFMachPortIsValid(port), Self.mayRecover(at: now, recent: &recoveries) {
                // macOS disables a tap that answered too slowly once (under heavy load, after
                // wake). Turn it back on, as other remappers do; events that passed meanwhile
                // leave unknown press state, so capture starts clean. Repeated loss stays latched.
                mailbox.captureLost(status: .paused)
                CGEvent.tapEnable(tap: port, enable: true)
            } else {
                failureLatched = true
                mailbox.captureLost(status: .interrupted, pause: true)
                removeTap()
            }
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

    /// At most three automatic recoveries a minute; beyond that something keeps the tap
    /// from working and the user resumes deliberately.
    static func mayRecover(at now: UInt64, recent: inout [UInt64], limit: Int = 3,
                           window: UInt64 = 60_000_000_000) -> Bool {
        recent.removeAll { now &- $0 >= window }
        guard recent.count < limit else { return false }
        recent.append(now)
        return true
    }

    static func eventMask(capturePointerMotion: Bool) -> CGEventMask {
        var types: [CGEventType] = [.keyDown, .keyUp, .flagsChanged, .leftMouseDown, .rightMouseDown,
                                   .leftMouseUp, .rightMouseUp,
                                   .otherMouseDown, .otherMouseUp, .otherMouseDragged,
                                   .leftMouseDragged, .rightMouseDragged, .scrollWheel]
        // Do not intercept the high-frequency idle motion stream unless enabled
        // pointer rules or Magic Mouse tap safety need it. Some drivers deliver motion instead of dragging.
        if capturePointerMotion { types.append(.mouseMoved) }
        return types.reduce(CGEventMask(0)) { $0 | (CGEventMask(1) << $1.rawValue) }
    }

    private func installTap(capturePointerMotion: Bool) {
        AttachedHIDScroll.prepare()
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
        scroller.cancel()
        if let source { CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .defaultMode) }
        if let port { CFMachPortInvalidate(port) }
        source = nil
        port = nil
        capturesPointerMotion = false
    }

    private func receive(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            // Not re-enabled here: `service` on this thread recovers or latches the failure
            // within one run-loop slice.
            return Unmanaged.passUnretained(event)
        }
        guard event.getIntegerValueField(.eventSourceUserData) != ShortcutSender.eventTag else {
            return Unmanaged.passUnretained(event)
        }
        if type == .mouseMoved {
            return mailbox.handlePointerMotion(PointerMotion.from(event), modifiers: ModifierSet(flags: event.flags),
                                               receivedAt: DispatchTime.now().uptimeNanoseconds,
                                               secureInput: IsSecureEventInputEnabled()) ? nil : pass(event)
        }
        if type == .scrollWheel {
            let phase = event.getIntegerValueField(.scrollWheelEventScrollPhase)
            let momentum = event.getIntegerValueField(.scrollWheelEventMomentumPhase)
            if (phase != 0 || momentum != 0), mailbox.tracksMagicMouseSource,
               mailbox.handleMagicMouseScroll(sender: AttachedHIDScroll.senderID(of: event), phase: phase, momentum: momentum,
                    direction: phase & 1 != 0 ? Self.fingerScrollDirection(of: event) : nil, modifiers: ModifierSet(flags: event.flags),
                    at: DispatchTime.now().uptimeNanoseconds, secureInput: IsSecureEventInputEnabled()) { return nil }
            guard var input = ScrollEventAdapter.input(from: event, adjustment: mailbox.wheelAdjustment) else {
                // Smooth/momentum/diagonal input still cancels a pending hold,
                // while passing through unchanged and never creating a wheel action.
                mailbox.handleUnsupportedScroll(modifiers: ModifierSet(flags: event.flags),
                                                at: DispatchTime.now().uptimeNanoseconds,
                                                secureInput: IsSecureEventInputEnabled())
                if let adjustment = mailbox.wheelAdjustment { ScrollEventAdapter.adjust(event, by: adjustment) }
                return pass(event)
            }
            input.receivedAt = DispatchTime.now().uptimeNanoseconds
            guard !mailbox.handle(input, secureInput: IsSecureEventInputEnabled()) else { return nil }
            if let adjustment = mailbox.wheelAdjustment { ScrollEventAdapter.adjust(event, by: adjustment) }
            let passed = pass(event)
            // A click no binding took becomes a glide when its mouse has smooth scrolling on;
            // the original click is swallowed.
            if SmoothScroller.applies(to: event) { mailbox.noteScroll() }
            if SmoothScroller.applies(to: event),
               let smooth = mailbox.smoothScrollDispatch(sender: AttachedHIDScroll.senderID(of: event)) {
                scroller.feed(event, dispatch: smooth)
                return nil
            }
            return passed
        }
        let trigger: InputTrigger
        let phase: InputEvent.Phase
        switch type {
        case .keyDown, .keyUp, .flagsChanged:
            let code = event.getIntegerValueField(.keyboardEventKeycode)
            guard let value = UInt16(exactly: code) else { return pass(event) }
            trigger = .key(value)
            phase = type == .flagsChanged ? .modifiersChanged : (type == .keyDown ? .down : .up)
        case .leftMouseDown, .rightMouseDown, .otherMouseDown, .leftMouseUp, .rightMouseUp, .otherMouseUp,
             .otherMouseDragged, .leftMouseDragged, .rightMouseDragged:
            let number = event.getIntegerValueField(.mouseEventButtonNumber)
            guard let value = UInt32(exactly: number) else { return pass(event) }
            trigger = .mouseButton(value)
            switch type {
            case .leftMouseUp, .rightMouseUp, .otherMouseUp: phase = .up
            case .otherMouseDragged, .leftMouseDragged, .rightMouseDragged: phase = .drag
            default: phase = .down
            }
        default: return pass(event)
        }
        let input = InputEvent(trigger: trigger, modifiers: ModifierSet(flags: event.flags), phase: phase,
                               isRepeat: type == .keyDown && event.getIntegerValueField(.keyboardEventAutorepeat) != 0,
                               timestamp: event.timestamp, receivedAt: DispatchTime.now().uptimeNanoseconds,
                               motion: phase == .drag ? PointerMotion.from(event) : nil,
                               isTouchClick: event.getIntegerValueField(.mouseEventSubtype) == Int64(NSEvent.EventSubtype.touch.rawValue))
        let sender: UInt64?
        if case .mouseButton(let button) = trigger, button <= 1, mailbox.tracksMagicMouseSource {
            sender = AttachedHIDScroll.senderID(of: event)
        } else { sender = nil }
        return mailbox.handle(input, secureInput: IsSecureEventInputEnabled(), sender: sender) ? nil : pass(event)
    }

    /// AppKit exposes the device inversion flag; this local wrapper reads metadata only.
    static func fingerScrollDirection(of event: CGEvent) -> ScrollDirection? {
        guard let native = NSEvent(cgEvent: event) else { return nil }
        return fingerScrollDirection(vertical: native.scrollingDeltaY, horizontal: native.scrollingDeltaX,
                                     inverted: native.isDirectionInvertedFromDevice)
    }

    static func fingerScrollDirection(vertical: Double, horizontal: Double, inverted: Bool) -> ScrollDirection? {
        guard vertical.isFinite, horizontal.isFinite, abs(vertical) > abs(horizontal) else { return nil }
        let physical = inverted ? -vertical : vertical
        return physical > 0 ? .up : .down
    }

    /// Hands an event on, with any modifier Rebind is holding for the user added to it.
    private func pass(_ event: CGEvent) -> Unmanaged<CGEvent> {
        let held = mailbox.virtualModifiers
        if !held.isEmpty { event.flags.insert(held.flags) }
        return Unmanaged.passUnretained(event)
    }
}
