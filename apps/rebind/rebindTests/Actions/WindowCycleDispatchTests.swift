import Foundation
import Synchronization
import Testing
@testable import rebind

struct WindowCycleDispatchTests {
    @Test(arguments: WindowCycleAction.allCases, [InputTrigger.key(0), .mouseButton(99), .scroll(.up), .mouseGesture(button: 99, direction: .left)])
    func sharedCatalogAndExactMatchingIncludeAllCurrentInputFamilies(_ action: WindowCycleAction, _ trigger: InputTrigger) throws {
        let configured = RebindAction.windowCycle(action), kind = ActionKind(action: configured)
        #expect(kind.category == .windows && kind.windowCycleAction == action)
        #expect(kind.configuredAction(shortcut: nil) == configured && configured.shortcut == nil)
        #expect(kind.isAvailable(with: .init()) && AudioOutputCapabilities().supports(configured))
        #expect(try JSONDecoder().decode(RebindAction.self, from: JSONEncoder().encode(configured)) == configured)
        var matcher = InputMatcher()
        let rules = InputMatcher.compile([rebind.Binding(scope: trigger.scope, trigger: trigger, modifiers: .control, action: configured)])
        let source = trigger.pressSource, phase: InputEvent.Phase = trigger.isScroll ? .scroll : .down
        #expect(!matcher.handle(InputEvent(trigger: source, phase: phase), rules: rules, enabled: true).suppress)
        var result = matcher.handle(InputEvent(trigger: source, modifiers: .control, phase: phase), rules: rules, enabled: true)
        if trigger.isPointerGesture {
            result = matcher.handle(InputEvent(trigger: source, modifiers: .control, phase: .drag,
                motion: .init(deltaX: -50, deltaY: 0)), rules: rules, enabled: true)
        }
        #expect(result.suppress && result.action == configured)
        if !trigger.isScroll { #expect(matcher.handle(InputEvent(trigger: source, phase: .up), rules: rules, enabled: true).suppress) }
        #expect(!matcher.handle(InputEvent(trigger: source, modifiers: .control, phase: phase, isSynthetic: true), rules: rules, enabled: true).suppress)
    }

    @Test(arguments: [WindowActionResult.performed, .cancelled, .unavailable])
    func serialWorkerUsesCycleBackendAndReportsOnlyCurrentFailure(_ result: WindowActionResult) {
        let mailbox = ready(), calls = Mutex(0)
        let worker = ActionWorker(mailbox: mailbox, capabilities: { .init() },
            sendShortcut: { _ in Issue.record("Cycle posted keys"); return false },
            performWindow: { _, _ in Issue.record("Cycle performed another window action"); return .unavailable },
            performWindowCycle: { action, canPerform in
                #expect(action == .next && canPerform()); calls.withLock { $0 += 1 }; return result
            }, secureInput: { false }, postingAllowed: { true })
        #expect(mailbox.handle(InputEvent(trigger: .mouseButton(3), phase: .down), secureInput: false))
        worker.service(at: 0)
        #expect(calls.withLock { $0 } == 1)
        #expect(mailbox.state.withLock { $0.actionFailed } == (result == .unavailable ? .windowCycle(.next) : nil))
        #expect(mailbox.state.withLock { $0.enabled && !$0.emergencyPause })
        #expect(mailbox.handle(InputEvent(trigger: .mouseButton(3), phase: .up), secureInput: false))
    }

    @Test(arguments: 0...7) func lifecycleAndProtectedChangesCancelFinalCycleGate(_ change: Int) {
        let mailbox = ready(), secure = Mutex(false), allowed = Mutex(true)
        let worker = ActionWorker(mailbox: mailbox, capabilities: { .init() }, performWindowCycle: { _, canPerform in
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
        mailbox.state.withLock { $0.pending = [.windowCycle(.next)] }
        worker.service(at: 0)
        #expect(mailbox.state.withLock { $0.actionFailed == nil })
    }

    @Test func nativeCycleFailureCannotOverwriteNewProfileState() {
        let mailbox = ready()
        let worker = ActionWorker(mailbox: mailbox, capabilities: { .init() }, performWindowCycle: { _, _ in
            mailbox.configure(Configuration(isEnabled: true)); return .unavailable
        }, secureInput: { false }, postingAllowed: { true })
        mailbox.state.withLock { $0.pending = [.windowCycle(.next)] }
        worker.service(at: 0)
        #expect(mailbox.state.withLock { $0.actionFailed == nil })
    }

    @Test @MainActor func localizedFailureNamesWindowSwitching() {
        let model = AppModel(loadConfiguration: false, sessionAllowsInput: { true })
        model.mailbox.state.withLock { $0.actionFailed = .windowCycle(.previous) }
        model.refresh()
        #expect(model.error == .windowCycleFailed)
        #expect(RebindAction.windowCycle(.next).label == String(localized: .nextWindowAction))
        #expect(RebindAction.windowCycle(.previous).label == String(localized: .previousWindowAction))
    }

    private func ready() -> EngineMailbox {
        let mailbox = EngineMailbox()
        mailbox.configure(Configuration(isEnabled: true, bindings: [.init(scope: .allMice, trigger: .mouseButton(3), modifiers: [], action: .windowCycle(.next))]))
        mailbox.state.withLock { $0.status = .active }
        return mailbox
    }
}
