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

    @objc private func foregroundChanged() {
        for index in surfaces.indices { surfaces[index].session?.interrupt() }
        mailbox.updateTrackpadForeground(foregroundPID(), activationChanged: true)
    }

    private func foregroundPID() -> Int32? {
        guard let app = NSWorkspace.shared.frontmostApplication,
              app.isActive, !app.isTerminated, app.activationPolicy == .regular,
              app.processIdentifier > 0, app.processIdentifier != ProcessInfo.processInfo.processIdentifier else { return nil }
        return app.processIdentifier
    }

    private func stopCapture() {
        for index in surfaces.indices { stop(&surfaces[index]) }
        mailbox.state.withLock { $0.trackpadStatus = .idle; $0.trackpadDispatch = nil }
    }

    private func stop(_ surface: inout Surface) {
        surface.device?.stop()
        surface.revision = nil
        surface.session = nil
    }

    @objc private func poll() {
        let now = DispatchTime.now().uptimeNanoseconds
        guard !IsSecureEventInputEnabled(),
              AXIsProcessTrusted(), CGPreflightPostEventAccess() else {
            mailbox.state.withLock { $0.trackpadDiagnostics = nil }
            stopCapture()
            timer?.fireDate = Date().addingTimeInterval(0.1)
            return
        }
        reportDiagnostics()
        // Publish focus cancellation before snapshotting activity; otherwise
        // this poll could classify pre-switch contacts with the old runtime.
        let pid = foregroundPID()
        mailbox.updateTrackpadForeground(pid)
        var statuses: [TrackpadCaptureStatus] = []
        for index in surfaces.indices { statuses.append(service(&surfaces[index], pid: pid, now: now)) }
        let status = statuses.first { $0 != .idle } ?? .idle
        mailbox.state.withLock {
            $0.trackpadStatus = status
            if status == .idle { $0.trackpadDispatch = nil }
        }
        if status == .idle {
            mailbox.recordTrackpadDiagnostic(.captureInactive)
            // Idle polling does not need the recognition cadence.
            timer?.fireDate = Date().addingTimeInterval(0.1)
        }
    }

    private func service(_ surface: inout Surface, pid: Int32?, now: UInt64) -> TrackpadCaptureStatus {
        let isMagic = surface.kind == .magicTrackpad
        // Read the held keys here, off the event tap; the session restarts whenever they change.
        let modifiers = ModifierSet(flags: CGEventSource.flagsState(.combinedSessionState))
        guard let runtime = mailbox.trackpadRuntime(magicTrackpad: isMagic, modifiers: modifiers) else {
            stop(&surface)
            return .idle
        }
        // A Magic Trackpad connects and disconnects; look for it at a slow cadence.
        if isMagic, surface.scannedAt.map({ now < $0 || now - $0 >= 2_000_000_000 }) ?? true {
            surface.scannedAt = now
            let found = NativeTrackpadDevice.acquire(mailbox: mailbox, kind: .magicTrackpad)
            if found !== surface.device { stop(&surface); surface.device = found }
        }
        if surface.revision != runtime.revision {
            stop(&surface)
            if !isMagic, surface.device == nil { surface.device = NativeTrackpadDevice.acquire(mailbox: mailbox) }
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
