import Foundation
import Testing
@testable import rebind

@MainActor struct MagicMouseEditorTests {
    @Test(arguments: MagicMousePreset.allCases)
    func presetEditingKeepsTheCategoryAndIndependentOutput(_ preset: MagicMousePreset) throws {
        var draft = BindingEditorDraft(scope: .magicMouse, existing: nil)
        draft.output = .init(keyCode: 13, modifiers: .command)
        draft.magicMousePreset = preset
        draft.trackpadModifiers = .shift
        let output = try #require(draft.output)
        let rule = try #require(draft.binding(scope: .magicMouse, action: .shortcut(output), existing: nil))
        #expect(rule.isValid && rule.scope == .magicMouse && rule.trigger == preset.trigger)
        #expect(rule.modifiers == .shift && rule.activation == .press && rule.holdsOutput == false)
        #expect(draft.output == .init(keyCode: 13, modifiers: .command))
        draft.accept(.init(request: .init(target: .mouseTrigger), input: .init(trigger: .mouseButton(3), modifiers: [])),
                     for: nil, scope: .magicMouse)
        #expect(draft.magicMousePreset == preset)
    }

    @Test(arguments: AppLanguage.allCases)
    func presetNamesAndGuidanceAreTranslated(_ language: AppLanguage) {
        let strings: [LocalizedStringResource] = [.magicMouseOneFingerTap, .magicMouseTwoFingerTap, .magicMouseSubtitle,
            .magicMouseTapHelp, .magicMouseOneFingerConflict, .magicMouseTwoFingerConflict, .magicMouseExperimentalTitle,
            .magicMouseExperimentalHelp, .magicMouseUnavailableTitle, .magicMouseUnavailableHelp,
            .magicMouseFailedTitle, .magicMouseFailedHelp]
        for resource in strings {
            let text = AppLocalization.string(resource, language: language)
            #expect(text.isEmpty == false)
            if language != .en { #expect(text != AppLocalization.string(resource, language: .en)) }
        }
        #expect(AppLocalization.string(.magicMouseOneFingerTap, language: language)
                != AppLocalization.string(.magicMouseTwoFingerTap, language: language))
    }
}
