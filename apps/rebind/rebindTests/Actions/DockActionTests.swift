import Foundation
import Synchronization
import Testing
@testable import rebind

struct DockActionTests {
    @Test(arguments: [DesktopAction.missionControl, .applicationWindows, .showDesktop])
    func directActionsSendOnlyTheirFixedNotification(_ action: DesktopAction) throws {
        let notification = try #require(action.dockNotification)
        var sent: [String] = []
        let result = DockActions.perform(action, canPerform: { true }, send: { sent.append($0); return true })
        #expect(result == .performed && sent == [notification])
        #expect(action.dockNotification != nil)
        #expect(RebindAction.dock(action).isSupported)
        #expect(ActionKind(action: .dock(action)).configuredAction(shortcut: nil) == .dock(action))
    }

    @Test func cancellationInvalidTargetAndNativeFailureNeverUseKeyboardFallback() {
        var calls = 0
        #expect(DockActions.perform(.missionControl, canPerform: { false }, send: { _ in calls += 1; return true }) == .cancelled)
        #expect(DockActions.perform(.nextSpace, canPerform: { false }, send: { _ in calls += 1; return true }) == .cancelled)
        #expect(calls == 0)
        #expect(DockActions.perform(.showDesktop, canPerform: { true }, send: { _ in calls += 1; return false }) == .unavailable)
        #expect(calls == 1 && RebindAction.dock(.nextSpace).isSupported)
    }

    @Test(arguments: [11, 12]) func legacySchemasConvertAllDesktopActionsWithoutRewritingOriginal(_ schema: Int) throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: "RebindDock-\(UUID())")
        defer { try? FileManager.default.removeItem(at: folder) }
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let store = ConfigurationStore(url: folder.appending(path: "config.json"))
        let custom = KeyboardShortcut(keyCode: 99, modifiers: .option)
        var old = Configuration(isEnabled: true, bindings: DesktopAction.allCases.enumerated().map { i, action in
            rebind.Binding(scope: .allMice, trigger: .mouseButton(UInt32(i + 2)), modifiers: .control,
                           action: .dock(action))
        })
        try old.createProfile(name: "Other", copying: old.selectedProfileID)
        old.schemaVersion = schema
        for profile in old.profiles.indices {
            for index in old.profiles[profile].bindings.indices {
                if case .dock(let action) = old.profiles[profile].bindings[index].action,
                   schema == 11 || action.isSpaceNavigation {
                    old.profiles[profile].bindings[index].action = .desktop(action, shortcut: custom)
                }
            }
        }
        let bytes = try JSONEncoder().encode(old)
        try bytes.write(to: store.url)
        let loaded = try store.load()
        #expect(try Data(contentsOf: store.url) == bytes)
        #expect(loaded.isEnabled && loaded.selectedProfileID == old.selectedProfileID)
        #expect(loaded.profiles.map(\.id) == old.profiles.map(\.id))
        for (before, after) in zip(old.profiles, loaded.profiles) {
            #expect(before.bindings.map(\.id) == after.bindings.map(\.id))
            for (oldRule, rule) in zip(before.bindings, after.bindings) {
                var expected = oldRule
                if case .desktop(let action, _) = oldRule.action { expected.action = .dock(action) }
                #expect(rule == expected)
            }
        }
        try store.save(loaded)
        #expect(try store.load() == loaded)
    }

    @Test(arguments: 1...11)
    func nativePayloadCannotMasqueradeAsOldSchema(_ schema: Int) throws {
        var configuration = Configuration(bindings: schema < 6 ? [nativeBinding()] : [])
        if schema >= 6 { configuration.profiles.append(RuleProfile(name: "Inactive", bindings: [nativeBinding()])) }
        configuration.schemaVersion = schema
        let decoded = try JSONDecoder().decode(Configuration.self, from: JSONEncoder().encode(configuration))
        #expect(throws: ConfigurationError.invalid) { try decoded.migrated() }
    }

    @Test func workerRoutesNativeActionWithoutAnyKeyPostingAndDoesNotPauseOnFailure() {
        let mailbox = EngineMailbox()
        mailbox.configure(Configuration(isEnabled: true, bindings: [nativeBinding()]))
        mailbox.state.withLock { $0.status = .active; $0.pending = [.dock(.missionControl)] }
        let calls = Mutex(0)
        let worker = ActionWorker(mailbox: mailbox, capabilities: { AudioOutputCapabilities() },
            sendShortcut: { _ in Issue.record("Native Dock action emitted a key"); return false },
            performDock: { action, allowed in
                #expect(action == .missionControl && allowed())
                calls.withLock { $0 += 1 }; return .unavailable
            }, secureInput: { false }, postingAllowed: { true })
        worker.service(at: 0)
        #expect(calls.withLock { $0 } == 1)
        #expect(mailbox.state.withLock { $0.enabled && !$0.emergencyPause && $0.actionFailed == .dock(.missionControl) })
    }

    @Test func generationChangeBeforeMutationCancelsNativeActionAndLateError() {
        let mailbox = EngineMailbox()
        mailbox.configure(Configuration(isEnabled: true))
        mailbox.state.withLock { $0.status = .active; $0.pending = [.dock(.showDesktop)] }
        let worker = ActionWorker(mailbox: mailbox, capabilities: { AudioOutputCapabilities() },
            performDock: { _, allowed in
                #expect(allowed())
                mailbox.setEditing(true)
                #expect(allowed() == false)
                return .unavailable
            }, secureInput: { false }, postingAllowed: { true })
        worker.service(at: 0)
        #expect(mailbox.state.withLock { $0.actionFailed == nil && $0.pending.isEmpty })
    }

    @MainActor @Test func nativeLabelsHaveNoRetiredChordAndFailuresReachUI() {
        let action = RebindAction.dock(.missionControl)
        #expect(action.label == String(localized: .missionControlAction))
        let model = AppModel(loadConfiguration: false)
        model.mailbox.state.withLock { $0.actionFailed = action }
        model.refresh()
        #expect(model.error == .dockActionFailed)
    }

    private func nativeBinding() -> rebind.Binding {
        rebind.Binding(scope: .allMice, trigger: .mouseButton(3), modifiers: [], action: .dock(.missionControl))
    }
}
