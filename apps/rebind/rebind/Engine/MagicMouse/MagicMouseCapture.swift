import Synchronization
import AppKit
import Carbon
import Dispatch

/// Main-actor device lifecycle and bounded dequeue; the callback only copies frames.
@MainActor final class MagicMouseCapture: NSObject {
    private let mailbox: EngineMailbox
    private var device: NativeTrackpadDevice?
    private var session: MagicMouseTapSession?
    private var revision: UInt64?
    private var scannedAt: UInt64?
    private var timer: Timer?

    init(mailbox: EngineMailbox) { self.mailbox = mailbox }

    func start() {
        guard timer == nil else { return }
        timer = Timer(timeInterval: 0.01, target: self, selector: #selector(poll), userInfo: nil, repeats: true)
        if let timer { RunLoop.main.add(timer, forMode: .common) }
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(foregroundChanged),
            name: NSWorkspace.didActivateApplicationNotification, object: nil)
    }

    /// Configuration/status changes wake an otherwise dormant observer without idle polling.
    func configurationChanged() { timer?.fireDate = Date() }

    func stop() {
        timer?.invalidate(); timer = nil
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        stopCapture()
        mailbox.state.withLock { $0.magicMouseStatus = .idle }
    }

    private func stopCapture() {
        device?.stop()
        session = nil
        revision = nil
        mailbox.state.withLock {
            if $0.trackpadDispatch?.trackpadTarget?.isMagicMouse == true { $0.trackpadDispatch = nil }
        }
    }

    @objc private func foregroundChanged() {
        session?.interrupt()
        configurationChanged()
        mailbox.updateTrackpadForeground(foregroundPID(), activationChanged: true)
    }

    private func foregroundPID() -> Int32? {
        guard let app = NSWorkspace.shared.frontmostApplication, app.isActive, !app.isTerminated,
              app.activationPolicy == .regular, app.processIdentifier > 0,
              app.processIdentifier != ProcessInfo.processInfo.processIdentifier else { return nil }
        return app.processIdentifier
    }

    @objc private func poll() {
        let now = DispatchTime.now().uptimeNanoseconds
        guard mailbox.magicMouseRuntime() != nil else {
            stopCapture()
            mailbox.state.withLock { $0.magicMouseStatus = .idle }
            timer?.fireDate = .distantFuture
            return
        }
        guard !IsSecureEventInputEnabled(), AXIsProcessTrusted(), CGPreflightPostEventAccess() else {
            stopCapture()
            mailbox.state.withLock { $0.magicMouseStatus = .idle }
            timer?.fireDate = Date().addingTimeInterval(0.5)
            return
        }
        let pid = foregroundPID()
        mailbox.updateTrackpadForeground(pid)
        let modifiers = ModifierSet(flags: CGEventSource.flagsState(.combinedSessionState))
        let buttonsDown = (0..<64).contains {
            CGEventSource.buttonState(.combinedSessionState, button: CGMouseButton(rawValue: UInt32($0)) ?? .left)
        }
        guard let runtime = mailbox.magicMouseRuntime(modifiers: modifiers, buttonsDown: buttonsDown) else {
            stopCapture()
            mailbox.state.withLock { $0.magicMouseStatus = .idle }
            timer?.fireDate = .distantFuture
            return
        }
        if scannedAt.map({ now < $0 || now - $0 >= 2_000_000_000 }) ?? true {
            scannedAt = now
            let found = NativeTrackpadDevice.acquire(mailbox: mailbox, kind: .magicMouse)
            if found !== device {
                stopCapture()
                device = found
                found?.buffer.setWake { [weak self] in
                    DispatchQueue.main.async { MainActor.assumeIsolated { self?.timer?.fireDate = Date() } }
                }
            }
        }
        guard let device else {
            mailbox.state.withLock { $0.magicMouseStatus = .unavailable }
            timer?.fireDate = Date().addingTimeInterval(2)
            return
        }
        if revision != runtime.revision {
            stopCapture()
            revision = runtime.revision
            guard device.start() else {
                mailbox.state.withLock { $0.magicMouseStatus = .failed }
                timer?.fireDate = Date().addingTimeInterval(2)
                return
            }
            session = MagicMouseTapSession(runtime: runtime, foreground: pid, startedAt: now)
        }
        guard session != nil else {
            mailbox.state.withLock { $0.magicMouseStatus = .failed }
            timer?.fireDate = Date().addingTimeInterval(2)
            return
        }
        session?.update(runtime: runtime, foreground: pid)
        session?.consumeBufferedFrames(from: device.buffer, clock: { DispatchTime.now().uptimeNanoseconds })
        let decisionTime = DispatchTime.now().uptimeNanoseconds
        if let fingers = session?.takeReady(from: device.buffer, at: decisionTime), let pid {
            _ = mailbox.submitMagicMouse(runtime, fingers: fingers, pid: pid, at: decisionTime)
        }
        mailbox.state.withLock { $0.magicMouseStatus = .active }
        // No idle 100 Hz polling. The first new frame wakes this timer immediately;
        // the two-second fallback is also the connection discovery cadence.
        if now > 500_000_000, device.buffer.sleepIfQuiet(since: now - 500_000_000) {
            timer?.fireDate = Date().addingTimeInterval(2)
        }
    }
}
