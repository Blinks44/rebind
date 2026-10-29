import Foundation
import Synchronization
import Testing
@testable import rebind

struct ScreenLockTests {
    @Test(arguments: 0...2) func unavailableAndCancelledRequestsNeverInvokeLock(_ scenario: Int) {
        var allowed = scenario != 0, resolved = 0, invoked = 0
        let result = ScreenLockExecutor.perform(canPerform: { allowed }, resolveRequest: {
            resolved += 1
            if scenario == 1 { return nil }
            allowed = false
            return { invoked += 1 }
        })
        #expect(result == (scenario == 1 ? .unavailable : .cancelled))
        #expect(resolved == (scenario == 0 ? 0 : 1) && invoked == 0)
    }

    @Test func currentRequestInvokesExactlyOnceWithoutInventingAcknowledgement() {
        var invoked = 0
        #expect(ScreenLockExecutor.perform(canPerform: { true }, resolveRequest: { { invoked += 1 } }) == .performed)
        #expect(invoked == 1)
    }

    // macOS went from 15 to 26; the range has no other real majors.
    @Test(arguments: [14, 15, 26, 27, 28]) func privateAdapterLimitsReviewedSystemVersions(_ major: Int) {
        #expect(ScreenLockExecutor.supportsSystemVersion(major) == [15, 26, 27].contains(major))
    }

    @Test @MainActor func catalogAndPayloadNeedNoShortcutOrAudioDevice() throws {
        let action = RebindAction.lockScreen, kind = ActionKind(action: action)
        #expect(kind.category == .system && kind.configuredAction(shortcut: nil) == action)
        #expect(action.isSupported && action.shortcut == nil && !kind.needsWorkspaceParameters)
        #expect(kind.isAvailable(with: .init(screenLock: true)))
        #expect(!kind.isAvailable(with: .init(screenLock: false)))
        #expect(action.label == String(localized: .lockScreenAction))
        #expect(kind.unavailableMessage == .lockScreenUnavailable)
        #expect(try JSONDecoder().decode(RebindAction.self, from: JSONEncoder().encode(action)) == action)
    }

