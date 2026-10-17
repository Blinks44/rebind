import AppKit
import Testing
@testable import rebind

@MainActor struct MenuPointerSpeedTests {
    private let values = [400, 800, 1600, 3200]

    @Test func sliderStartsAtTheNearestListedValue() {
        let view = makeView(dpi: 1500) { _ in }
        #expect(view.slider.minValue == 0)
        #expect(view.slider.maxValue == 3)
        #expect(view.shownValue == 1600)
        #expect(view.slider.accessibilityValueDescription() == "1600 DPI")
        #expect(view.slider.accessibilityLabel() == "MX Master 3S, Pointer speed")
    }

    @Test func aChangeOutsideADragCommitsOnceAndSnaps() {
        var committed: [Int] = []
        let view = makeView(dpi: 800) { committed.append($0) }
        view.slider.doubleValue = 2.6
        view.slider.sendAction(view.slider.action, to: view.slider.target)
        view.slider.sendAction(view.slider.action, to: view.slider.target)
        #expect(committed == [3200])
        #expect(view.slider.accessibilityValueDescription() == "3200 DPI")
    }

    @Test func disabledSliderCannotChange() {
        let view = makeView(dpi: 800, enabled: false) { _ in }
        #expect(!view.slider.isEnabled)
    }

    private func makeView(dpi: Int, enabled: Bool = true, commit: @escaping (Int) -> Void) -> MenuPointerSpeedView {
        MenuPointerSpeedView(name: "MX Master 3S", dpi: dpi, values: values, enabled: enabled,
                             accessibilityLabel: "MX Master 3S, Pointer speed",
                             valueText: { "\($0) DPI" }, commit: commit)
    }
}
