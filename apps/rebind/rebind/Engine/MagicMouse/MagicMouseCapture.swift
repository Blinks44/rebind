import Synchronization
import AppKit
import Carbon
import Dispatch

/// Main-actor device lifecycle and bounded dequeue; the callback only copies frames.
@MainActor final class MagicMouseCapture: NSObject {
    private let mailbox: EngineMailbox
    private var device: (any MagicMouseCaptureDevice)?
    private var session: MagicMouseTapSession?
    private var revision: UInt64?
    private var scannedAt: UInt64?
    private var timer: Timer?
    private let acquireDevice: () -> (any MagicMouseCaptureDevice)?
    private let clock: () -> UInt64
    private var controlRevision: UInt64?
    private var controlAllowsCapture: Bool?

    /// The scheduled deadline, including a distant deadline when capture is dormant.
    var nextPollDate: Date? { timer?.fireDate }

    init(mailbox: EngineMailbox, acquireDevice: (() -> (any MagicMouseCaptureDevice)?)? = nil,
         clock: @escaping () -> UInt64 = { DispatchTime.now().uptimeNanoseconds }) {
        self.mailbox = mailbox
        self.acquireDevice = acquireDevice ?? { NativeTrackpadDevice.acquire(mailbox: mailbox, kind: .magicMouse) }
        self.clock = clock
    }

    func start() {
        guard timer == nil else { return }
        timer = Timer(timeInterval: 0.01, target: self, selector: #selector(poll), userInfo: nil, repeats: true)
        if let timer { RunLoop.main.add(timer, forMode: .common) }
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(foregroundChanged),
            name: NSWorkspace.didActivateApplicationNotification, object: nil)
    }

    /// Configuration/status changes wake an otherwise dormant observer without idle polling.
    func configurationChanged() { timer?.fireDate = Date() }

    /// Piggybacks on the model's existing refresh; unchanged state never wakes capture.
    /// Editing/recording and exclusions can change admission without changing tap status.
    func refreshControl() {
        let control = mailbox.state.withLock { ($0.actionRevision, $0.canDispatch && $0.hasMagicMouseRules) }
        guard controlRevision != control.0 || controlAllowsCapture != control.1 else { return }
        controlRevision = control.0
        controlAllowsCapture = control.1
        configurationChanged()
    }

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
        service(allowingInput: !IsSecureEventInputEnabled() && AXIsProcessTrusted() && CGPreflightPostEventAccess(),
                foregroundPID: foregroundPID(),
                modifiers: ModifierSet(flags: CGEventSource.flagsState(.combinedSessionState)),
                buttonsDown: (0..<64).contains {
                    CGEventSource.buttonState(.combinedSessionState, button: CGMouseButton(rawValue: UInt32($0)) ?? .left)
                })
    }

    /// One bounded service pass; environment and acquisition are isolated from recognition.
    func service(allowingInput: Bool, foregroundPID pid: Int32?, modifiers: ModifierSet, buttonsDown: Bool) {
        let now = clock()
        guard mailbox.magicMouseRuntime() != nil else {
            stopCapture()
            mailbox.state.withLock { $0.magicMouseStatus = .idle }
            timer?.fireDate = .distantFuture
            return
        }
        guard allowingInput else {
            stopCapture()
            mailbox.state.withLock { $0.magicMouseStatus = .idle }
            timer?.fireDate = Date().addingTimeInterval(0.5)
            return
        }
        mailbox.updateTrackpadForeground(pid)
        guard let runtime = mailbox.magicMouseRuntime(modifiers: modifiers, buttonsDown: buttonsDown) else {
            stopCapture()
            mailbox.state.withLock { $0.magicMouseStatus = .idle }
            timer?.fireDate = .distantFuture
            return
        }
        if scannedAt.map({ now < $0 || now - $0 >= 2_000_000_000 }) ?? true {
            scannedAt = now
            let found = acquireDevice()
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
        session?.consumeBufferedFrames(from: device.buffer, clock: clock)
        let decisionTime = clock()
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
