import Foundation
import Testing
@testable import rebind

@MainActor struct MouseBindingEditorTests {
    private let action = RebindAction.shortcut(KeyboardShortcut(keyCode: 13, modifiers: .command))

    @Test(arguments: [UInt32(2), 8, 99, UInt32.max])
    func numericButtonsRoundTripWithoutAProductLimit(_ button: UInt32) throws {
        let existing = rebind.Binding(scope: .allMice, trigger: .mouseButton(button), modifiers: [.control, .option],
            action: action, isEnabled: false, activation: .hold, holdDurationMilliseconds: 1500)
        let draft = BindingEditorDraft(scope: .allMice, existing: existing)
        let saved = try #require(draft.binding(scope: .allMice, action: action, existing: existing))
        #expect(saved == existing)
        #expect(saved.isValid)
    }

    @Test(arguments: [RecordingTarget.mouseTrigger, .scrollTrigger, .gestureTrigger])
    func changingTypeClearsOnlyTriggerOptions(_ target: RecordingTarget) {
        let existing = rebind.Binding(scope: .allMice, trigger: .mouseButton(8), modifiers: .control,
            action: action, activation: .hold, holdDurationMilliseconds: 1500)
        var draft = BindingEditorDraft(scope: .allMice, existing: existing)
        draft.pointerDirection = .right
        draft.selectMouseTarget(target)
        #expect(draft.trigger == nil && draft.activation == .press)
        #expect(draft.holdDurationMilliseconds == 500 && draft.pointerDirection == .left)
        #expect(draft.output == action.shortcut && draft.mouseTarget == target)
    }

    @Test func cancelledAndUnrelatedRecordingsRetainPreviousValues() {
        let binding = rebind.Binding(scope: .allMice, trigger: .mouseButton(8), modifiers: .option, action: action)
        var draft = BindingEditorDraft(scope: .allMice, existing: binding)
        let request = RecordingRequest(target: .mouseTrigger)
        draft.accept(RecordedInput(request: request, input: nil), for: request, scope: .allMice)
        let stale = RecordedInput(request: request, input: MatchKey(trigger: .mouseButton(99), modifiers: []))
        draft.accept(stale, for: RecordingRequest(target: .mouseTrigger), scope: .allMice)
        draft.accept(stale, for: nil, scope: .allMice)
        #expect(draft.trigger == binding.matchKey && draft.output == action.shortcut)
    }

    @Test func wrongInputTypeCannotSilentlyChangeCaptureMode() {
        var draft = BindingEditorDraft(scope: .allMice, existing: nil)
        draft.selectMouseTarget(.scrollTrigger)
        let request = RecordingRequest(target: .scrollTrigger)
        draft.accept(RecordedInput(request: request, input: MatchKey(trigger: .mouseButton(8), modifiers: [])),
                     for: request, scope: .allMice)
        #expect(draft.trigger == nil && draft.mouseTarget == .scrollTrigger)
        draft.accept(RecordedInput(request: request, input: MatchKey(trigger: .scroll(.right), modifiers: .shift)),
                     for: request, scope: .allMice)
        #expect(draft.trigger == MatchKey(trigger: .scroll(.right), modifiers: .shift))
    }

    @Test func outputRecordingChangesOnlyTheOutput() {
        let binding = rebind.Binding(scope: .allMice, trigger: .mouseButton(8), modifiers: .control, action: action)
        var draft = BindingEditorDraft(scope: .allMice, existing: binding)
        let request = RecordingRequest(target: .output)
        draft.accept(RecordedInput(request: request, input: MatchKey(trigger: .key(0), modifiers: [.command, .shift])),
                     for: request, scope: .allMice)
        #expect(draft.trigger == binding.matchKey)
        #expect(draft.output == KeyboardShortcut(keyCode: 0, modifiers: [.command, .shift]))
    }

