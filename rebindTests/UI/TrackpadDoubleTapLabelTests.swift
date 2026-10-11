import Testing
@testable import rebind

@MainActor struct TrackpadDoubleTapLabelTests {
    @Test(arguments: [(AppLanguage.en, "Three-finger double tap", "Four-finger double tap"),
                      (.ru, "Двойной тап тремя пальцами", "Двойной тап четырьмя пальцами"),
                      (.de, "Doppeltippen mit drei Fingern", "Doppeltippen mit vier Fingern"),
                      (.fr, "Double toucher à trois doigts", "Double toucher à quatre doigts")])
    func distinctDoubleLabelsExistInAllLanguages(_ sample: (AppLanguage, String, String)) {
        #expect(AppLocalization.string(.threeFingerDoubleTap, language: sample.0) == sample.1)
        #expect(AppLocalization.string(.fourFingerDoubleTap, language: sample.0) == sample.2)
        #expect(sample.1 != AppLocalization.string(.threeFingerTap, language: sample.0))
        #expect(sample.2 != AppLocalization.string(.fourFingerTap, language: sample.0))
    }
}
