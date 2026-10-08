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
    private let performWindow: @Sendable (WindowAction, @Sendable () -> Bool) -> WindowActionResult
    private let prepareWorkspace: @Sendable (WorkspaceAction) -> WorkspaceTarget?
    private let secureInput: @Sendable () -> Bool
    private let postingAllowed: @Sendable () -> Bool
    private var lastCapabilitiesCheck: UInt64?

    init(mailbox: EngineMailbox,
         capabilities: @escaping @Sendable () -> AudioOutputCapabilities = { CoreAudioOutput.capabilities() },
         performAudio: @escaping @Sendable (SystemAction, UInt32) -> Bool = { CoreAudioOutput.perform($0, device: $1) },
         sendShortcut: @escaping @Sendable (KeyboardShortcut) -> Bool = { ShortcutSender.send($0) },
         performWindow: @escaping @Sendable (WindowAction, @Sendable () -> Bool) -> WindowActionResult = {
             WindowActionExecutor.perform($0, canPerform: $1)
         },
         prepareWorkspace: @escaping @Sendable (WorkspaceAction) -> WorkspaceTarget? = { WorkspacePreparation.prepare($0) },
         secureInput: @escaping @Sendable () -> Bool = { IsSecureEventInputEnabled() },
         postingAllowed: @escaping @Sendable () -> Bool = { CGPreflightPostEventAccess() }) {
        self.mailbox = mailbox
        self.capabilities = capabilities
        self.performAudio = performAudio
        self.sendShortcut = sendShortcut
        self.performWindow = performWindow
        self.prepareWorkspace = prepareWorkspace
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
        case .workspace(let action):
            guard let target = prepareWorkspace(action) else { mailbox.actionFailed(dispatch); return }
            // Preparation can wait on filesystem metadata. The MainActor
            // consumer also rechecks immediately before the native request.
            mailbox.submitWorkspace(WorkspaceRequest(dispatch: dispatch, target: target))
            return
        }
        if !success {
            mailbox.actionFailed(dispatch)
            // Detect output replacement/property loss promptly, without retrying
            // an action or replaying the already consumed original input.
            if case .system = dispatch.action { mailbox.updateAudioCapabilities(capabilities()) }
        }
    }
}
