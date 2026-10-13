import Testing
@testable import rebind

@MainActor struct TrackpadDoubleTapLabelTests {
    @Test(arguments: [(AppLanguage.en, "Double tap · 3 fingers", "Double tap · 4 fingers", "Double tap · 2 fingers"),
                      (.ru, "Двойное касание · 3 пальца", "Двойное касание · 4 пальца", "Двойное касание · 2 пальца"),
                      (.de, "Doppeltippen · 3 Finger", "Doppeltippen · 4 Finger", "Doppeltippen · 2 Finger"),
                      (.fr, "Double toucher · 3 doigts", "Double toucher · 4 doigts", "Double toucher · 2 doigts")])
    func distinctDoubleLabelsExistInAllLanguages(_ sample: (AppLanguage, String, String, String)) {
        #expect(AppLocalization.string(.threeFingerDoubleTap, language: sample.0) == sample.1)
        #expect(AppLocalization.string(.fourFingerDoubleTap, language: sample.0) == sample.2)
        #expect(AppLocalization.string(.twoFingerDoubleTap, language: sample.0) == sample.3)
        #expect(sample.1 != AppLocalization.string(.threeFingerTap, language: sample.0))
        #expect(sample.2 != AppLocalization.string(.fourFingerTap, language: sample.0))
        #expect(sample.3 != AppLocalization.string(.fourFingerDoubleTap, language: sample.0))
    }
}