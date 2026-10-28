import Synchronization
import AppKit
import Carbon
import Dispatch

// Consumes the bounded native buffer outside its synchronous callback. MainActor
// owns private device start/stop and public foreground lookup; the existing serial
// action worker performs the balanced output. No touch coordinates are persisted,
// logged, exposed to UI, or retained after an interrupted/completed stroke.
@MainActor final class TrackpadCapture: NSObject {
    private let mailbox: EngineMailbox
    /// One independent recognition pipeline per touch surface.
    private struct Surface {
        let kind: NativeTrackpadDevice.Kind
        var device: NativeTrackpadDevice?
        var revision: UInt64?
        var session: TrackpadTapSession?
        var scannedAt: UInt64?
    }
    private var surfaces = [Surface(kind: .builtIn), Surface(kind: .magicTrackpad)]
    private var timer: Timer?
    private var controlRevision: UInt64?
    private var controlAllowsCapture: Bool?

    /// The scheduled deadline, including a distant deadline when capture is dormant.
    var nextPollDate: Date? { timer?.fireDate }

    init(mailbox: EngineMailbox) { self.mailbox = mailbox }

    func start() {
        guard timer == nil else { return }
        if ProcessInfo.processInfo.arguments.contains("--diagnose-trackpad") {
            mailbox.state.withLock { $0.trackpadDiagnostics = TrackpadDiagnostics(startedAt: DispatchTime.now().uptimeNanoseconds) }
            FileHandle.standardError.write(Data("trackpad_diagnostics_started=60s; aggregate reasons only; existing rules remain active\n".utf8))
        }
        timer = Timer(timeInterval: 0.01, target: self, selector: #selector(poll), userInfo: nil, repeats: true)
        if let timer { RunLoop.main.add(timer, forMode: .common) }
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(foregroundChanged),
                                                         name: NSWorkspace.didActivateApplicationNotification, object: nil)
    }

    func stop() {
        timer?.invalidate(); timer = nil
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        stopCapture()
        reportDiagnostics(finishing: true)
    }

    /// Configuration/status changes wake an otherwise dormant observer without idle polling.
    func configurationChanged() { timer?.fireDate = Date() }

    /// Piggybacks on the model's existing refresh, like Magic Mouse capture; unchanged state never wakes it.
    func refreshControl() {
        let control = mailbox.state.withLock { ($0.actionRevision, $0.canDispatch && $0.hasTrackpadRules) }
        guard controlRevision != control.0 || controlAllowsCapture != control.1 else { return }
        controlRevision = control.0
        controlAllowsCapture = control.1
        configurationChanged()
    }

    @objc private func foregroundChanged() {
        for index in surfaces.indices { surfaces[index].session?.interrupt() }
        mailbox.updateTrackpadForeground(foregroundPID(), activationChanged: true)
        // The app in front selects its own rules.
        configurationChanged()
    }

    private func foregroundPID() -> Int32? {
        guard let app = NSWorkspace.shared.frontmostApplication,
              app.isActive, !app.isTerminated, app.activationPolicy == .regular,
              app.processIdentifier > 0, app.processIdentifier != ProcessInfo.processInfo.processIdentifier else { return nil }
        return app.processIdentifier
    }

    private func stopCapture() {
        for index in surfaces.indices { stop(&surfaces[index]) }
        mailbox.state.withLock {
            $0.trackpadStatus = .idle
            if $0.trackpadDispatch?.trackpadTarget?.isMagicMouse != true { $0.trackpadDispatch = nil }
        }
    }

    private func stop(_ surface: inout Surface) {
        surface.device?.stop()
        surface.revision = nil
        surface.session = nil
    }

    @objc private func poll() {
        service(allowingInput: !IsSecureEventInputEnabled() && AXIsProcessTrusted() && CGPreflightPostEventAccess(),
                foregroundPID: foregroundPID(),
                modifiers: ModifierSet(flags: CGEventSource.flagsState(.combinedSessionState)))
    }

    /// Services both trackpads with one permission, foreground and held-modifier snapshot.
    func service(allowingInput: Bool, foregroundPID pid: Int32?, modifiers: ModifierSet) {
        let now = DispatchTime.now().uptimeNanoseconds
        // No trackpad rule can match: sleep until configuration or status changes.
        guard mailbox.state.withLock({ $0.canDispatch && $0.hasTrackpadRules }) else {
            mailbox.state.withLock { $0.trackpadDiagnostics = nil }
            stopCapture()
            timer?.fireDate = .distantFuture
            return
        }
        guard allowingInput else {
            mailbox.state.withLock { $0.trackpadDiagnostics = nil }
            stopCapture()
            timer?.fireDate = Date().addingTimeInterval(0.1)
            return
        }
        reportDiagnostics()
        // Publish focus cancellation before snapshotting activity; otherwise
        // this poll could classify pre-switch contacts with the old runtime.
        mailbox.updateTrackpadForeground(pid)
        var statuses: [TrackpadCaptureStatus] = []
        for index in surfaces.indices { statuses.append(service(&surfaces[index], pid: pid, modifiers: modifiers, now: now)) }
        let status = statuses.first { $0 != .idle } ?? .idle
        mailbox.state.withLock {
            $0.trackpadStatus = status
            // The bounded touch-output slot is shared with Magic Mouse capture.
            if status == .idle, $0.trackpadDispatch?.trackpadTarget?.isMagicMouse != true { $0.trackpadDispatch = nil }
        }
        if status == .idle {
            mailbox.recordTrackpadDiagnostic(.captureInactive)
            // Idle polling does not need the recognition cadence.
            timer?.fireDate = Date().addingTimeInterval(0.5)
        } else if surfacesAreQuiet(at: now) {
            // No finger for longer than a double tap can wait: the next frame wakes the poll.
            timer?.fireDate = Date().addingTimeInterval(0.25)
        }
    }

