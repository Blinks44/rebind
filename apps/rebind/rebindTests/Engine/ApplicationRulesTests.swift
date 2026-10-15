import Foundation
import Testing
@testable import rebind

@MainActor struct ApplicationRulesTests {
    private let chrome = ApplicationTarget(url: URL(filePath: "/Applications/Google Chrome.app"), bundleIdentifier: "com.google.Chrome")
    private let back = KeyboardShortcut(keyCode: 33, modifiers: .command)
    private let closeTab = KeyboardShortcut(keyCode: 13, modifiers: .command)

    private func rule(_ shortcut: KeyboardShortcut, in application: ApplicationTarget? = nil, button: UInt32 = 3) -> rebind.Binding {
        var binding = rebind.Binding(scope: .allMice, trigger: .mouseButton(button), modifiers: [], action: .shortcut(shortcut))
        binding.application = application
        return binding
    }

    private func press(_ mailbox: EngineMailbox, button: UInt32 = 3) -> [RebindAction] {
        _ = mailbox.handle(InputEvent(trigger: .mouseButton(button), phase: .down), secureInput: false)
        _ = mailbox.handle(InputEvent(trigger: .mouseButton(button), phase: .up), secureInput: false)
        return mailbox.state.withLock { state in defer { state.pending.removeAll() }; return state.pending }
    }

    @Test func anAppRuleReplacesTheGeneralRuleOnlyInThatApp() throws {
        let configuration = Configuration(isEnabled: true, bindings: [rule(back), rule(closeTab, in: chrome)])
        try configuration.validate()
        let mailbox = EngineMailbox()
        mailbox.configure(configuration)
        mailbox.state.withLock { $0.status = .active }
        mailbox.setForegroundApplication("com.apple.finder")
        #expect(press(mailbox) == [.shortcut(back)])
        mailbox.setForegroundApplication(chrome.bundleIdentifier)
        #expect(press(mailbox) == [.shortcut(closeTab)])
        mailbox.setForegroundApplication(nil)
        #expect(press(mailbox) == [.shortcut(back)])
    }

    @Test func anAppRuleWithoutAGeneralOneWorksOnlyThere() {
        let mailbox = EngineMailbox()
        mailbox.configure(Configuration(isEnabled: true, bindings: [rule(closeTab, in: chrome)]))
        mailbox.state.withLock { $0.status = .active }
        mailbox.setForegroundApplication("com.apple.finder")
        #expect(press(mailbox).isEmpty)
        mailbox.setForegroundApplication(chrome.bundleIdentifier)
        #expect(press(mailbox) == [.shortcut(closeTab)])
    }

    @Test func twoRulesForTheSameAppAndTriggerConflict() throws {
        #expect(throws: ConfigurationError.conflict) {
            try Configuration(isEnabled: true, bindings: [rule(back, in: chrome), rule(closeTab, in: chrome)]).validate()
        }
        // A hold rule for one app and gestures on the same button for all apps are ambiguous there.
        var hold = rule(back, in: chrome)
        hold.activation = .hold
        let gesture = rebind.Binding(scope: .allMice, trigger: .mouseGesture(button: 3, direction: .left), modifiers: [],
                                     action: .shortcut(closeTab))
        #expect(throws: ConfigurationError.conflict) { try Configuration(isEnabled: true, bindings: [hold, gesture]).validate() }
    }

    @Test func theAppSurvivesStorageAndOlderFilesCannotCarryIt() throws {
        var configuration = Configuration(isEnabled: true, bindings: [rule(closeTab, in: chrome)])
        let decoded = try JSONDecoder().decode(Configuration.self, from: JSONEncoder().encode(configuration))
        #expect(decoded.bindings.first?.application == chrome)
        configuration.schemaVersion = 38
        #expect(throws: ConfigurationError.invalid) { try configuration.migrated() }
    }
}

struct GestureButtonTriggerTests {
    private let output = KeyboardShortcut(keyCode: 123, modifiers: .control)

    @Test func theGestureButtonWorksLikeAMouseButtonWithoutAClickToGiveBack() {
        let gesture = rebind.Binding(scope: .allMice, trigger: .mouseGesture(button: InputTrigger.gestureButton, direction: .left),
                                     modifiers: [], action: .shortcut(output))
        let mailbox = EngineMailbox()
        mailbox.configure(Configuration(isEnabled: true, bindings: [gesture]))
        mailbox.state.withLock { $0.status = .active }
        mailbox.handleOffTapButton(InputTrigger.gestureButton, down: true, modifiers: [], secureInput: false)
        #expect(mailbox.state.withLock { $0.hasPointerGestureRules && $0.matcher.pointerGestureSource != nil })
        _ = mailbox.handlePointerMotion(PointerMotion(deltaX: -120, deltaY: 0), modifiers: [],
                                        receivedAt: DispatchTime.now().uptimeNanoseconds, secureInput: false)
        mailbox.handleOffTapButton(InputTrigger.gestureButton, down: false, modifiers: [], secureInput: false)
        #expect(mailbox.state.withLock { $0.pending } == [.shortcut(output)])
        // Released without movement there is no ordinary click to post for it.
        mailbox.state.withLock { $0.pending.removeAll() }
        mailbox.handleOffTapButton(InputTrigger.gestureButton, down: true, modifiers: [], secureInput: false)
        mailbox.handleOffTapButton(InputTrigger.gestureButton, down: false, modifiers: [], secureInput: false)
        #expect(mailbox.state.withLock { $0.pending }.isEmpty)
    }

    @Test @MainActor func itIsNamedInTriggers() {
        #expect(InputLabels.trigger(.mouseButton(InputTrigger.gestureButton), modifiers: []) == AppLocalization.string(.gestureButton))
        #expect(InputLabels.trigger(.mouseButton(3), modifiers: []) == AppLocalization.string(.mouseButton(4)))
    }
}

struct ConfigurationBackupFileTests {
    @Test func aCopyIsKeptPerChangeAndTheNewestTenStay() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: "RebindBackups-\(UUID())")
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = ConfigurationStore(url: directory.appending(path: "configuration.json"))
        var configuration = Configuration(isEnabled: true)
        for minute in 0..<12 {
            configuration.isEnabled.toggle()
            configuration.pointerGestureDistance = minute.isMultiple(of: 3) ? .short : .standard
            try store.save(configuration)
            store.backUpLoadedFile(on: Date(timeIntervalSince1970: 1_800_000_000 + Double(minute) * 60))
        }
        // The same contents again on a later launch add nothing.
        store.backUpLoadedFile(on: Date(timeIntervalSince1970: 1_800_000_000 + 3600))
        let copies = try FileManager.default.contentsOfDirectory(atPath: store.backupDirectory.path).sorted()
        #expect(copies.count == ConfigurationStore.keptBackups)
        let newest = try ConfigurationBackup(contentsOf: store.backupDirectory.appending(path: try #require(copies.last)))
        #expect(newest.configuration == configuration)
    }
}
