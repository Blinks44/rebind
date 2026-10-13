import CoreGraphics
import Foundation
import Synchronization
import Testing
@testable import rebind

struct DesktopActionTests {
    @Test(arguments: DesktopAction.allCases)
    func catalogConfiguresNativeActionsWithoutRecordedOutputChord(_ desktop: DesktopAction) throws {
        let custom = KeyboardShortcut(keyCode: 99, modifiers: [.command, .option])
        let action: RebindAction = .dock(desktop)
        let kind = ActionKind(action: action)
        #expect(kind.desktopAction == desktop && kind.category == .desktop)
        #expect(kind.configuredAction(shortcut: custom) == action)
        #expect(kind.configuredAction(shortcut: nil) == action)
        #expect(action.shortcut == nil && action.isSupported)
        let available = DockActions.isAvailable(for: desktop)
        #expect(AudioOutputCapabilities().supports(action) == available)
        #expect(kind.isAvailable(with: AudioOutputCapabilities()) == available)
        #expect(try JSONDecoder().decode(RebindAction.self, from: JSONEncoder().encode(action)) == action)
    }

    @Test func legacyShortcutsCannotBeConfiguredOrMatchedInCurrentSchema() {
        let legacy = RebindAction.desktop(.nextSpace, shortcut: .init(keyCode: 124, modifiers: .control))
        #expect(!legacy.isSupported && !AudioOutputCapabilities().supports(legacy))
        #expect(ActionKind.nextSpace.configuredAction(shortcut: nil) == .dock(.nextSpace))
        let binding = rebind.Binding(scope: .allMice, trigger: .mouseButton(4), modifiers: [], action: legacy)
        #expect(InputMatcher.compile([binding]).isEmpty)
    }

