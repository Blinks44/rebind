import ApplicationServices
import Carbon
import Dispatch
import Foundation
import Synchronization

// One serial consumer for the existing bounded mailbox. Core Audio and AX calls
// must never delay the synchronous tap's CFRunLoop or the UI. No second queue or
// unbounded dispatch blocks are created. Workspace requests use one bounded
// MainActor handoff slot, with at most one retained async operation.
// App-switch AX IPC transfers owned handles to a structured concurrent call;
// the Workspace slot still prevents another action from overtaking it.
nonisolated final class ActionWorker {
    private let mailbox: EngineMailbox
    private let capabilities: @Sendable () -> AudioOutputCapabilities
    private let performAudio: @Sendable (SystemAction, UInt32) -> Bool
    private let sendTrackpadShortcut: @Sendable (KeyboardShortcut, TrackpadDispatchTarget, @Sendable () -> Bool) -> WindowActionResult
    private let sendShortcut: @Sendable (KeyboardShortcut) -> Bool
    private let sendHeldKey: @Sendable (HeldKeyCommand) -> Void
    private let requestLock: @Sendable (@Sendable () -> Bool) -> WindowActionResult
    private let requestSleep: @Sendable (@Sendable () -> Bool) -> WindowActionResult
    private let performMouse: @Sendable (MouseAction, @Sendable () -> Bool) -> WindowActionResult
    private let performText: @Sendable (String, @Sendable () -> Bool) -> WindowActionResult
    private let performMedia: @Sendable (MediaAction, @Sendable () -> Bool) -> WindowActionResult
    private let performDock: @Sendable (DesktopAction, @Sendable () -> Bool) -> WindowActionResult
    private let performWindow: @Sendable (WindowAction, @Sendable () -> Bool) -> WindowActionResult
    private var windowCycle = WindowCycleState<AXUIElement>()
    private let performWindowCycle: (@Sendable (WindowCycleAction, @Sendable () -> Bool) -> WindowActionResult)?
    private let performWindowLayout: @Sendable (WindowLayoutAction, [WindowDisplay], @Sendable () -> Bool) -> WindowActionResult
    private let layoutClock: @Sendable () -> UInt64
    private let prepareWorkspace: @Sendable (WorkspaceAction) -> WorkspaceTarget?
    private let performAppleShortcut: @Sendable (AppleShortcutTarget, @Sendable () -> Bool) -> AppleShortcutRunResult
    private let secureInput: @Sendable () -> Bool
    private let postingAllowed: @Sendable () -> Bool
    private var lastCapabilitiesCheck: UInt64?

    init(mailbox: EngineMailbox,
         capabilities: @escaping @Sendable () -> AudioOutputCapabilities = { CoreAudioOutput.capabilities() },
         performAudio: @escaping @Sendable (SystemAction, UInt32) -> Bool = { CoreAudioOutput.perform($0, device: $1) },
         sendTrackpadShortcut: (@Sendable (KeyboardShortcut, TrackpadDispatchTarget, @Sendable () -> Bool) -> WindowActionResult)? = nil,
         sendShortcut: @escaping @Sendable (KeyboardShortcut) -> Bool = { ShortcutSender.send($0) },
         sendHeldKey: @escaping @Sendable (HeldKeyCommand) -> Void = { ShortcutSender.postHeldKey($0) },
         requestLock: @escaping @Sendable (@Sendable () -> Bool) -> WindowActionResult = { canPerform in
             ScreenLockExecutor.perform(canPerform: { canPerform() && ScreenLockSession.allowsInput() })
         },
         requestSleep: @escaping @Sendable (@Sendable () -> Bool) -> WindowActionResult = {
             SystemSleepExecutor.perform(canPerform: $0)
         },
         performMouse: @escaping @Sendable (MouseAction, @Sendable () -> Bool) -> WindowActionResult = {
             MouseClickSender.perform($0, canPerform: $1)
         },
         performText: @escaping @Sendable (String, @Sendable () -> Bool) -> WindowActionResult = {
             TextSender.perform($0, canPerform: $1)
         },
         performMedia: @escaping @Sendable (MediaAction, @Sendable () -> Bool) -> WindowActionResult = {
             MediaKeySender.perform($0, canPerform: $1)
         },
         performDock: @escaping @Sendable (DesktopAction, @Sendable () -> Bool) -> WindowActionResult = {
             DockActions.perform($0, canPerform: $1)
         },
         performWindow: @escaping @Sendable (WindowAction, @Sendable () -> Bool) -> WindowActionResult = {
             WindowActionExecutor.perform($0, canPerform: $1)
         },
         performWindowCycle: (@Sendable (WindowCycleAction, @Sendable () -> Bool) -> WindowActionResult)? = nil,
         performWindowLayout: @escaping @Sendable (WindowLayoutAction, [WindowDisplay], @Sendable () -> Bool) -> WindowActionResult = {
             WindowLayoutExecutor.perform($0, displays: $1, canPerform: $2)
         },
         layoutClock: @escaping @Sendable () -> UInt64 = { DispatchTime.now().uptimeNanoseconds },
         prepareWorkspace: @escaping @Sendable (WorkspaceAction) -> WorkspaceTarget? = { WorkspacePreparation.prepare($0) },
         performAppleShortcut: @escaping @Sendable (AppleShortcutTarget, @Sendable () -> Bool) -> AppleShortcutRunResult = {
             AppleShortcuts.run($0, canPerform: $1)
         },
         secureInput: @escaping @Sendable () -> Bool = { IsSecureEventInputEnabled() },
         postingAllowed: @escaping @Sendable () -> Bool = { CGPreflightPostEventAccess() }) {
        self.mailbox = mailbox
        self.capabilities = capabilities
        self.performAudio = performAudio
        self.requestLock = requestLock
        self.requestSleep = requestSleep
        self.sendShortcut = sendShortcut
        self.sendHeldKey = sendHeldKey
        self.sendTrackpadShortcut = sendTrackpadShortcut ?? { shortcut, target, canPerform in
            ShortcutSender.send(shortcut, to: target, canPerform: canPerform,
                                diagnose: { mailbox.recordTrackpadDiagnostic($0) })
        }
        self.performMouse = performMouse
        self.performMedia = performMedia
        self.performText = performText
        self.performDock = performDock
        self.performWindow = performWindow
        self.performWindowCycle = performWindowCycle
        self.performWindowLayout = performWindowLayout
        self.layoutClock = layoutClock
        self.prepareWorkspace = prepareWorkspace
        self.performAppleShortcut = performAppleShortcut
        self.secureInput = secureInput
        self.postingAllowed = postingAllowed
    }

    static func start(mailbox: EngineMailbox) {
        let thread = Thread {
            let worker = ActionWorker(mailbox: mailbox)
            while !mailbox.state.withLock({ $0.stopped }) {
                autoreleasepool { worker.service(at: DispatchTime.now().uptimeNanoseconds) }
                Thread.sleep(forTimeInterval: 0.02)
            }
            // Stopping marks every held key released; post what is still owed.
            while let command = mailbox.nextHeldKey(at: DispatchTime.now().uptimeNanoseconds) {
                ShortcutSender.postHeldKey(command)
            }
        }
        thread.name = "Rebind actions"
        thread.qualityOfService = .userInitiated
        thread.start()
    }

    func service(at now: UInt64) {
        windowCycle.invalidate(ifRevisionDiffersFrom: mailbox.state.withLock { $0.actionRevision })
        guard !mailbox.state.withLock({ $0.stopped }) else { return }
        if lastCapabilitiesCheck == nil || now < (lastCapabilitiesCheck ?? 0)
            || now - (lastCapabilitiesCheck ?? 0) >= 1_000_000_000 {
            lastCapabilitiesCheck = now
            mailbox.updateAudioCapabilities(capabilities())
        }
        let secure = secureInput()
        let allowed = postingAllowed()
        if secure { mailbox.captureLost(status: .secureInput) }
        else if !allowed { mailbox.captureLost(status: .permissionRequired) }
        // After the checks above, so a key held when capture is lost is released at once.
        if let command = mailbox.nextHeldKey(at: now) { sendHeldKey(command) }
        guard !secure, allowed else { return }
        guard let dispatch = mailbox.nextAction() else { return }
        // Recheck after dequeue: configuration/edit/pause/capture-loss changes
        // invalidate waiting work. A call already accepted here cannot be recalled.
        guard postingAllowed() else { mailbox.captureLost(status: .permissionRequired); return }
        guard !secureInput() else { mailbox.captureLost(status: .secureInput); return }
        guard mailbox.dispatchIsCurrent(dispatch) else { return }
        // A delayed touch action is dropped rather than executed late, whatever it does.
        if let target = dispatch.trackpadTarget, now > target.expiresAt {
            mailbox.recordTrackpadDiagnostic(.outputExpired)
            return
        }
        let mailbox = mailbox, postingAllowed = postingAllowed, secureInput = secureInput
        let canPerform: @Sendable () -> Bool = {
            mailbox.dispatchIsCurrent(dispatch) && postingAllowed() && !secureInput()
        }
        let result: WindowActionResult
        switch dispatch.action {
        case .shortcut(let shortcut):
            if let target = dispatch.trackpadTarget {
                result = sendTrackpadShortcut(shortcut, target, canPerform)
                switch result {
                case .performed: mailbox.recordTrackpadDiagnostic(.outputPosted)
                case .cancelled: mailbox.recordTrackpadDiagnostic(.outputCancelled)
                case .unavailable: mailbox.recordTrackpadDiagnostic(.outputUnavailable)
                }
            } else { result = sendShortcut(shortcut) ? .performed : .unavailable }
        case .lockScreen, .sleepSystem:
            let transition = dispatch.action == .lockScreen ? requestLock(canPerform) : requestSleep(canPerform)
            if transition == .performed { mailbox.systemTransitionRequested(dispatch) }
            else if transition == .unavailable { mailbox.actionFailed(dispatch) }
            return
        case .media(let action): result = performMedia(action, canPerform)
        case .mouse(let action): result = performMouse(action, canPerform)
        case .text(let text): result = performText(text, canPerform)
        case .dock(let action): result = performDock(action, canPerform)
        case .window(let action): result = performWindow(action, canPerform)
        case .doNothing, .modifier: result = .performed
        case .desktop: result = .unavailable // Legacy decoding only; cannot enter compiled rules.
        case .control(let action):
            mailbox.requestControl(action, for: dispatch)
            return
        case .system(let action):
            guard let device = dispatch.deviceID else { mailbox.actionFailed(dispatch); return }
            result = performAudio(action, device) ? .performed : .unavailable
        case .windowCycle(let action):
            if let performWindowCycle { result = performWindowCycle(action, canPerform) }
            else { result = WindowCycleExecutor.perform(action, revision: dispatch.revision, state: &windowCycle, canPerform: canPerform) }
        case .windowLayout(let action):
            let clock = layoutClock
            let snapshot = mailbox.state.withLock { $0.windowDisplays }
            guard snapshot.isFresh(at: clock()) else { mailbox.actionFailed(dispatch); return }
            result = performWindowLayout(action, snapshot.displays) {
                let current = mailbox.state.withLock { $0.windowDisplays }
                return current.displays == snapshot.displays && current.isFresh(at: clock()) && canPerform()
            }
        case .workspace(let action):
            guard let target = prepareWorkspace(action) else { mailbox.actionFailed(dispatch); return }
            // Preparation can wait on filesystem metadata. The MainActor
            // consumer also rechecks immediately before the native request.
            mailbox.submitWorkspace(WorkspaceRequest(dispatch: dispatch, target: target))
            return
        case .appleShortcut(let target):
            mailbox.state.withLock { $0.appleShortcutInProgress = true }
            let run = performAppleShortcut(target, canPerform)
            mailbox.state.withLock { $0.appleShortcutInProgress = false }
            switch run {
            case .performed: result = .performed
            case .cancelled: result = .cancelled
            case .failed: result = .unavailable
            }
        }
        guard result == .unavailable else { return }
        mailbox.actionFailed(dispatch)
        // Detect output replacement/property loss promptly, without retrying
        // an action or replaying the already consumed original input.
        if case .system = dispatch.action { mailbox.updateAudioCapabilities(capabilities()) }
    }
}
