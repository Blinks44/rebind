import Foundation
import Synchronization
import Testing
@testable import rebind

struct MediaActionTests {
    @Test(arguments: MediaAction.allCases) @MainActor
    func sharedCatalogDoesNotRequireAudioDeviceOrRecordedShortcut(_ media: MediaAction) throws {
        let action = RebindAction.media(media), kind = ActionKind(action: action)
        #expect(kind.category == (media.isBrightness ? .system : .audio) && kind.mediaAction == media && kind.systemAction == nil)
        #expect(kind.configuredAction(shortcut: nil) == action && action.shortcut == nil && action.isSupported)
        #expect(kind.isAvailable(with: AudioOutputCapabilities()) && AudioOutputCapabilities().supports(action))
        #expect(action.label == String(localized: kind.title))
        #expect(try JSONDecoder().decode(RebindAction.self, from: JSONEncoder().encode(action)) == action)
    }

    @Test(arguments: MediaAction.allCases, [InputTrigger.key(0), .mouseButton(99), .scroll(.right), .mouseGesture(button: 99, direction: .left)])
    func matchesExactModifiersAcrossExistingInputFamiliesAndIgnoresSyntheticFeedback(_ media: MediaAction, _ trigger: InputTrigger) {
        let binding = rebind.Binding(scope: trigger.scope, trigger: trigger, modifiers: .control, action: .media(media))
        let rules = InputMatcher.compile([binding])
        var matcher = InputMatcher()
        let source = trigger.pressSource
        let phase: InputEvent.Phase = trigger.isScroll ? .scroll : .down
        #expect(matcher.handle(InputEvent(trigger: source, phase: phase), rules: rules, enabled: true).suppress == false)
        var decision = matcher.handle(InputEvent(trigger: source, modifiers: .control, phase: phase), rules: rules, enabled: true)
        if trigger.isPointerGesture {
            decision = matcher.handle(InputEvent(trigger: source, modifiers: .control, phase: .drag,
                motion: PointerMotion(deltaX: -50, deltaY: 0)), rules: rules, enabled: true)
        }
        #expect(decision.suppress && decision.action == .media(media) && decision.shortcut == nil)
        if !trigger.isScroll {
            #expect(matcher.handle(InputEvent(trigger: source, phase: .up), rules: rules, enabled: false).suppress)
            #expect(matcher.hasSuppressedInput == false)
        }
        #expect(matcher.handle(InputEvent(trigger: source, modifiers: .control, phase: phase, isSynthetic: true),
            rules: rules, enabled: true).suppress == false)
    }

    @Test func schema14MigratesEveryProfileAndActionWithoutRewritingUntilSave() throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: "RebindMedia-\(UUID())")
        defer { try? FileManager.default.removeItem(at: folder) }
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let store = ConfigurationStore(url: folder.appending(path: "configuration.json"))
        let earlier: [RebindAction] = [.shortcut(.init(keyCode: 0, modifiers: .command)), .system(.toggleMute),
            .mouse(.doubleLeftClick), .window(.minimize),
            .workspace(.openURL(try #require(URL(string: "https://example.com")))),
            .appleShortcut(.init(id: UUID(), name: "Test")), .dock(.missionControl), .dock(.previousSpace), .dock(.nextSpace)]
        var old = Configuration(isEnabled: true, bindings: earlier.enumerated().map { index, action in
            rebind.Binding(scope: .allMice, trigger: .mouseButton(UInt32(index + 3)), modifiers: .control, action: action,
                activation: .hold, holdDurationMilliseconds: 1000)
        })
        try old.createProfile(name: "Other", copying: old.selectedProfileID)
        old.schemaVersion = 14
        let bytes = try JSONEncoder().encode(old)
        try bytes.write(to: store.url)
        var loaded = try store.load()
        #expect(loaded.schemaVersion == Configuration.currentSchemaVersion && loaded.profiles == old.profiles)
        #expect(loaded.isEnabled && loaded.selectedProfileID == old.selectedProfileID)
        #expect(try Data(contentsOf: store.url) == bytes)
        loaded.bindings[0].action = .media(.playPause)
        try store.save(loaded)
        #expect(try store.load() == loaded)
    }

    @Test(arguments: 1...14) func mediaPayloadCannotAppearInOlderSchemaOrInactiveProfile(_ version: Int) throws {
        let binding = rebind.Binding(scope: .allMice, trigger: .mouseButton(3), modifiers: [], action: .media(.playPause))
        var old = Configuration(bindings: version < 6 ? [binding] : [])
        if version >= 6 { old.profiles.append(RuleProfile(name: "Inactive", bindings: [binding])) }
        old.schemaVersion = version
        let decoded = try JSONDecoder().decode(Configuration.self, from: JSONEncoder().encode(old))
        #expect(throws: ConfigurationError.invalid) { try decoded.migrated() }
    }

    @Test func unknownMediaActionFailsDecoding() throws {
        let bytes = try JSONEncoder().encode(RebindAction.media(.playPause))
        let unknown = Data(String(decoding: bytes, as: UTF8.self).replacingOccurrences(of: "playPause", with: "unsupportedMedia").utf8)
        #expect(throws: DecodingError.self) { try JSONDecoder().decode(RebindAction.self, from: unknown) }
    }

    @Test func serialWorkerRoutesMediaIndependentlyOfOutputDeviceAndReportsNonPausingFailures() {
        let mailbox = readyMailbox()
        let calls = Mutex<[RebindAction]>([])
        let worker = ActionWorker(mailbox: mailbox, capabilities: { AudioOutputCapabilities() },
            sendShortcut: { value in calls.withLock { $0.append(.shortcut(value)) }; return true },
            performMouse: { action, _ in calls.withLock { $0.append(.mouse(action)) }; return .performed },
            performMedia: { action, canPerform in
                #expect(canPerform())
                calls.withLock { $0.append(.media(action)) }
                return action == .nextTrack ? .unavailable : .performed
            }, secureInput: { false }, postingAllowed: { true })
        let sequence: [RebindAction] = [.media(.playPause), .mouse(.leftClick), .media(.nextTrack),
            .shortcut(.init(keyCode: 0, modifiers: .command)), .media(.previousTrack)]
        mailbox.state.withLock { $0.pending = sequence }
        for time in UInt64(0)...4 { worker.service(at: time) }
        #expect(calls.withLock { $0 } == sequence)
        #expect(mailbox.state.withLock { $0.enabled && !$0.emergencyPause && $0.actionFailed == .media(.nextTrack) })
    }

    @Test(arguments: 0...5) func lifecycleChangesAtFinalGateCancelWithoutStaleError(_ change: Int) {
        let mailbox = readyMailbox()
        let calls = Mutex(0)
        let worker = ActionWorker(mailbox: mailbox, capabilities: { AudioOutputCapabilities() },
            performMedia: { _, canPerform in
                switch change {
                case 0: mailbox.configure(Configuration(isEnabled: false))
                case 1: mailbox.setEditing(true)
                case 2: mailbox.record(RecordingRequest(target: .mouseTrigger))
                case 3: mailbox.suspend(true)
                case 4: mailbox.stop()
                default: mailbox.configure(Configuration(isEnabled: true))
                }
                if canPerform() { calls.withLock { $0 += 1 }; return .performed }
                return .cancelled
            }, secureInput: { false }, postingAllowed: { true })
        mailbox.state.withLock { $0.pending = [.media(.playPause)] }
        worker.service(at: 0)
        #expect(calls.withLock { $0 } == 0)
        #expect(mailbox.state.withLock { $0.actionFailed == nil && $0.pending.isEmpty })
    }

    @Test(arguments: [true, false]) func protectedContextsClearMediaQueueWithoutCallingBackend(_ secure: Bool) {
        let mailbox = readyMailbox()
        let calls = Mutex(0)
        let worker = ActionWorker(mailbox: mailbox, capabilities: { AudioOutputCapabilities() },
            performMedia: { _, _ in calls.withLock { $0 += 1 }; return .performed },
            secureInput: { secure }, postingAllowed: { secure })
        mailbox.state.withLock { $0.pending = [.media(.playPause)] }
        worker.service(at: 0)
        #expect(calls.withLock { $0 } == 0)
        #expect(mailbox.state.withLock { $0.pending.isEmpty })
        #expect(mailbox.state.withLock { $0.status } == (secure ? .secureInput : .permissionRequired))
    }

    @Test @MainActor func mediaDispatchFailureHasItsOwnLocalizedError() throws {
        let url = FileManager.default.temporaryDirectory.appending(path: "RebindMediaMissing-\(UUID()).json")
        let model = AppModel(store: ConfigurationStore(url: url))
        model.mailbox.state.withLock { $0.actionFailed = .media(.playPause) }
        model.refresh()
        #expect(model.error == .mediaActionFailed)
    }

    private func readyMailbox() -> EngineMailbox {
        let mailbox = EngineMailbox()
        let binding = rebind.Binding(scope: .allMice, trigger: .mouseButton(3), modifiers: [], action: .media(.playPause))
        mailbox.configure(Configuration(isEnabled: true, bindings: [binding]))
        mailbox.state.withLock { $0.status = .active }
        return mailbox
    }
}
