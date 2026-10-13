import Foundation
import Testing
@testable import rebind

@MainActor struct TrackpadBindingEditorTests {
    private let action = RebindAction.shortcut(KeyboardShortcut(keyCode: 13, modifiers: .command))

    @Test(arguments: TrackpadPreset.allCases)
    func savedPresetRoundTripsWithoutChangingIdentity(_ preset: TrackpadPreset) throws {
        let existing = rebind.Binding(scope: .builtInTrackpad, trigger: preset.trigger,
            modifiers: [], action: action, isEnabled: false)
        let draft = BindingEditorDraft(scope: .builtInTrackpad, existing: existing)
        #expect(draft.trackpadPreset == preset)
        let candidate = try #require(draft.binding(scope: .builtInTrackpad, action: action, existing: existing))
        #expect(candidate == existing && candidate.isValid)
        let restored = try JSONDecoder().decode(Configuration.self,
            from: JSONEncoder().encode(Configuration(bindings: [candidate])))
        #expect(restored.bindings == [existing])
    }

    @Test(arguments: TrackpadPreset.allCases)
    func choosingCompletePresetRetainsOutputAndNormalizesTriggerOptions(_ preset: TrackpadPreset) throws {
        let existing = rebind.Binding(scope: .builtInTrackpad, trigger: .fourFingerTap,
            modifiers: [], action: action, isEnabled: false)
        var draft = BindingEditorDraft(scope: .builtInTrackpad, existing: existing)
        draft.activation = .hold
        draft.trigger?.modifiers = .shift
        draft.trackpadPreset = preset
        #expect(draft.output == action.shortcut)
        let candidate = try #require(draft.binding(scope: .builtInTrackpad, action: action, existing: existing))
        #expect(candidate.id == existing.id && !candidate.isEnabled)
        // The chosen held key belongs to the rule, not to the preset, so changing the preset keeps it.
        #expect(candidate.trigger == preset.trigger && candidate.modifiers == .shift)
        #expect(candidate.activation == .press && candidate.isValid)
    }

