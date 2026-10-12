import Testing
@testable import rebind

@MainActor struct TrackpadDoubleTapLabelTests {
    @Test(arguments: [(AppLanguage.en, "Three-finger double tap", "Four-finger double tap", "Two-finger double tap"),
                      (.ru, "Двойной тап тремя пальцами", "Двойной тап четырьмя пальцами", "Двойной тап двумя пальцами"),
                      (.de, "Doppeltippen mit drei Fingern", "Doppeltippen mit vier Fingern", "Doppeltippen mit zwei Fingern"),
                      (.fr, "Double toucher à trois doigts", "Double toucher à quatre doigts", "Double toucher à deux doigts")])
    func distinctDoubleLabelsExistInAllLanguages(_ sample: (AppLanguage, String, String, String)) {
        #expect(AppLocalization.string(.threeFingerDoubleTap, language: sample.0) == sample.1)
        #expect(AppLocalization.string(.fourFingerDoubleTap, language: sample.0) == sample.2)
        #expect(AppLocalization.string(.twoFingerDoubleTap, language: sample.0) == sample.3)
        #expect(sample.1 != AppLocalization.string(.threeFingerTap, language: sample.0))
        #expect(sample.2 != AppLocalization.string(.fourFingerTap, language: sample.0))
        #expect(sample.3 != AppLocalization.string(.fourFingerDoubleTap, language: sample.0))
    }
}