    @Test(arguments: [InputTrigger.key(0), .mouseButton(99), .scroll(.up), .mouseGesture(button: 99, direction: .left)])
    func allSourceFamiliesKeepExactModifierAndSyntheticRules(_ trigger: InputTrigger) {
        var matcher = InputMatcher()
        let rules = InputMatcher.compile([rebind.Binding(scope: trigger.scope, trigger: trigger, modifiers: .control, action: .lockScreen)])
        let source = trigger.pressSource, phase: InputEvent.Phase = trigger.isScroll ? .scroll : .down
        #expect(!matcher.handle(InputEvent(trigger: source, phase: phase), rules: rules, enabled: true).suppress)
        var result = matcher.handle(InputEvent(trigger: source, modifiers: .control, phase: phase), rules: rules, enabled: true)
        if trigger.isPointerGesture {
            result = matcher.handle(InputEvent(trigger: source, modifiers: .control, phase: .drag,
                motion: .init(deltaX: -50, deltaY: 0)), rules: rules, enabled: true)
        }
        #expect(result.suppress && result.action == .lockScreen)
        if !trigger.isScroll { #expect(matcher.handle(InputEvent(trigger: source, phase: .up), rules: rules, enabled: true).suppress) }
        #expect(!matcher.handle(InputEvent(trigger: source, modifiers: .control, phase: phase, isSynthetic: true), rules: rules, enabled: true).suppress)
    }

    @Test func unavailableLockRulePassesThroughAndDoesNotConsumeSource() {
        let mailbox = ready()
        mailbox.updateAudioCapabilities(.init(screenLock: false))
        #expect(!mailbox.handle(InputEvent(trigger: .mouseButton(3), phase: .down), secureInput: false))
        #expect(!mailbox.handle(InputEvent(trigger: .mouseButton(3), phase: .up), secureInput: false))
        #expect(mailbox.state.withLock { $0.pending.isEmpty && !$0.matcher.hasSuppressedInput })
    }

    @Test(arguments: [WindowActionResult.performed, .cancelled, .unavailable])
    func workerRoutesLockSeparatelyAndDropsQueueAndDiagnosticsOnlyAfterCall(_ result: WindowActionResult) {
        let mailbox = ready(), calls = Mutex(0)
        let worker = ActionWorker(mailbox: mailbox, capabilities: { .init(screenLock: true) },
            sendShortcut: { _ in Issue.record("Lock posted keys"); return false }, requestLock: { canPerform in
                #expect(canPerform()); calls.withLock { $0 += 1 }; return result
            }, requestSleep: { _ in Issue.record("Lock requested sleep"); return .unavailable },
            secureInput: { false }, postingAllowed: { true })
        #expect(mailbox.startDiagnostics(at: 0))
        #expect(mailbox.handle(InputEvent(trigger: .mouseButton(3), phase: .down, receivedAt: 1), secureInput: false))
        #expect(mailbox.state.withLock { !$0.diagnostics.snapshot().entries.isEmpty })
        mailbox.state.withLock { $0.pending.append(.media(.playPause)) }
        let revision = mailbox.state.withLock { $0.actionRevision }
        worker.service(at: 0)
        #expect(calls.withLock { $0 } == 1)
        #expect(mailbox.state.withLock { $0.actionFailed } == (result == .unavailable ? .lockScreen : nil))
        #expect(mailbox.state.withLock { $0.pending } == (result == .performed ? [] : [.media(.playPause)]))
        #expect(mailbox.state.withLock { $0.actionRevision } == revision + (result == .performed ? 1 : 0))
        #expect(mailbox.state.withLock { $0.enabled && !$0.emergencyPause && !$0.suspended })
        if result == .performed {
            let snapshot = mailbox.state.withLock { $0.diagnostics.snapshot() }
            #expect(!snapshot.isRunning && snapshot.entries.isEmpty)
        }
        #expect(mailbox.handle(InputEvent(trigger: .mouseButton(3), phase: .up), secureInput: false))
    }

    @Test(arguments: 0...7) func finalGateCancelsLifecycleAndProtectedChanges(_ change: Int) {
        let mailbox = ready(), secure = Mutex(false), allowed = Mutex(true)
        let worker = ActionWorker(mailbox: mailbox, capabilities: { .init(screenLock: true) }, requestLock: { canPerform in
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
        mailbox.state.withLock { $0.pending = [.lockScreen] }
        worker.service(at: 0)
        #expect(mailbox.state.withLock { $0.actionFailed == nil })
    }

    @Test func oldLockReturnDoesNotDiscardNewProfileWork() throws {
        let mailbox = ready()
        mailbox.state.withLock { $0.pending = [.lockScreen] }
        let dispatch = try #require(mailbox.nextAction())
        mailbox.configure(Configuration(isEnabled: true))
        mailbox.state.withLock { $0.pending = [.media(.nextTrack)] }
        let revision = mailbox.state.withLock { $0.actionRevision }
        mailbox.systemTransitionRequested(dispatch)
        #expect(mailbox.state.withLock { $0.actionRevision == revision && $0.pending == [.media(.nextTrack)] })
    }

    @Test(arguments: 1...18) func olderSchemasRejectLockIncludingInactiveProfiles(_ version: Int) throws {
        let binding = rebind.Binding(scope: .allMice, trigger: .mouseButton(3), modifiers: [], action: .lockScreen)
        var old = Configuration(bindings: version < 6 ? [binding] : [])
        if version >= 6 { old.profiles.append(RuleProfile(name: "Inactive", bindings: [binding])) }
        old.schemaVersion = version
        let decoded = try JSONDecoder().decode(Configuration.self, from: JSONEncoder().encode(old))
        #expect(throws: ConfigurationError.invalid) { try decoded.migrated() }
    }

    @Test func schema18MigrationRetainsSleepProfilesAndFileUntilSave() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: "RebindLockStore-\(UUID())")
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let store = ConfigurationStore(url: directory.appending(path: "config.json"))
        var old = Configuration(isEnabled: true, bindings: [.init(scope: .allMice, trigger: .mouseButton(3), modifiers: .control,
            action: .sleepSystem, activation: .hold, holdDurationMilliseconds: 1000)])
        try old.createProfile(name: "Other", copying: old.selectedProfileID)
        old.schemaVersion = 18
        let bytes = try JSONEncoder().encode(old)
        try bytes.write(to: store.url)
        var loaded = try store.load()
        #expect(loaded.profiles == old.profiles && loaded.selectedProfileID == old.selectedProfileID && loaded.isEnabled)
        #expect(try Data(contentsOf: store.url) == bytes)
        loaded.bindings[0].action = .lockScreen
        try store.save(loaded)
        #expect(try store.load() == loaded)
    }

    @Test @MainActor func unavailableLockReportsSpecificLocalizedError() {
        let model = AppModel(loadConfiguration: false, sessionAllowsInput: { true })
        model.mailbox.state.withLock { $0.actionFailed = .lockScreen }
        model.refresh()
        #expect(model.error == .lockScreenFailed)
    }

    private func ready() -> EngineMailbox {
        let mailbox = EngineMailbox()
        mailbox.updateAudioCapabilities(.init(screenLock: true))
        mailbox.configure(Configuration(isEnabled: true, bindings: [.init(scope: .allMice, trigger: .mouseButton(3), modifiers: [], action: .lockScreen)]))
        mailbox.state.withLock { $0.status = .active }
        return mailbox
    }
}
