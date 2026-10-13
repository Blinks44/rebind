import Foundation
import Testing
import Synchronization
@testable import rebind

@MainActor struct PreviousApplicationDispatchTests {
    private let action = RebindAction.workspace(.previousApplication)

    @Test(arguments: [InputTrigger.key(0), .mouseButton(99), .scroll(.up), .mouseGesture(button: 99, direction: .left)])
    func parameterlessActionMatchesAllInputFamiliesExactly(_ trigger: InputTrigger) throws {
        let kind = ActionKind(action: action)
        #expect(kind.category == .windows && !kind.needsWorkspaceParameters)
        #expect(kind.configuredAction(shortcut: nil) == action && action.shortcut == nil)
        #expect(kind.isAvailable(with: .init()) && AudioOutputCapabilities().supports(action))
        #expect(WorkspacePreparation.prepare(.previousApplication) == .previousApplication)
        #expect(try JSONDecoder().decode(RebindAction.self, from: JSONEncoder().encode(action)) == action)
        var matcher = InputMatcher()
        let rules = InputMatcher.compile([rebind.Binding(scope: trigger.scope, trigger: trigger, modifiers: .control, action: action)])
        let source = trigger.pressSource, phase: InputEvent.Phase = trigger.isScroll ? .scroll : .down
        #expect(!matcher.handle(InputEvent(trigger: source, phase: phase), rules: rules, enabled: true).suppress)
        var result = matcher.handle(InputEvent(trigger: source, modifiers: .control, phase: phase), rules: rules, enabled: true)
        if trigger.isPointerGesture {
            result = matcher.handle(InputEvent(trigger: source, modifiers: .control, phase: .drag,
                motion: .init(deltaX: -50, deltaY: 0)), rules: rules, enabled: true)
        }
        #expect(result.suppress && result.action == action)
        if !trigger.isScroll { #expect(matcher.handle(InputEvent(trigger: source, phase: .up), rules: rules, enabled: true).suppress) }
        #expect(!matcher.handle(InputEvent(trigger: source, modifiers: .control, phase: phase, isSynthetic: true), rules: rules, enabled: true).suppress)
    }

    @Test func workerHandsOffToOneBoundedWorkspaceSlotWithoutKeysOrLaunching() {
        let mailbox = ready()
        let worker = ActionWorker(mailbox: mailbox, capabilities: { .init() },
            sendShortcut: { _ in Issue.record("App switch posted keys"); return false },
            secureInput: { false }, postingAllowed: { true })
        #expect(mailbox.handle(InputEvent(trigger: .mouseButton(3), phase: .down), secureInput: false))
        worker.service(at: 0)
        #expect(mailbox.state.withLock { $0.workspaceRequest?.target } == .previousApplication)
        #expect(mailbox.nextAction() == nil)
        #expect(mailbox.handle(InputEvent(trigger: .mouseButton(3), phase: .up), secureInput: false))
    }

    @Test(arguments: [WindowActionResult.performed, .cancelled, .unavailable])
    func mainActorRoutingReportsOnlyRejectedCurrentRequests(_ result: WindowActionResult) async throws {
        let mailbox = try queued()
        var calls = 0
        let executor = WorkspaceActionExecutor(mailbox: mailbox, previousApplication: { canPerform in
            #expect(canPerform()); calls += 1; return result
        }, openApplication: { _ in Issue.record("App switch cold-launched") },
           openDocument: { _ in Issue.record("App switch opened a URL") },
           activateApplication: { _ in Issue.record("App switch selected a bundle path"); return false },
           secureInput: { false }, postingAllowed: { true })
        await executor.service()
        #expect(calls == 1)
        #expect(mailbox.state.withLock { $0.actionFailed } == (result == .unavailable ? action : nil))
        #expect(mailbox.state.withLock { $0.workspaceRequest == nil && $0.enabled && !$0.emergencyPause })
    }

    @Test(arguments: 0...7) func lifecycleAndProtectedChangesCancelTheFinalActivationGate(_ change: Int) async throws {
        let mailbox = try queued()
        let secure = Mutex(false), allowed = Mutex(true)
        let executor = WorkspaceActionExecutor(mailbox: mailbox, previousApplication: { canPerform in
            #expect(canPerform())
            switch change {
            case 0: mailbox.configure(Configuration(isEnabled: false))
            case 1: mailbox.configure(Configuration(isEnabled: true))
            case 2: mailbox.setEditing(true)
            case 3: mailbox.record(.init(target: .mouseTrigger))
            case 4: mailbox.suspend(true)
            case 5: mailbox.stop()
            case 6: secure.withLock { $0 = true }
            default: allowed.withLock { $0 = false }
            }
            #expect(!canPerform()); return .cancelled
        }, secureInput: { secure.withLock { $0 } }, postingAllowed: { allowed.withLock { $0 } })
        await executor.service()
        #expect(mailbox.state.withLock { $0.actionFailed == nil && $0.workspaceRequest == nil })
    }

    @Test func lateFailureCannotOverwriteANewProfile() async throws {
        let mailbox = try queued()
        await WorkspaceActionExecutor(mailbox: mailbox, previousApplication: { _ in
            mailbox.configure(Configuration(isEnabled: true)); return .unavailable
        }, secureInput: { false }, postingAllowed: { true }).service()
        #expect(mailbox.state.withLock { $0.actionFailed == nil })
    }

    @Test func awaitingActivationKeepsSlotAndCancelsAfterProfileChange() async throws {
        let mailbox = try queued()
        await WorkspaceActionExecutor(mailbox: mailbox, previousApplication: { canPerform in
            #expect(canPerform())
            mailbox.state.withLock { $0.pending = [.window(.close)] }
            await Task.yield()
            #expect(mailbox.nextAction() == nil)
            await WorkspaceActionExecutor(mailbox: mailbox, previousApplication: { _ in
                Issue.record("A second app switch overtook the first"); return .performed
            }, secureInput: { false }, postingAllowed: { true }).service()
            mailbox.configure(Configuration(isEnabled: true))
            #expect(!canPerform())
            return .cancelled
        }, secureInput: { false }, postingAllowed: { true }).service()
        #expect(mailbox.state.withLock { $0.workspaceRequest == nil && !$0.workspaceClaimed && $0.actionFailed == nil })
    }

    @Test func localizedLabelAndFailureDescribePreviousApplication() {
        let model = AppModel(loadConfiguration: false, sessionAllowsInput: { true })
        model.mailbox.state.withLock { $0.actionFailed = action }
        model.refresh()
        #expect(model.error == .previousApplicationFailed)
        #expect(action.label == String(localized: .previousApplicationAction))
    }

    private func ready() -> EngineMailbox {
        let mailbox = EngineMailbox()
        mailbox.configure(Configuration(isEnabled: true, bindings: [.init(scope: .allMice, trigger: .mouseButton(3), modifiers: [], action: action)]))
        mailbox.state.withLock { $0.status = .active }
        return mailbox
    }

    private func queued() throws -> EngineMailbox {
        let mailbox = ready()
        mailbox.state.withLock { $0.pending = [action] }
        let dispatch = try #require(mailbox.nextAction())
        mailbox.submitWorkspace(.init(dispatch: dispatch, target: .previousApplication))
        return mailbox
    }
}