    @Test func migrationRetainsAllOldActionsProfilesAndBytesUntilSave() throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: "RebindDesktop-\(UUID())")
        defer { try? FileManager.default.removeItem(at: folder) }
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let store = ConfigurationStore(url: folder.appending(path: "config.json"))
        let url = try #require(URL(string: "https://example.com"))
        let previous: [RebindAction] = [.shortcut(.init(keyCode: 0, modifiers: .command)), .system(.toggleMute),
            .window(.minimize), .workspace(.openURL(url)), .appleShortcut(.init(id: UUID(), name: "Test"))]
        let bindings = previous.enumerated().map { index, action in
            rebind.Binding(scope: .allMice, trigger: .mouseButton(UInt32(index + 2)), modifiers: [], action: action)
        }
        var old = Configuration(isEnabled: true, bindings: bindings)
        try old.createProfile(name: "Second", copying: old.selectedProfileID)
        old.schemaVersion = 10
        let bytes = try JSONEncoder().encode(old)
        try bytes.write(to: store.url)
        var migrated = try store.load()
        #expect(migrated.schemaVersion == Configuration.currentSchemaVersion)
        #expect(migrated.isEnabled && migrated.selectedProfileID == old.selectedProfileID && migrated.profiles == old.profiles)
        #expect(try Data(contentsOf: store.url) == bytes)
        migrated.bindings[0].action = .dock(.nextSpace)
        try store.save(migrated)
        #expect(try store.load() == migrated)
    }

    @Test(arguments: 1...10)
    func desktopCannotMasqueradeInOlderSchemasEvenInInactiveProfiles(_ version: Int) throws {
        let binding = rebind.Binding(scope: .allMice, trigger: .mouseButton(3), modifiers: [],
                                    action: .desktop(.missionControl, shortcut: KeyboardShortcut(keyCode: 126, modifiers: .control)))
        var old = Configuration(bindings: version < 6 ? [binding] : [])
        if version >= 6 { old.profiles.append(RuleProfile(name: "Inactive", bindings: [binding])) }
        old.schemaVersion = version
        let decoded = try JSONDecoder().decode(Configuration.self, from: JSONEncoder().encode(old))
        #expect(throws: ConfigurationError.invalid) { try decoded.migrated() }
    }

    @Test func unsupportedStoredKeyAndUnknownDesktopActionFailValidation() throws {
        var configuration = Configuration(bindings: [rebind.Binding(scope: .allMice, trigger: .mouseButton(3), modifiers: [],
            action: .desktop(.missionControl, shortcut: .init(keyCode: 55, modifiers: [])))])
        #expect(throws: ConfigurationError.invalid) { try configuration.validate() }
        configuration.bindings[0].action = .desktop(.missionControl, shortcut: KeyboardShortcut(keyCode: 126, modifiers: .control))
        let text = String(decoding: try JSONEncoder().encode(configuration), as: UTF8.self)
        let unknown = Data(text.replacingOccurrences(of: "missionControl", with: "unknownDesktop").utf8)
        #expect(throws: DecodingError.self) { try JSONDecoder().decode(Configuration.self, from: unknown) }
    }

    @Test(arguments: DesktopAction.allCases, [InputTrigger.key(0), .mouseButton(99), .scroll(.right)])
    func typedMatchingPreservesExactModifiersPassthroughAndRelease(_ desktop: DesktopAction, _ trigger: InputTrigger) {
        let action: RebindAction = .dock(desktop)
        let binding = rebind.Binding(scope: trigger.scope, trigger: trigger, modifiers: .control, action: action)
        let rules = InputMatcher.compile([binding])
        var matcher = InputMatcher()
        let phase: InputEvent.Phase = trigger.isScroll ? .scroll : .down
        #expect(matcher.handle(InputEvent(trigger: trigger, phase: phase), rules: rules, enabled: true).suppress == false)
        let result = matcher.handle(InputEvent(trigger: trigger, modifiers: .control, phase: phase), rules: rules, enabled: true)
        #expect(result.suppress && result.action == action && result.shortcut == nil)
        if !trigger.isScroll {
            #expect(matcher.handle(InputEvent(trigger: trigger, phase: .up), rules: rules, enabled: false).suppress)
            #expect(matcher.hasSuppressedInput == false)
        }
    }

    @Test(arguments: [DesktopAction.previousSpace, .nextSpace])
    func generatedNativeShortcutsAreTaggedAndNeverFeedBack(_ desktop: DesktopAction) throws {
        let events = try #require(SpaceShortcutSender.events(desktop))
        #expect(events.count == 2)
        #expect(events.allSatisfy { ($0.type == .keyDown || $0.type == .keyUp)
            && $0.flags == [.maskControl, .maskSecondaryFn] && $0.getIntegerValueField(.eventSourceUserData) == ShortcutSender.eventTag })
        let binding = rebind.Binding(scope: .allMice, trigger: .mouseButton(4), modifiers: [], action: .dock(desktop))
        var matcher = InputMatcher()
        let result = matcher.handle(InputEvent(trigger: binding.trigger, phase: .down, isSynthetic: true),
                                   rules: InputMatcher.compile([binding]), enabled: true)
        #expect(!result.suppress && result.action == nil)
    }

    @Test func sharedSerialWorkerRoutesNativeSpacesAmongEarlierActions() {
        let mailbox = readyMailbox()
        let audio = AudioOutputCapabilities(deviceID: 17, volume: true, mute: true)
        let calls = Mutex<[RebindAction]>([])
        let worker = ActionWorker(mailbox: mailbox, capabilities: { audio },
            performAudio: { action, _ in calls.withLock { $0.append(.system(action)) }; return true },
            sendShortcut: { shortcut in calls.withLock { $0.append(.shortcut(shortcut)) }; return true },
            performDock: { action, allowed in
                #expect(allowed()); calls.withLock { $0.append(.dock(action)) }; return .performed
            },
            secureInput: { false }, postingAllowed: { true })
        mailbox.updateAudioCapabilities(audio)
        mailbox.state.withLock { $0.pending = [.system(.toggleMute), .dock(.nextSpace),
                                             .shortcut(.init(keyCode: 0, modifiers: .command))] }
        for tick in 0...2 { worker.service(at: UInt64(tick)) }
        #expect(calls.withLock { $0 } == [.system(.toggleMute), .dock(.nextSpace), .shortcut(.init(keyCode: 0, modifiers: .command))])
        #expect(mailbox.state.withLock { $0.pending.isEmpty && $0.actionFailed == nil })
    }

    @Test(arguments: 0...5)
    func lifecycleChangeAfterDequeuePreventsGesturePostingAndStaleError(_ change: Int) {
        let mailbox = readyMailbox()
        let calls = Mutex(0), preflights = Mutex(0)
        let worker = ActionWorker(mailbox: mailbox, capabilities: { AudioOutputCapabilities() },
            performDock: { _, _ in calls.withLock { $0 += 1 }; return .performed }, secureInput: { false }, postingAllowed: {
                let count = preflights.withLock { $0 += 1; return $0 }
                if count == 2 {
                    switch change {
                    case 0: mailbox.configure(Configuration(isEnabled: true))
                    case 1: mailbox.configure(Configuration(isEnabled: false))
                    case 2: mailbox.setEditing(true)
                    case 3: mailbox.record(RecordingRequest(target: .output))
                    case 4: mailbox.suspend(true)
                    default: mailbox.stop()
                    }
                }
                return true
            })
        worker.service(at: 0)
        #expect(calls.withLock { $0 } == 0)
        #expect(mailbox.state.withLock { $0.pending.isEmpty && $0.actionFailed == nil })
    }

    @Test(arguments: [true, false])
    func secureInputAndRevokedPostingCancelBeforeNativeSending(_ secure: Bool) {
        let mailbox = readyMailbox()
        let calls = Mutex(0)
        let worker = ActionWorker(mailbox: mailbox, capabilities: { AudioOutputCapabilities() },
            performDock: { _, _ in calls.withLock { $0 += 1 }; return .performed }, secureInput: { secure }, postingAllowed: { secure })
        worker.service(at: 0)
        #expect(calls.withLock { $0 } == 0)
        #expect(mailbox.state.withLock { $0.pending.isEmpty && $0.status == (secure ? .secureInput : .permissionRequired) })
    }

    @Test func gestureFailureReportsErrorWithoutPausingUnrelatedRules() {
        let mailbox = readyMailbox()
        let worker = ActionWorker(mailbox: mailbox, capabilities: { AudioOutputCapabilities() },
            performDock: { _, _ in .unavailable }, secureInput: { false }, postingAllowed: { true })
        worker.service(at: 0)
        #expect(mailbox.state.withLock { $0.enabled && !$0.emergencyPause && $0.pending.isEmpty })
        #expect(mailbox.state.withLock { $0.actionFailed } == .dock(.nextSpace))
    }

    @MainActor @Test func nativeSpaceLabelHasNoRetiredChordAndFailureReachesUI() {
        let action = RebindAction.dock(.nextSpace)
        #expect(action.label == String(localized: .nextSpaceAction))
        let model = AppModel(loadConfiguration: false)
        model.mailbox.state.withLock { $0.actionFailed = action }
        model.refresh()
        #expect(model.error == .spaceActionFailed)
        #expect(model.mailbox.state.withLock { $0.actionFailed == nil })
    }

    private func readyMailbox() -> EngineMailbox {
        let mailbox = EngineMailbox()
        let binding = rebind.Binding(scope: .allMice, trigger: .mouseButton(3), modifiers: [],
            action: .dock(.nextSpace))
        mailbox.configure(Configuration(isEnabled: true, bindings: [binding]))
        mailbox.state.withLock { $0.status = .active }
        #expect(mailbox.handle(InputEvent(trigger: .mouseButton(3), phase: .down), secureInput: false))
        return mailbox
    }
}
