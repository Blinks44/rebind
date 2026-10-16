import Foundation
import Testing
@testable import rebind

struct ActionTests {
    @Test func catalogRequiresARecordedShortcutAndSeparatesCapabilities() {
        #expect(ActionKind.keyboardShortcut.configuredAction(shortcut: nil) == nil)
        #expect(ActionKind.keyboardShortcut.configuredAction(shortcut: KeyboardShortcut(keyCode: 55, modifiers: [])) == nil)
        let volumeOnly = AudioOutputCapabilities(deviceID: 1, volume: true, mute: false)
        #expect(ActionKind.volumeUp.isAvailable(with: volumeOnly))
        #expect(ActionKind.volumeDown.isAvailable(with: volumeOnly))
        #expect(ActionKind.toggleMute.isAvailable(with: volumeOnly) == false)
        #expect(AudioOutputCapabilities(volume: true, mute: true).supports(.volumeUp) == false)
        for kind in ActionKind.allCases {
            if let system = kind.systemAction {
                #expect(kind.configuredAction(shortcut: nil) == .system(system))
                #expect(ActionKind(action: .system(system)) == kind)
            }
        }
    }

    @Test(arguments: SystemAction.allCases, [InputTrigger.key(0), .mouseButton(99), .scroll(.up)])
    func everySystemActionMatchesSupportedInputCategories(_ action: SystemAction, _ trigger: InputTrigger) {
        let binding = rebind.Binding(scope: trigger.scope, trigger: trigger, modifiers: .control, action: .system(action))
        let rules = InputMatcher.compile([binding])
        var matcher = InputMatcher()
        let phase: InputEvent.Phase = trigger.isScroll ? .scroll : .down
        let decision = matcher.handle(InputEvent(trigger: trigger, modifiers: .control, phase: phase), rules: rules, enabled: true)
        #expect(decision.suppress && decision.action == .system(action))
        #expect(decision.shortcut == nil)
        if !trigger.isScroll {
            #expect(matcher.handle(InputEvent(trigger: trigger, phase: .up), rules: rules, enabled: false).suppress)
        }
    }

    @Test func audioHoldDoublePressAndPointerGestureDeliverTypedActions() {
        let output = RebindAction.system(.toggleMute)
        var binding = rebind.Binding(scope: .allMice, trigger: .mouseButton(3), modifiers: [], action: output,
                                     activation: .hold, holdDurationMilliseconds: 1000)
        var matcher = InputMatcher()
        var rules = InputMatcher.compile([binding])
        let down = InputEvent(trigger: .mouseButton(3), phase: .down, timestamp: 0)
        #expect(matcher.handle(down, rules: rules, enabled: true).action == nil)
        #expect(matcher.pollHold(at: 1_000_000_000, rules: rules, enabled: true) == output)
        #expect(matcher.pollHold(at: 1_000_000_001, rules: rules, enabled: true) == nil)
        matcher.resetAfterCaptureLoss()
        binding.activation = .doublePress
        rules = InputMatcher.compile([binding])
        #expect(matcher.handle(down, rules: rules, enabled: true).action == nil)
        _ = matcher.handle(InputEvent(trigger: .mouseButton(3), phase: .up, timestamp: 1), rules: rules, enabled: true)
        #expect(matcher.handle(InputEvent(trigger: .mouseButton(3), phase: .down, timestamp: 2), rules: rules, enabled: true).action == output)
        matcher.resetAfterCaptureLoss()
        binding.activation = .press
        binding.trigger = .mouseGesture(button: 3, direction: .left)
        rules = InputMatcher.compile([binding])
        _ = matcher.handle(down, rules: rules, enabled: true)
        let motion = InputEvent(trigger: .mouseButton(3), phase: .drag, timestamp: 1, motion: PointerMotion(deltaX: -50, deltaY: 0))
        #expect(matcher.handle(motion, rules: rules, enabled: true).action == output)
        #expect(matcher.handle(motion, rules: rules, enabled: true).action == nil)
    }

    @Test func oldProfileSchemaKeepsSelectionRulesAndOriginalFileUntilSave() throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: "RebindActions-\(UUID())")
        defer { try? FileManager.default.removeItem(at: folder) }
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let store = ConfigurationStore(url: folder.appending(path: "configuration.json"))
        let binding = rebind.Binding(scope: .allMice, trigger: .mouseButton(4), modifiers: .control,
            action: .shortcut(KeyboardShortcut(keyCode: 0, modifiers: .command)), activation: .hold, holdDurationMilliseconds: 1000)
        var original = Configuration(isEnabled: true, bindings: [binding])
        try original.createProfile(name: "Work", copying: RuleProfile.defaultID)
        original.schemaVersion = 6
        let bytes = try JSONEncoder().encode(original)
        try bytes.write(to: store.url)
        var migrated = try store.load()
        #expect(migrated.schemaVersion == Configuration.currentSchemaVersion)
        #expect(migrated.selectedProfileID == original.selectedProfileID && migrated.profiles == original.profiles && migrated.isEnabled)
        #expect(try Data(contentsOf: store.url) == bytes)
        migrated.bindings[0].action = .system(.volumeDown)
        try store.save(migrated)
        #expect(try store.load() == migrated)
    }

    @Test(arguments: 1...6)
    func newActionsCannotMasqueradeAsOldSchema(_ version: Int) throws {
        let binding = rebind.Binding(scope: .allKeyboards, trigger: .key(0), modifiers: .control, action: .system(.volumeUp))
        let bytes = try JSONEncoder().encode(Configuration(schemaVersion: version, bindings: [binding]))
        let decoded = try JSONDecoder().decode(Configuration.self, from: bytes)
        #expect(throws: ConfigurationError.invalid) { try decoded.migrated() }
    }

    @Test func unknownSystemActionsAndFutureSchemasAreNotAccepted() throws {
        let binding = rebind.Binding(scope: .allMice, trigger: .mouseButton(3), modifiers: [], action: .system(.toggleMute))
        let configuration = Configuration(bindings: [binding])
        let bytes = try JSONEncoder().encode(configuration)
        #expect(try JSONDecoder().decode(Configuration.self, from: bytes).migrated() == configuration)
        let unknown = Data(String(decoding: bytes, as: UTF8.self).replacingOccurrences(of: "toggleMute", with: "launchUntrustedCode").utf8)
        #expect(throws: (any Error).self) { try JSONDecoder().decode(Configuration.self, from: unknown) }
        #expect(throws: ConfigurationError.incompatible) { try Configuration(schemaVersion: Configuration.currentSchemaVersion + 1).migrated() }
    }
}