    /// Whether every running surface has been without frames for its double-tap interval plus
    /// half a second, so no tap or double tap can still be pending. Puts their buffers to sleep.
    private func surfacesAreQuiet(at now: UInt64) -> Bool {
        surfaces.allSatisfy { surface in
            guard let device = surface.device, let session = surface.session else { return true }
            let window = session.runtime.doubleTapIntervalNanoseconds &+ 500_000_000
            return now > window && device.buffer.sleepIfQuiet(since: now - window)
        }
    }

    /// Called from the touch callback (once per touch after a quiet period): poll now.
    private nonisolated static func wakeHandler(for capture: TrackpadCapture) -> @Sendable () -> Void {
        { [weak capture] in
            DispatchQueue.main.async { MainActor.assumeIsolated { capture?.timer?.fireDate = Date() } }
        }
    }

    private func service(_ surface: inout Surface, pid: Int32?, modifiers: ModifierSet, now: UInt64) -> TrackpadCaptureStatus {
        let isMagic = surface.kind == .magicTrackpad
        // The pass's held-key snapshot selects the same modifiers for both surfaces.
        guard let runtime = mailbox.trackpadRuntime(magicTrackpad: isMagic, modifiers: modifiers) else {
            stop(&surface)
            return .idle
        }
        // A Magic Trackpad connects and disconnects; look for it at a slow cadence.
        if isMagic, surface.scannedAt.map({ now < $0 || now - $0 >= 2_000_000_000 }) ?? true {
            surface.scannedAt = now
            let found = NativeTrackpadDevice.acquire(mailbox: mailbox, kind: .magicTrackpad)
            if found !== surface.device {
                stop(&surface)
                surface.device = found
                found?.buffer.setWake(Self.wakeHandler(for: self))
            }
        }
        if surface.revision != runtime.revision {
            stop(&surface)
            if !isMagic, surface.device == nil {
                surface.device = NativeTrackpadDevice.acquire(mailbox: mailbox)
                surface.device?.buffer.setWake(Self.wakeHandler(for: self))
            }
            mailbox.state.withLock {
                if isMagic { $0.magicTrackpadClicks.beginCapture(at: now) }
                else { $0.trackpadClicks.beginCapture(at: now) }
            }
            guard let device = surface.device, device.start() else {
                mailbox.recordTrackpadDiagnostic(surface.device?.failed == true ? .captureFailed : .captureUnavailable)
                // Latch this revision; a failing start is not retried every 10 ms.
                // An absent Magic Trackpad is picked up by the next scan instead.
                if surface.device != nil || !isMagic { surface.revision = runtime.revision }
                return surface.device?.failed == true ? .failed : .unavailable
            }
            surface.revision = runtime.revision
            mailbox.recordTrackpadDiagnostic(.captureRestarted)
            surface.session = TrackpadTapSession(runtime: runtime, foreground: pid, startedAt: now)
        }
        guard let device = surface.device, surface.session != nil else {
            return surface.device?.failed == true ? .failed : .unavailable
        }
        if let event = surface.session?.update(runtime: runtime, foreground: pid) { mailbox.recordTrackpadDiagnostic(event) }
        let mailbox = mailbox
        surface.session?.consumeBufferedFrames(from: device.buffer, clock: { DispatchTime.now().uptimeNanoseconds },
                                               diagnose: { mailbox.recordTrackpadDiagnostic($0) })
        let decisionTime = DispatchTime.now().uptimeNanoseconds
        // A busy UI cancels rather than executing old actions after it unblocks.
        if let gesture = surface.session?.takeReadyGesture(from: device.buffer, at: decisionTime,
                              diagnose: { mailbox.recordTrackpadDiagnostic($0) }), let pid {
            let queued = mailbox.submitTrackpad(runtime, gesture: gesture, pid: pid, at: decisionTime)
            mailbox.recordTrackpadDiagnostic(queued ? .queued : .queueUnavailable)
        }
        if let event = surface.session?.takeCancellation() { mailbox.recordTrackpadDiagnostic(event) }
        return .active
    }

    private func reportDiagnostics(finishing: Bool = false) {
        if let report = mailbox.takeTrackpadDiagnosticReport(at: DispatchTime.now().uptimeNanoseconds, finishing: finishing) {
            FileHandle.standardError.write(Data(("trackpad_diagnostics=" + report + "\n").utf8))
        }
    }
}