    @Test func onlyEngineBackedPresetsAreSelectable() {
        #expect(Set(TrackpadPreset.allCases.map { $0.trigger }) ==
            Set([InputTrigger.threeFingerTap, .fourFingerTap, .twoFingerDoubleTap, .threeFingerDoubleTap,
                 .fourFingerDoubleTap] + (2...4).map { .trackpadClick(fingers: $0) }
                + TrackpadCorner.allCases.map(InputTrigger.cornerTap)))
        #expect(TrackpadPreset(trigger: .mouseButton(3)) == nil)
        #expect(TrackpadPreset(trigger: .key(13)) == nil)
        #expect(BindingEditorDraft(scope: .builtInTrackpad, existing: nil).trackpadPreset == .fourFingerTap)
    }

    @Test(arguments: TrackpadPreset.allCases)
    func outputRecorderCannotReplaceTheGestureAndRejectsStaleOrCancelledCapture(_ preset: TrackpadPreset) {
        var draft = BindingEditorDraft(scope: .builtInTrackpad, existing: nil)
        draft.trackpadPreset = preset
        draft.output = action.shortcut
        let request = RecordingRequest(target: .output)
        let replacement = MatchKey(trigger: .key(0), modifiers: [.command, .shift])
        draft.accept(RecordedInput(request: request, input: nil), for: request, scope: .builtInTrackpad)
        draft.accept(RecordedInput(request: request, input: replacement),
                     for: RecordingRequest(target: .output), scope: .builtInTrackpad)
        draft.accept(RecordedInput(request: request, input: replacement), for: nil, scope: .builtInTrackpad)
        #expect(draft.output == action.shortcut)
        let triggerRequest = RecordingRequest(target: .keyboardTrigger)
        draft.accept(RecordedInput(request: triggerRequest, input: replacement),
                     for: triggerRequest, scope: .builtInTrackpad)
        #expect(draft.trackpadPreset == preset)
        draft.accept(RecordedInput(request: request, input: replacement), for: request, scope: .builtInTrackpad)
        #expect(draft.output == KeyboardShortcut(keyCode: 0, modifiers: [.command, .shift]))
        #expect(draft.trigger == MatchKey(trigger: preset.trigger, modifiers: []))
    }

    @Test(arguments: TrackpadPreset.allCases)
    func duplicatePresetConflictsOnlyWithinSelectedProfile(_ preset: TrackpadPreset) throws {
        let binding = rebind.Binding(scope: .builtInTrackpad, trigger: preset.trigger,
            modifiers: [], action: action)
        var configuration = Configuration(bindings: [binding])
        let original = configuration
        var candidate = binding
        candidate.id = UUID()
        #expect(BindingEditorValidation.error(for: candidate, in: configuration) == .conflict)
        #expect(BindingEditorValidation.error(for: binding, in: configuration) == nil)
        for other in TrackpadPreset.allCases where other != preset {
            candidate.trigger = other.trigger
            #expect(BindingEditorValidation.error(for: candidate, in: configuration) == nil)
        }
        #expect(configuration == original)
        try configuration.createProfile(name: "Independent")
        candidate.trigger = binding.trigger
        #expect(BindingEditorValidation.error(for: candidate, in: configuration) == nil)
    }

    @Test func presetEditingPersistsAndFailedSaveKeepsDraftAndPreviousRules() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: "TrackpadPreset-\(UUID())")
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = ConfigurationStore(url: directory.appending(path: "configuration.json"))
        let existing = rebind.Binding(scope: .builtInTrackpad, trigger: .fourFingerTap, modifiers: [], action: action)
        try store.save(Configuration(bindings: [existing]))
        let model = AppModel(store: store, readPermissions: { InputPermissions() })
        let profileID = model.configuration.selectedProfileID
        var draft = BindingEditorDraft(scope: .builtInTrackpad, existing: existing)
        draft.trackpadPreset = .threeFingerDoubleTap
        let candidate = try #require(draft.binding(scope: .builtInTrackpad, action: action, existing: existing))
        #expect(model.saveBinding(candidate, profileID: profileID))
        #expect(try store.load().bindings == [candidate])
        draft.trackpadPreset = .fourFingerDoubleTap
        let retry = try #require(draft.binding(scope: .builtInTrackpad, action: action, existing: existing))
        try FileManager.default.removeItem(at: store.url)
        try FileManager.default.createDirectory(at: store.url, withIntermediateDirectories: false)
        #expect(!model.saveBinding(retry, profileID: profileID))
        #expect(model.configuration.bindings == [candidate])
        #expect(draft.trackpadPreset == .fourFingerDoubleTap && draft.output == action.shortcut)
    }

    @Test(arguments: [AppLanguage.en, .ru, .de, .fr])
    func explanationsAndConditionalGuidanceAreTranslated(_ language: AppLanguage) {
        for preset in TrackpadPreset.allCases {
            #expect(!AppLocalization.string(preset.explanation, language: language).isEmpty)
            #expect(!AppLocalization.string(preset.systemGestureHelp, language: language).isEmpty)
        }
        let lookUp = AppLocalization.string(TrackpadPreset.threeFingerTap.systemGestureHelp, language: language)
        let zoom = AppLocalization.string(TrackpadPreset.threeFingerDoubleTap.systemGestureHelp, language: language)
        #expect(lookUp != zoom)
        if language != .en {
            for preset in TrackpadPreset.allCases {
                #expect(AppLocalization.string(preset.explanation, language: language) !=
                        AppLocalization.string(preset.explanation, language: .en))
                #expect(AppLocalization.string(preset.systemGestureHelp, language: language) !=
                        AppLocalization.string(preset.systemGestureHelp, language: .en))
            }
        }
    }
}
