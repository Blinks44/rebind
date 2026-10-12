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
    private var device: NativeTrackpadDevice?
    private var timer: Timer?
    private var revision: UInt64?
    private var session: TrackpadTapSession?

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
        session?.interrupt()
        mailbox.updateTrackpadForeground(foregroundPID(), activationChanged: true)
    }

    private func foregroundPID() -> Int32? {
        guard let app = NSWorkspace.shared.frontmostApplication,
              app.isActive, !app.isTerminated, app.activationPolicy == .regular,
              app.processIdentifier > 0, app.processIdentifier != ProcessInfo.processInfo.processIdentifier else { return nil }
        return app.processIdentifier
    }

    private func stopCapture() {
        device?.stop()
        revision = nil; session = nil
        mailbox.state.withLock { $0.trackpadStatus = .idle; $0.trackpadDispatch = nil }
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
        guard let runtime = mailbox.trackpadRuntime() else {
            mailbox.recordTrackpadDiagnostic(.captureInactive)
            stopCapture()
            // Idle polling does not need the recognition cadence.
            timer?.fireDate = Date().addingTimeInterval(0.1)
            return
        }
        if revision != runtime.revision {
            stopCapture()
            if device == nil { device = NativeTrackpadDevice.acquire(mailbox: mailbox) }
            guard let device, device.start() else {
                mailbox.state.withLock { $0.trackpadStatus = device?.failed == true ? .failed : .unavailable }
                mailbox.recordTrackpadDiagnostic(device?.failed == true ? .captureFailed : .captureUnavailable)
                // Latch this revision; a failing start is not retried every 10 ms.
                revision = runtime.revision
                return
            }
            revision = runtime.revision
            mailbox.recordTrackpadDiagnostic(.captureRestarted)
            session = TrackpadTapSession(runtime: runtime, foreground: pid, startedAt: now)
        }
        guard let device, session != nil else { return }
        if let event = session?.update(runtime: runtime, foreground: pid) { mailbox.recordTrackpadDiagnostic(event) }
        let mailbox = mailbox
        session?.consumeBufferedFrames(from: device.buffer, clock: { DispatchTime.now().uptimeNanoseconds },
                                       diagnose: { mailbox.recordTrackpadDiagnostic($0) })
        let decisionTime = DispatchTime.now().uptimeNanoseconds
        // A busy UI cancels rather than executing old actions after it unblocks.
        if let gesture = session?.takeReadyGesture(from: device.buffer, at: decisionTime,
                              diagnose: { mailbox.recordTrackpadDiagnostic($0) }), let pid {
            let queued = mailbox.submitTrackpad(runtime, gesture: gesture, pid: pid, at: decisionTime)
            mailbox.recordTrackpadDiagnostic(queued ? .queued : .queueUnavailable)
        }
        if let event = session?.takeCancellation() { mailbox.recordTrackpadDiagnostic(event) }
        mailbox.state.withLock { $0.trackpadStatus = .active }
    }

    private func reportDiagnostics(finishing: Bool = false) {
        if let report = mailbox.takeTrackpadDiagnosticReport(at: DispatchTime.now().uptimeNanoseconds, finishing: finishing) {
            FileHandle.standardError.write(Data(("trackpad_diagnostics=" + report + "\n").utf8))
        }
    }
}
