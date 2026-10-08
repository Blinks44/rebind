import Foundation
import Testing
@testable import rebind

@MainActor struct WorkspaceDispatchTests {
    private let url = URL(filePath: "/tmp/RebindTestDocument.txt")

    private func queued() throws -> (EngineMailbox, WorkspaceRequest) {
        let mailbox = EngineMailbox()
        let binding = rebind.Binding(scope: .allMice, trigger: .mouseButton(3), modifiers: [], action: .workspace(.openFile(url)))
        mailbox.configure(Configuration(isEnabled: true, bindings: [binding]))
        mailbox.state.withLock { $0.status = .active }
        #expect(mailbox.handle(InputEvent(trigger: .mouseButton(3), phase: .down), secureInput: false))
        let dispatch = try #require(mailbox.nextAction())
        let request = WorkspaceRequest(dispatch: dispatch, target: .document(url))
        mailbox.submitWorkspace(request)
        return (mailbox, request)
    }

    @Test func workerPreparesOnItsSerialPathAndNeverPostsWorkspaceActions() throws {
        let (mailbox, request) = try queued()
        mailbox.finishWorkspace(request, failed: false)
        mailbox.state.withLock { $0.pending = [request.dispatch.action] }
        let worker = ActionWorker(mailbox: mailbox, capabilities: { AudioOutputCapabilities() },
            performAudio: { _, _ in Issue.record("Workspace action reached audio"); return false },
            sendShortcut: { _ in Issue.record("Workspace action reached keyboard"); return false },
            performWindow: { _, _ in Issue.record("Workspace action reached AX"); return .unavailable },
            prepareWorkspace: { action in .document(action.url) }, secureInput: { false }, postingAllowed: { true })
        worker.service(at: 0)
        #expect(mailbox.hasWorkspaceRequest)
        #expect(mailbox.state.withLock { $0.workspaceRequest?.target } == .document(url))
        #expect(mailbox.state.withLock { $0.pending.isEmpty })
    }

    @Test func preparationFailureReportsWithoutPausingAndPreparationCancellationNeverSubmits() throws {
        for fail in [true, false] {
            let (mailbox, request) = try queued()
            mailbox.finishWorkspace(request, failed: false)
            mailbox.state.withLock { $0.pending = [request.dispatch.action] }
            let worker = ActionWorker(mailbox: mailbox, capabilities: { AudioOutputCapabilities() },
                prepareWorkspace: { action in
                    if fail { return nil }
                    mailbox.setEditing(true)
                    return .document(action.url)
                }, secureInput: { false }, postingAllowed: { true })
            worker.service(at: 0)
            #expect(mailbox.hasWorkspaceRequest == false)
            #expect(mailbox.state.withLock { $0.actionFailed } == (fail ? request.dispatch.action : nil))
            #expect(mailbox.state.withLock { $0.enabled && !$0.emergencyPause })
        }
    }

    @Test(arguments: 0...5)
    func cancellationBeforeClaimPreventsNativeCalls(_ change: Int) async throws {
        let (mailbox, _) = try queued()
        switch change {
        case 0:
            var configuration = Configuration(isEnabled: true)
            try configuration.createProfile(name: "New")
            mailbox.configure(configuration)
        case 1: mailbox.configure(Configuration(isEnabled: false))
        case 2: mailbox.setEditing(true)
        case 3: mailbox.record(RecordingRequest(target: .mouseTrigger))
        case 4: mailbox.suspend(true)
        default: mailbox.stop()
        }
        let executor = WorkspaceActionExecutor(mailbox: mailbox,
            openApplication: { _ in Issue.record("Stale app opened") },
            openDocument: { _ in Issue.record("Stale file opened") },
            activateApplication: { _ in Issue.record("Stale app activated"); return true },
            secureInput: { false }, postingAllowed: { true })
        await executor.service()
        #expect(mailbox.state.withLock { $0.workspaceRequest == nil && $0.workspaceClaimed == false && $0.actionFailed == nil })
        #expect(mailbox.handle(InputEvent(trigger: .mouseButton(3), phase: .up), secureInput: false) || change == 4 || change == 5)
    }

