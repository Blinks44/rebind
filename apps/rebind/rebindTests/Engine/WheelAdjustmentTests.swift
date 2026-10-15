import CoreGraphics
import Foundation
import Testing
@testable import rebind

@MainActor struct WheelAdjustmentTests {
    private func wheel(vertical: Int32, horizontal: Int32 = 0) throws -> CGEvent {
        try #require(CGEvent(scrollWheelEvent2Source: nil, units: .line, wheelCount: 2,
                             wheel1: vertical, wheel2: horizontal, wheel3: 0))
    }

    @Test func aSteppedWheelEventIsReversedAndMultipliedOnBothAxes() throws {
        let event = try wheel(vertical: 2, horizontal: -1)
        ScrollEventAdapter.adjust(event, by: WheelAdjustment(reverses: true, multiplier: 3))
        #expect(event.getIntegerValueField(.scrollWheelEventDeltaAxis1) == -6)
        #expect(event.getIntegerValueField(.scrollWheelEventDeltaAxis2) == 3)
        #expect(event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1) < 0)
        #expect(event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis2) > 0)
    }

    @Test func aContinuousWheelWithoutPhaseIsReversed() throws {
        // A high-resolution wheel (such as an MX Master without Logitech software) arrives as
        // continuous pixel scrolling with no gesture phase.
        let wheel = try #require(CGEvent(scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 1,
                                         wheel1: 12, wheel2: 0, wheel3: 0))
        #expect(wheel.getIntegerValueField(.scrollWheelEventIsContinuous) == 1)
        let before = wheel.getIntegerValueField(.scrollWheelEventPointDeltaAxis1)
        ScrollEventAdapter.adjust(wheel, by: WheelAdjustment(reverses: true, multiplier: 2))
        #expect(before > 0)
        #expect(wheel.getIntegerValueField(.scrollWheelEventPointDeltaAxis1) == -2 * before)
    }

    @Test(arguments: [CGEventField.scrollWheelEventScrollPhase, .scrollWheelEventMomentumPhase])
    func trackpadAndMomentumScrollingIsNeverChanged(_ phase: CGEventField) throws {
        let trackpad = try #require(CGEvent(scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 1,
                                            wheel1: 12, wheel2: 0, wheel3: 0))
        trackpad.setIntegerValueField(phase, value: 2)
        let before = trackpad.getIntegerValueField(.scrollWheelEventPointDeltaAxis1)
        ScrollEventAdapter.adjust(trackpad, by: WheelAdjustment(reverses: true, multiplier: 2))
        #expect(trackpad.getIntegerValueField(.scrollWheelEventPointDeltaAxis1) == before)
        let stepped = try wheel(vertical: 1)
        stepped.setIntegerValueField(phase, value: 1)
        ScrollEventAdapter.adjust(stepped, by: WheelAdjustment(reverses: true, multiplier: 1))
        #expect(stepped.getIntegerValueField(.scrollWheelEventDeltaAxis1) == 1)
    }

    @Test func theAdjustmentAppliesOnlyWhileRulesRunAndPersists() throws {
        var configuration = Configuration(isEnabled: true)
        let mailbox = EngineMailbox()
        mailbox.configure(configuration)
        mailbox.state.withLock { $0.status = .active }
        #expect(mailbox.wheelAdjustment == nil)
        configuration.reversesMouseWheel = true
        configuration.mouseWheelSpeed = .fast
        mailbox.configure(configuration)
        #expect(mailbox.wheelAdjustment == WheelAdjustment(reverses: true, multiplier: 2))
        configuration.excludedApplications = [ExcludedApplication(target: ApplicationTarget(
            url: URL(filePath: "/Applications/Game.app"), bundleIdentifier: "com.example.game"))]
        mailbox.configure(configuration)
        mailbox.setForegroundApplication("com.example.game")
        #expect(mailbox.wheelAdjustment == nil)
        mailbox.setForegroundApplication(nil)
        mailbox.suspend(true)
        #expect(mailbox.wheelAdjustment == nil)
        #expect(try JSONDecoder().decode(Configuration.self, from: JSONEncoder().encode(configuration)) == configuration)
        configuration.schemaVersion = 33
        #expect(throws: ConfigurationError.invalid) { try configuration.migrated() }
    }

    @Test func theSupportReportHasCountsAndStatesButNoRuleContent() throws {
        let store = ConfigurationStore(url: FileManager.default.temporaryDirectory
            .appending(path: "RebindReport-\(UUID())").appending(path: "config.json"))
        defer { try? FileManager.default.removeItem(at: store.url.deletingLastPathComponent()) }
        var secret = rebind.Binding(scope: .allKeyboards, trigger: .key(0), modifiers: .command, action: .text("my secret snippet"))
        secret.note = "private note"
        let app = rebind.Binding(scope: .allMice, trigger: .mouseButton(3), modifiers: [],
            action: .workspace(.openApplication(ApplicationTarget(url: URL(filePath: "/Applications/Secret.app"),
                                                                  bundleIdentifier: "com.example.secret"))))
        try store.save(Configuration(bindings: [secret, app]))
        let report = AppModel(store: store).supportReport(system: "Version 27.0")
        #expect(report.contains("macOS: Version 27.0"))
        #expect(report.contains("Selected profile, keyboard: 1 bindings, 1 enabled"))
        #expect(report.contains("insertText ×1") && report.contains("openApplication ×1"))
        for leaked in ["secret", "Secret", "private note", "/Applications"] { #expect(report.contains(leaked) == false) }
    }
}