    @Test(arguments: PointerDirection.allCases)
    func editingDirectionRetainsRecordedButtonAndIdentity(_ direction: PointerDirection) throws {
        let existing = rebind.Binding(scope: .allMice, trigger: .mouseGesture(button: 99, direction: .left),
            modifiers: .option, action: action, isEnabled: false)
        var draft = BindingEditorDraft(scope: .allMice, existing: existing)
        draft.pointerDirection = direction
        let candidate = try #require(draft.binding(scope: .allMice, action: action, existing: existing))
        #expect(candidate.trigger == .mouseGesture(button: 99, direction: direction))
        #expect(candidate.modifiers == .option && candidate.id == existing.id && !candidate.isEnabled)
        #expect(candidate.activation == .press && candidate.isValid)
    }

    @Test func validationSharesPersistenceConflictsWithoutChangingRules() throws {
        let button = rebind.Binding(scope: .allMice, trigger: .mouseButton(8), modifiers: .control, action: action)
        var configuration = Configuration(bindings: [button])
        let original = configuration
        var candidate = button
        candidate.id = UUID()
        candidate.activation = .hold
        #expect(BindingEditorValidation.error(for: candidate, in: configuration) == .conflict)
        candidate.trigger = .mouseGesture(button: 8, direction: .left)
        candidate.activation = .press
        #expect(BindingEditorValidation.error(for: candidate, in: configuration) == .conflict)
        candidate.modifiers = .option
        #expect(BindingEditorValidation.error(for: candidate, in: configuration) == nil)
        candidate.modifiers = .control
        candidate.isEnabled = false
        #expect(BindingEditorValidation.error(for: candidate, in: configuration) == nil)
        #expect(configuration == original)
        #expect(BindingEditorValidation.error(for: button, in: configuration) == nil)
        try configuration.createProfile(name: "Independent")
        #expect(BindingEditorValidation.error(for: button, in: configuration) == .invalid) // Global duplicate ID.
        candidate.id = UUID(); candidate.isEnabled = true
        #expect(BindingEditorValidation.error(for: candidate, in: configuration) == nil)
    }

    @Test func distinctPointerDirectionsCanShareAButton() {
        let existing = rebind.Binding(scope: .allMice, trigger: .mouseGesture(button: 8, direction: .left),
            modifiers: .control, action: action)
        var candidate = existing
        candidate.id = UUID(); candidate.trigger = .mouseGesture(button: 8, direction: .right)
        #expect(BindingEditorValidation.error(for: candidate, in: Configuration(bindings: [existing])) == nil)
    }

    @Test func searchUsesTriggerActionAndActivationWithinMouseCategory() {
        let button = rebind.Binding(scope: .allMice, trigger: .mouseButton(99), modifiers: .control, action: action,
            activation: .hold, holdDurationMilliseconds: 1500)
        let wheel = rebind.Binding(scope: .allMice, trigger: .scroll(.up), modifiers: [], action: .system(.volumeUp))
        let keyboard = rebind.Binding(scope: .allKeyboards, trigger: .key(0), modifiers: [], action: action)
        let bindings = [button, wheel, keyboard]
        #expect(BindingList.matching(bindings, search: "  \n ") == [button, wheel])
        #expect(BindingList.matching(bindings, search: "100") == [button])
        #expect(BindingList.matching(bindings, search: "1500") == [button])
        #expect(BindingList.matching(bindings, search: wheel.action.label.uppercased()) == [wheel])
        #expect(BindingList.matching(bindings, search: "unknown query") == [])
    }

    @Test func secureInputBlocksCaptureWhilePauseAloneDoesNot() {
        let model = AppModel(loadConfiguration: false,
            readPermissions: { InputPermissions(accessibility: true, posting: true) })
        model.mailbox.state.withLock { $0.status = .paused }
        #expect(model.canRecord)
        model.mailbox.state.withLock { $0.status = .secureInput }
        #expect(!model.canRecord)
        model.mailbox.state.withLock { $0.status = .paused; $0.suspended = true }
        #expect(!model.canRecord)
        model.mailbox.state.withLock { $0.suspended = false; $0.stopped = true }
        #expect(!model.canRecord)
        #expect(model.recordingUnavailableHint == .engineInterrupted)
        model.mailbox.state.withLock { $0.stopped = false; $0.suspended = true }
        #expect(model.recordingUnavailableHint == .remappingSessionSuspended)
        model.mailbox.state.withLock { $0.suspended = false; $0.status = .secureInput }
        #expect(model.recordingUnavailableHint == .secureInputPaused)
    }
}
