import Foundation
import Testing
@testable import rebind

@MainActor struct TrackpadSingleTapLabelTests {
    @Test(arguments: [(AppLanguage.en, "Three-finger tap"), (.ru, "Тап тремя пальцами"),
                      (.de, "Tippen mit drei Fingern"), (.fr, "Toucher à trois doigts")])
    func savedThreeFingerRuleHasItsOwnLocalizedLabel(_ sample: (AppLanguage, String)) {
        #expect(AppLocalization.string(.threeFingerTap, language: sample.0) == sample.1)
        #expect(AppLocalization.string(.threeFingerTap, language: sample.0)
                != AppLocalization.string(.fourFingerTap, language: sample.0))
    }
}
