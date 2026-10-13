import Foundation
import Testing
@testable import rebind

@MainActor struct TrackpadSingleTapLabelTests {
    @Test(arguments: [(AppLanguage.en, "Tap · 3 fingers"), (.ru, "Касание · 3 пальца"),
                      (.de, "Tippen · 3 Finger"), (.fr, "Toucher · 3 doigts")])
    func savedThreeFingerRuleHasItsOwnLocalizedLabel(_ sample: (AppLanguage, String)) {
        #expect(AppLocalization.string(.threeFingerTap, language: sample.0) == sample.1)
        #expect(AppLocalization.string(.threeFingerTap, language: sample.0)
                != AppLocalization.string(.fourFingerTap, language: sample.0))
    }
}
