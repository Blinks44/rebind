import ApplicationServices
import Carbon
import Dispatch
import Foundation
import Synchronization

// One serial consumer for the existing bounded mailbox. Core Audio and AX calls
// must never delay the synchronous tap's CFRunLoop or the UI. No second queue or
// unbounded dispatch blocks are created. Workspace requests use one bounded
// MainActor handoff slot, with at most one retained async operation.
nonisolated final class ActionWorker {
    private let mailbox: EngineMailbox
    private let capabilities: @Sendable () -> AudioOutputCapabilities
    private let performAudio: @Sendable (SystemAction, UInt32) -> Bool
    private let sendShortcut: @Sendable (KeyboardShortcut) -> Bool
    private let performMouse: @Sendable (MouseAction, @Sendable () -> Bool) -> WindowActionResult
    private let performMedia: @Sendable (MediaAction, @Sendable () -> Bool) -> WindowActionResult
    private let performDock: @Sendable (DesktopAction, @Sendable () -> Bool) -> WindowActionResult
    private let performWindow: @Sendable (WindowAction, @Sendable () -> Bool) -> WindowActionResult
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
         sendShortcut: @escaping @Sendable (KeyboardShortcut) -> Bool = { ShortcutSender.send($0) },
         performMouse: @escaping @Sendable (MouseAction, @Sendable () -> Bool) -> WindowActionResult = {
             MouseClickSender.perform($0, canPerform: $1)
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
        self.sendShortcut = sendShortcut
        self.performMouse = performMouse
        self.performMedia = performMedia
        self.performDock = performDock
        self.performWindow = performWindow
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
        }
        thread.name = "Rebind actions"
        thread.qualityOfService = .userInitiated
        thread.start()
    }

    func service(at now: UInt64) {
        guard !mailbox.state.withLock({ $0.stopped }) else { return }
        if lastCapabilitiesCheck == nil || now < (lastCapabilitiesCheck ?? 0)
            || now - (lastCapabilitiesCheck ?? 0) >= 1_000_000_000 {
            lastCapabilitiesCheck = now
            mailbox.updateAudioCapabilities(capabilities())
        }
        guard !secureInput() else { mailbox.captureLost(status: .secureInput); return }
        guard postingAllowed() else { mailbox.captureLost(status: .permissionRequired); return }
        guard let dispatch = mailbox.nextAction() else { return }
        // Recheck after dequeue: configuration/edit/pause/capture-loss changes
        // invalidate waiting work. A call already accepted here cannot be recalled.
        guard postingAllowed() else { mailbox.captureLost(status: .permissionRequired); return }
        guard !secureInput() else { mailbox.captureLost(status: .secureInput); return }
        guard mailbox.dispatchIsCurrent(dispatch) else { return }
        let success: Bool
        switch dispatch.action {
        case .shortcut(let shortcut): success = sendShortcut(shortcut)
        case .media(let action):
            let mailbox = mailbox
            let postingAllowed = postingAllowed
            let secureInput = secureInput
            let result = performMedia(action) {
                mailbox.dispatchIsCurrent(dispatch) && postingAllowed() && !secureInput()
            }
            guard result != .cancelled else { return }
            success = result == .performed
        case .mouse(let action):
            let mailbox = mailbox
            let postingAllowed = postingAllowed
            let secureInput = secureInput
            let result = performMouse(action) {
                mailbox.dispatchIsCurrent(dispatch) && postingAllowed() && !secureInput()
            }
            guard result != .cancelled else { return }
            success = result == .performed
        case .desktop: success = false // Legacy decoding only; cannot enter compiled rules.
        case .dock(let action):
            let mailbox = mailbox
            let postingAllowed = postingAllowed
            let secureInput = secureInput
            let result = performDock(action) {
                mailbox.dispatchIsCurrent(dispatch) && postingAllowed() && !secureInput()
            }
            guard result != .cancelled else { return }
            success = result == .performed
        case .system(let action):
            guard let device = dispatch.deviceID else { mailbox.actionFailed(dispatch); return }
            success = performAudio(action, device)
        case .window(let action):
            let mailbox = mailbox
            let postingAllowed = postingAllowed
            let secureInput = secureInput
            let result = performWindow(action) {
                mailbox.dispatchIsCurrent(dispatch) && postingAllowed() && !secureInput()
            }
            guard result != .cancelled else { return }
            success = result == .performed
        case .windowLayout(let action):
            let mailbox = mailbox
            let postingAllowed = postingAllowed
            let secureInput = secureInput
            let clock = layoutClock
            let snapshot = mailbox.state.withLock { $0.windowDisplays }
            guard snapshot.isFresh(at: clock()) else { mailbox.actionFailed(dispatch); return }
            let result = performWindowLayout(action, snapshot.displays) {
                let current = mailbox.state.withLock { $0.windowDisplays }
                return current.displays == snapshot.displays && current.isFresh(at: clock())
                    && mailbox.dispatchIsCurrent(dispatch) && postingAllowed() && !secureInput()
            }
            guard result != .cancelled else { return }
            success = result == .performed
        case .workspace(let action):
            guard let target = prepareWorkspace(action) else { mailbox.actionFailed(dispatch); return }
            // Preparation can wait on filesystem metadata. The MainActor
            // consumer also rechecks immediately before the native request.
            mailbox.submitWorkspace(WorkspaceRequest(dispatch: dispatch, target: target))
            return
        case .appleShortcut(let target):
            let mailbox = mailbox
            let postingAllowed = postingAllowed
            let secureInput = secureInput
            mailbox.state.withLock { $0.appleShortcutInProgress = true }
            defer { mailbox.state.withLock { $0.appleShortcutInProgress = false } }
            let result = performAppleShortcut(target) {
                mailbox.dispatchIsCurrent(dispatch) && postingAllowed() && !secureInput()
            }
            guard result != .cancelled else { return }
            success = result == .performed
        }
        if !success {
            mailbox.actionFailed(dispatch)
            // Detect output replacement/property loss promptly, without retrying
            // an action or replaying the already consumed original input.
            if case .system = dispatch.action { mailbox.updateAudioCapabilities(capabilities()) }
        }
    }
}
