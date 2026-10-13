import Foundation
import Testing
import Synchronization
@testable import rebind

@MainActor struct ApplicationCommandsTests {
    private let app = ApplicationTarget(url: URL(filePath: "/Applications/Example.app"), bundleIdentifier: "org.example.app")

    @Test func catalogUsesDistinctTypedActionsAndParameters() throws {
        #expect(ActionKind.quitApplication.configuredAction(shortcut: nil) == nil)
        let quit = try #require(ActionKind.quitApplication.configuredAction(shortcut: nil, application: app))
        let settings = try #require(ActionKind.openSystemSettings.configuredAction(shortcut: nil))
        #expect(quit == .workspace(.quitApplication(app)) && settings == .workspace(.openSystemSettings))
        #expect(ActionKind(action: quit).category == .windows && ActionKind(action: settings).category == .system)
        #expect(settings.label == String(localized: .openSystemSettingsAction))
        #expect(quit.label.contains(app.url.lastPathComponent))
        for action in [quit, settings] {
            #expect(AudioOutputCapabilities().supports(action))
            #expect(try JSONDecoder().decode(RebindAction.self, from: JSONEncoder().encode(action)) == action)
        }
    }

    @Test(arguments: [InputTrigger.key(0), .mouseButton(99), .scroll(.up), .mouseGesture(button: 99, direction: .left)])
    func bothActionsMatchExistingInputsWithExactModifiers(_ trigger: InputTrigger) {
        for action in [RebindAction.workspace(.quitApplication(app)), .workspace(.openSystemSettings)] {
            let rules = InputMatcher.compile([rebind.Binding(scope: trigger.scope, trigger: trigger, modifiers: .control, action: action)])
            var matcher = InputMatcher()
            let source = trigger.pressSource
            let phase: InputEvent.Phase = trigger.isScroll ? .scroll : .down
            #expect(!matcher.handle(InputEvent(trigger: source, phase: phase), rules: rules, enabled: true).suppress)
            var decision = matcher.handle(InputEvent(trigger: source, modifiers: .control, phase: phase), rules: rules, enabled: true)
            if trigger.isPointerGesture {
                decision = matcher.handle(InputEvent(trigger: source, modifiers: .control, phase: .drag,
                    motion: .init(deltaX: -50, deltaY: 0)), rules: rules, enabled: true)
            }
            #expect(decision.suppress && decision.action == action)
            if !trigger.isScroll { #expect(matcher.handle(InputEvent(trigger: source, phase: .up), rules: rules, enabled: true).suppress) }
        }
    }

    @Test func metadataPreparationChecksSettingsBundleAndQuitCopy() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: "RebindCommands-\(UUID())")
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appending(path: "Example.app", directoryHint: .isDirectory)
        let contents = url.appending(path: "Contents", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: contents, withIntermediateDirectories: true)
        let info = contents.appending(path: "Info.plist")
        func writeBundle(_ id: String) throws {
            let bytes = try PropertyListSerialization.data(fromPropertyList: ["CFBundleIdentifier": id, "CFBundlePackageType": "APPL"], format: .xml, options: 0)
            try bytes.write(to: info)
        }
        try writeBundle("org.example.app")
        let target = ApplicationTarget(url: url, bundleIdentifier: "org.example.app")
        #expect(WorkspacePreparation.prepare(.quitApplication(target)) == .quitApplication(target))
        #expect(WorkspacePreparation.prepare(.openSystemSettings, settingsApplication: { nil }) == nil)
        #expect(WorkspacePreparation.prepare(.openSystemSettings, settingsApplication: { url }) == nil)
        let settingsURL = directory.appending(path: "Settings.app", directoryHint: .isDirectory)
        let settingsContents = settingsURL.appending(path: "Contents", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: settingsContents, withIntermediateDirectories: true)
        let settingsBytes = try PropertyListSerialization.data(fromPropertyList:
            ["CFBundleIdentifier": "com.apple.systempreferences", "CFBundlePackageType": "APPL"], format: .xml, options: 0)
        try settingsBytes.write(to: settingsContents.appending(path: "Info.plist"))
        let settings = ApplicationTarget(url: settingsURL, bundleIdentifier: "com.apple.systempreferences")
        #expect(WorkspacePreparation.prepare(.openSystemSettings, settingsApplication: { settingsURL }) == .application(settings, activateOnly: false))
        #expect(WorkspacePreparation.prepare(.quitApplication(ApplicationTarget(url: url, bundleIdentifier: "org.example.other"))) == nil)
    }

    @Test(arguments: [true, false]) func quitRoutingChecksFinalGateAndReportsOnlyFailure(_ accepted: Bool) async throws {
        let (mailbox, _) = try queued(.quitApplication(app), target: .quitApplication(app))
        var calls = 0
        let executor = WorkspaceActionExecutor(mailbox: mailbox, previousApplication: { _ in
            Issue.record("Unrelated workspace action switched apps"); return .unavailable
        },
            openApplication: { _ in Issue.record("Quit cold-launched an app") },
            quitApplication: { target, canPerform in
                #expect(target == app && canPerform())
                calls += 1
                return accepted ? .performed : .unavailable
            }, secureInput: { false }, postingAllowed: { true })
        await executor.service()
        #expect(calls == 1)
        #expect(mailbox.state.withLock { $0.actionFailed } == (accepted ? nil : .workspace(.quitApplication(app))))
        #expect(mailbox.state.withLock { $0.enabled && !$0.emergencyPause && $0.workspaceRequest == nil })
    }

    @Test(arguments: 0...7) func quitFinalGateCancelsWithoutLateError(_ change: Int) async throws {
        let (mailbox, _) = try queued(.quitApplication(app), target: .quitApplication(app))
        let secure = Mutex(false), allowed = Mutex(true)
        let executor = WorkspaceActionExecutor(mailbox: mailbox, previousApplication: { _ in
            Issue.record("Unrelated workspace action switched apps"); return .unavailable
        }, quitApplication: { _, canPerform in
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
            #expect(!canPerform())
            return .cancelled
        }, secureInput: { secure.withLock { $0 } }, postingAllowed: { allowed.withLock { $0 } })
        await executor.service()
        #expect(mailbox.state.withLock { $0.actionFailed == nil && $0.workspaceRequest == nil })
    }

    @Test func settingsRoutesToNativeApplicationOpeningAndHandlesFailure() async throws {
        let (mailbox, _) = try queued(.openSystemSettings, target: .application(app, activateOnly: false))
        var calls: [URL] = []
        let executor = WorkspaceActionExecutor(mailbox: mailbox, previousApplication: { _ in
            Issue.record("Unrelated workspace action switched apps"); return .unavailable
        }, openApplication: { url in
            calls.append(url)
            throw CommandTestError.rejected
        }, openDocument: { _ in Issue.record("Settings used a URL scheme") }, secureInput: { false }, postingAllowed: { true })
        await executor.service()
        #expect(calls == [app.url])
        #expect(mailbox.state.withLock { $0.actionFailed == .workspace(.openSystemSettings) && !$0.emergencyPause })
    }

    @Test(arguments: 1...16, [true, false]) func oldSchemasRejectNewCommandsInEveryProfile(_ version: Int, _ quit: Bool) throws {
        let action = quit ? WorkspaceAction.quitApplication(app) : .openSystemSettings
        let binding = rebind.Binding(scope: .allMice, trigger: .mouseButton(3), modifiers: [], action: .workspace(action))
        var old = Configuration(bindings: version < 6 ? [binding] : [])
        if version >= 6 { old.profiles.append(RuleProfile(name: "Inactive", bindings: [binding])) }
        old.schemaVersion = version
        let decoded = try JSONDecoder().decode(Configuration.self, from: JSONEncoder().encode(old))
        #expect(throws: ConfigurationError.invalid) { try decoded.migrated() }
    }

    @Test func schema16RetainsAllProfilesAndOnlyWritesOnExplicitSave() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: "RebindCommandStore-\(UUID())")
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let store = ConfigurationStore(url: directory.appending(path: "config.json"))
        var old = Configuration(isEnabled: true, bindings: [.init(scope: .allMice, trigger: .mouseButton(3), modifiers: .control,
            action: .windowLayout(.leftHalf), activation: .hold, holdDurationMilliseconds: 1000)])
        try old.createProfile(name: "Other", copying: old.selectedProfileID)
        old.schemaVersion = 16
        let bytes = try JSONEncoder().encode(old)
        try bytes.write(to: store.url)
        var loaded = try store.load()
        #expect(loaded.profiles == old.profiles && loaded.selectedProfileID == old.selectedProfileID && loaded.isEnabled)
        #expect(try Data(contentsOf: store.url) == bytes)
        loaded.bindings[0].action = .workspace(.quitApplication(app))
        try store.save(loaded)
        #expect(try store.load() == loaded)
    }

    @Test func bothFailuresHaveSpecificLocalizedMessages() {
        let model = AppModel(loadConfiguration: false)
        for action in [WorkspaceAction.quitApplication(app), .openSystemSettings] {
            model.mailbox.state.withLock { $0.actionFailed = .workspace(action) }
            model.refresh()
            #expect(model.error == (action == .openSystemSettings ? .openSystemSettingsFailed : .quitApplicationFailed))
        }
    }

    private func queued(_ action: WorkspaceAction, target: WorkspaceTarget) throws -> (EngineMailbox, WorkspaceRequest) {
        let mailbox = EngineMailbox()
        mailbox.configure(Configuration(isEnabled: true))
        mailbox.state.withLock { $0.status = .active; $0.pending = [.workspace(action)] }
        let dispatch = try #require(mailbox.nextAction())
        let request = WorkspaceRequest(dispatch: dispatch, target: target)
        mailbox.submitWorkspace(request)
        return (mailbox, request)
    }
}

nonisolated private enum CommandTestError: Error { case rejected }
