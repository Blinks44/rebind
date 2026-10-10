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
        timer = Timer(timeInterval: 0.01, target: self, selector: #selector(poll), userInfo: nil, repeats: true)
        if let timer { RunLoop.main.add(timer, forMode: .common) }
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(foregroundChanged),
                                                         name: NSWorkspace.didActivateApplicationNotification, object: nil)
    }

    func stop() {
        timer?.invalidate(); timer = nil
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        stopCapture()
    }

    @objc private func foregroundChanged() {
        session?.interrupt()
        mailbox.updateTrackpadForeground(foregroundPID())
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
        guard let runtime = mailbox.trackpadRuntime(), !IsSecureEventInputEnabled(),
              AXIsProcessTrusted(), CGPreflightPostEventAccess() else {
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
                // Latch this revision; a failing start is not retried every 10 ms.
                revision = runtime.revision
                return
            }
            revision = runtime.revision
            session = TrackpadTapSession(runtime: runtime, foreground: foregroundPID(), startedAt: now)
        }
        guard let device, session != nil else { return }
        let pid = foregroundPID()
        session?.update(runtime: runtime, foreground: pid)
        mailbox.updateTrackpadForeground(pid)
        if device.buffer.takeOverflow() { session?.interrupt() }
        while let frame = device.buffer.pop() { session?.consume(frame, at: now) }
        // A busy UI cancels rather than executing old actions after it unblocks.
        if session?.takeReady(at: now) == true, let pid {
            mailbox.submitTrackpad(runtime, pid: pid, at: now)
        }
        mailbox.state.withLock { $0.trackpadStatus = .active }
    }
}