    @Test func oneClaimPreservesOrderingAndDuplicateAcknowledgementsCannotClearTheNextRequest() throws {
        let (mailbox, request) = try queued()
        mailbox.state.withLock { $0.pending = [.window(.close)] }
        #expect(mailbox.nextAction() == nil)
        #expect(mailbox.claimWorkspace() == request)
        #expect(mailbox.claimWorkspace() == nil)
        #expect(mailbox.nextAction() == nil)
        mailbox.finishWorkspace(request, failed: false)
        #expect(mailbox.nextAction()?.action == .window(.close))
        var next = request
        next.dispatch.id = UUID()
        mailbox.submitWorkspace(next)
        mailbox.finishWorkspace(request, failed: true)
        #expect(mailbox.state.withLock { $0.workspaceRequest } == next)
        #expect(mailbox.state.withLock { $0.actionFailed == nil })
        mailbox.finishWorkspace(next, failed: false)
    }

    @Test(arguments: [true, false])
    func protectedContextsBetweenPreparationAndNativeRequestNeverOpen(_ secure: Bool) async throws {
        let (mailbox, _) = try queued()
        let executor = WorkspaceActionExecutor(mailbox: mailbox,
            openDocument: { _ in Issue.record("Opened in protected context") },
            secureInput: { secure }, postingAllowed: { secure })
        await executor.service()
        #expect(mailbox.state.withLock { $0.workspaceRequest == nil && $0.pending.isEmpty })
        #expect(mailbox.state.withLock { $0.status } == (secure ? .secureInput : .permissionRequired))
    }

    @Test(arguments: 0...2)
    func nativeRoutingReportsCompletionAndDoesNotColdLaunchActivation(_ kind: Int) async throws {
        let (mailbox, original) = try queued()
        mailbox.finishWorkspace(original, failed: false)
        let app = ApplicationTarget(url: URL(filePath: "/Applications/Example.app"), bundleIdentifier: "org.example.app")
        let target: WorkspaceTarget = kind == 2 ? .document(url) : .application(app, activateOnly: kind == 1)
        mailbox.submitWorkspace(WorkspaceRequest(dispatch: original.dispatch, target: target))
        var calls: [String] = []
        let executor = WorkspaceActionExecutor(mailbox: mailbox,
            openApplication: { _ in calls.append("open app") }, openDocument: { _ in calls.append("open document") },
            activateApplication: { _ in calls.append("activate"); return false }, secureInput: { false }, postingAllowed: { true })
        await executor.service()
        #expect(calls == [kind == 0 ? "open app" : kind == 1 ? "activate" : "open document"])
        #expect(mailbox.state.withLock { $0.actionFailed } == (kind == 1 ? original.dispatch.action : nil))
        #expect(mailbox.state.withLock { $0.workspaceRequest == nil && $0.enabled && !$0.emergencyPause })
    }

    @Test func stateChangesAcrossAwaitIgnoreOldErrorsAndKeepAcceptedWorkSerialized() async throws {
        let (mailbox, _) = try queued()
        let executor = WorkspaceActionExecutor(mailbox: mailbox, openDocument: { _ in
            mailbox.configure(Configuration(isEnabled: true))
            mailbox.state.withLock { $0.pending = [.window(.minimize)] }
            #expect(mailbox.nextAction() == nil)
            await WorkspaceActionExecutor(mailbox: mailbox, openDocument: { _ in Issue.record("Second request started") }).service()
            await Task.yield()
            #expect(mailbox.nextAction() == nil)
            throw NativeTestError.rejected
        }, secureInput: { false }, postingAllowed: { true })
        await executor.service()
        #expect(mailbox.state.withLock { $0.workspaceRequest == nil && !$0.workspaceClaimed && $0.actionFailed == nil })
        #expect(mailbox.nextAction()?.action == .window(.minimize))
    }

    @Test(arguments: [true, false])
    func nativeErrorReportsOnceWhileCancellationDoesNotReportFailure(_ fail: Bool) async throws {
        let (mailbox, request) = try queued()
        let executor = WorkspaceActionExecutor(mailbox: mailbox, openDocument: { _ in
            if fail { throw NativeTestError.rejected }
            throw CancellationError()
        }, secureInput: { false }, postingAllowed: { true })
        await executor.service()
        #expect(mailbox.state.withLock { $0.actionFailed } == (fail ? request.dispatch.action : nil))
        #expect(mailbox.state.withLock { $0.workspaceRequest == nil && $0.enabled && !$0.emergencyPause })
        #expect(mailbox.handle(InputEvent(trigger: .mouseButton(3), phase: .up), secureInput: false))
    }

    @Test func missingTargetFailureReachesLocalizedUI() {
        let model = AppModel(loadConfiguration: false)
        model.mailbox.state.withLock { $0.actionFailed = .workspace(.openFile(url)) }
        model.refresh()
        #expect(model.error == .workspaceActionFailed)
    }
}

nonisolated private enum NativeTestError: Error { case rejected }
