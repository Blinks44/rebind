import Foundation
import Synchronization
import Testing
@testable import rebind

struct TrackpadCornerTapTests {
    private let lift: UInt64 = 4_000_000_000

    private struct Harness {
        let mailbox: EngineMailbox
        var runtime: TrackpadRuntime
        let buffer: NativeTrackpadBuffer
        var session: TrackpadTapSession
        var nextID: Int32 = 1

        init(corners: [TrackpadCorner] = TrackpadCorner.allCases, threeFingerTap: Bool = false) throws {
            mailbox = EngineMailbox()
            let triggers = corners.map(InputTrigger.cornerTap) + (threeFingerTap ? [.threeFingerTap] : [])
            let rules = triggers.enumerated().map { index, trigger in
                rebind.Binding(scope: .builtInTrackpad, trigger: trigger, modifiers: [],
                               action: .shortcut(.init(keyCode: UInt16(13 + index), modifiers: .command)))
            }
            mailbox.configure(Configuration(isEnabled: true, bindings: rules))
            mailbox.state.withLock { $0.status = .active; $0.foregroundPID = 100 }
            runtime = try #require(mailbox.trackpadRuntime())
            buffer = NativeTrackpadBuffer(mailbox: mailbox)
            buffer.setAccepting(true)
            session = TrackpadTapSession(runtime: runtime, foreground: 100, startedAt: 0)
            consume([], at: 3_900_000_000)
        }

        mutating func consume(_ points: [(x: Float, y: Float)], at time: UInt64) {
            var value = NativeTrackpadFrame(receipt: time, revision: runtime.revision,
                activity: runtime.inputActivity, frame: nextID, time: Double(time) / 1_000_000_000, count: points.count)
            nextID += 1
            let contacts = points.enumerated().map {
                ShortContactRecognizer.Contact(id: Int32($0.offset), x: $0.element.x, y: $0.element.y, pressure: 45)
            }
            value.first = contacts.first
            if contacts.count > 1 { value.second = contacts[1] }
            if contacts.count > 2 { value.third = contacts[2] }
            mailbox.state.withLock { $0.trackpadClicks.observe(value) }
            session.consume(value, at: time)
        }

        mutating func tap(x: Float, y: Float, endingAt time: UInt64, movedTo end: Float? = nil) {
            consume([(x, y)], at: time - 40_000_000)
            consume([(end ?? x, y)], at: time - 20_000_000)
            consume([], at: time)
        }

        func click(_ phase: InputEvent.Phase, at time: UInt64) -> Bool {
            mailbox.handle(InputEvent(trigger: .mouseButton(0), phase: phase, receivedAt: time), secureInput: false)
        }

        mutating func ready(at time: UInt64) -> TrackpadTapGesture? {
            session.takeReadyGesture(from: buffer, at: time)
        }
    }

    private static func point(_ corner: TrackpadCorner) -> (x: Float, y: Float) {
        switch corner {
        case .topLeft: (0.1, 0.9)
        case .topRight: (0.9, 0.9)
        case .bottomLeft: (0.1, 0.1)
        case .bottomRight: (0.9, 0.1)
        }
    }

    @Test(arguments: TrackpadCorner.allCases)
    func configuredCornerTapEmitsExactlyOnceAfterSettling(_ corner: TrackpadCorner) throws {
        var h = try Harness()
        let point = Self.point(corner)
        h.tap(x: point.x, y: point.y, endingAt: lift)
        #expect(h.ready(at: lift + 30_000_000) == nil)
        #expect(h.ready(at: lift + 60_000_000) == .corner(corner))
        #expect(h.ready(at: lift + 70_000_000) == nil)
    }

    @Test func tapOutsideCornersOrInAnUnconfiguredCornerNeverEmits() throws {
        var h = try Harness(corners: [.topLeft])
        h.tap(x: 0.5, y: 0.5, endingAt: lift)
        #expect(h.ready(at: lift + 60_000_000) == nil)
        h.tap(x: 0.9, y: 0.1, endingAt: lift + 200_000_000)
        #expect(h.ready(at: lift + 260_000_000) == nil)
        h.tap(x: 0.1, y: 0.9, endingAt: lift + 400_000_000)
        #expect(h.ready(at: lift + 460_000_000) == .corner(.topLeft))
    }

    @Test func movementOutOfTheCornerCancels() throws {
        var h = try Harness()
        h.tap(x: 0.1, y: 0.9, endingAt: lift, movedTo: 0.2)
        #expect(h.ready(at: lift + 60_000_000) == nil)
    }

    /// Button activity that is not the tap's own click (here: outside the click window) cancels the output.
    @Test func buttonActivityAfterTheTapCancelsAndTheNextTapRecovers() throws {
        var h = try Harness()
        h.tap(x: 0.1, y: 0.1, endingAt: lift)
        _ = h.mailbox.handle(InputEvent(trigger: .mouseButton(0), phase: .down), secureInput: false)
        h.runtime = try #require(h.mailbox.trackpadRuntime())
        h.session.update(runtime: h.runtime, foreground: 100)
        #expect(h.ready(at: lift + 60_000_000) == nil)
        h.consume([], at: lift + 300_000_000)
        h.tap(x: 0.1, y: 0.1, endingAt: lift + 400_000_000)
        #expect(h.ready(at: lift + 460_000_000) == .corner(.bottomLeft))
    }

    @Test func oneFingerTapsDoNotDisturbThreeFingerRules() throws {
        var h = try Harness(corners: [.topRight], threeFingerTap: true)
        h.tap(x: 0.5, y: 0.5, endingAt: lift)
        #expect(h.ready(at: lift + 60_000_000) == nil)
        h.consume([(0.3, 0.5), (0.4, 0.5), (0.5, 0.5)], at: lift + 200_000_000)
        h.consume([(0.3, 0.5), (0.4, 0.5), (0.5, 0.5)], at: lift + 220_000_000)
        h.consume([], at: lift + 240_000_000)
        #expect(h.ready(at: lift + 300_000_000) == .single(.threeFinger))
    }

    @Test func mailboxDeliversOnlyTheConfiguredCornerShortcut() throws {
        let h = try Harness(corners: [.topLeft])
        var spoofed = h.runtime
        spoofed.actions[.corner(.topLeft)] = .shortcut(.init(keyCode: 0, modifiers: .command))
        #expect(h.mailbox.submitTrackpad(spoofed, gesture: .corner(.topLeft), pid: 100, at: lift) == false)
        #expect(h.mailbox.submitTrackpad(h.runtime, gesture: .corner(.topRight), pid: 100, at: lift) == false)
        #expect(h.mailbox.handle(InputEvent(trigger: .cornerTap(.topLeft), phase: .down), secureInput: false) == false)
        #expect(h.mailbox.submitTrackpad(h.runtime, gesture: .corner(.topLeft), pid: 100, at: lift))
    }

    @Test(arguments: TrackpadCorner.allCases)
    func cornerRuleRoundTripsAndOlderSchemasCannotCarryIt(_ corner: TrackpadCorner) throws {
        let binding = rebind.Binding(scope: .builtInTrackpad, trigger: .cornerTap(corner), modifiers: [],
                                     action: .shortcut(.init(keyCode: 13, modifiers: .command)))
        let configuration = Configuration(isEnabled: true, bindings: [binding])
        try configuration.validate()
        let decoded = try JSONDecoder().decode(Configuration.self, from: JSONEncoder().encode(configuration))
        #expect(decoded.bindings == [binding] && decoded.schemaVersion == Configuration.currentSchemaVersion)
        var old = configuration
        old.schemaVersion = 27
        #expect(throws: ConfigurationError.invalid) { try old.migrated() }
    }

    @MainActor @Test(arguments: [AppLanguage.en, .ru, .de, .fr])
    func cornerLabelsAreDistinctAndTranslated(_ language: AppLanguage) {
        let titles = TrackpadCorner.allCases.map { AppLocalization.string($0.title, language: language) }
        #expect(Set(titles).count == 4)
        if language != .en {
            #expect(titles != TrackpadCorner.allCases.map { AppLocalization.string($0.title, language: .en) })
        }
    }

    @Test func tapToClickAfterAConfiguredCornerTapIsConsumedAndTheRuleStillFires() throws {
        var h = try Harness(corners: [.topLeft])
        h.tap(x: 0.1, y: 0.9, endingAt: lift)
        #expect(h.click(.down, at: lift + 12_000_000))
        #expect(h.click(.up, at: lift + 28_000_000))
        #expect(h.mailbox.trackpadRuntime() == h.runtime)
        #expect(h.ready(at: lift + 60_000_000) == .corner(.topLeft))
        #expect(h.click(.down, at: lift + 100_000_000) == false)
        #expect(h.click(.up, at: lift + 110_000_000) == false)
    }

    @Test func delayedTapToClickInsideTheWindowIsConsumedAfterTheRuleFired() throws {
        var h = try Harness(corners: [.bottomRight])
        h.tap(x: 0.9, y: 0.1, endingAt: lift)
        #expect(h.ready(at: lift + 60_000_000) == .corner(.bottomRight))
        #expect(h.click(.down, at: lift + 300_000_000))
        #expect(h.click(.up, at: lift + 310_000_000))
    }

    @Test func clicksThatAreNotACornerTapPassThrough() throws {
        var h = try Harness(corners: [.topLeft])
        h.tap(x: 0.5, y: 0.5, endingAt: lift)
        #expect(h.click(.down, at: lift + 12_000_000) == false)
        #expect(h.click(.up, at: lift + 28_000_000) == false)
        h.tap(x: 0.9, y: 0.9, endingAt: lift + 300_000_000)
        #expect(h.click(.down, at: lift + 312_000_000) == false)
        h.tap(x: 0.1, y: 0.9, endingAt: lift + 600_000_000)
        #expect(h.click(.down, at: lift + 600_000_000 + TrackpadClickFilter.tapClickWindow + 1) == false)
        h.tap(x: 0.1, y: 0.9, endingAt: lift + 1_400_000_000, movedTo: 0.2)
        #expect(h.click(.down, at: lift + 1_412_000_000) == false)
    }

    @Test func physicalClickWithAFingerOnTheCornerPassesThrough() throws {
        var h = try Harness(corners: [.topLeft])
        h.consume([(0.1, 0.9)], at: lift - 40_000_000)
        h.consume([(0.1, 0.9)], at: lift - 20_000_000)
        #expect(h.click(.down, at: lift - 10_000_000) == false)
        #expect(h.click(.up, at: lift - 5_000_000) == false)
        h.consume([], at: lift)
        #expect(h.click(.down, at: lift + 12_000_000) == false)
    }

    /// Tap to click (with three-finger drag, also for three fingers) turns the tap itself
    /// into a click after the lift; that click passes on and must not cancel the rule.
    @Test(arguments: [0 as UInt32, 1])
    func clickMadeFromAThreeFingerTapPassesAndKeepsTheRule(_ button: UInt32) throws {
        var h = try Harness(corners: [], threeFingerTap: true)
        let fingers: [(x: Float, y: Float)] = [(0.3, 0.5), (0.4, 0.5), (0.5, 0.5)]
        h.consume(fingers, at: lift - 40_000_000)
        h.consume(fingers, at: lift - 20_000_000)
        h.consume([], at: lift)
        let activity = h.mailbox.state.withLock { $0.inputActivity }
        func press(_ phase: InputEvent.Phase, _ time: UInt64) -> Bool {
            h.mailbox.handle(InputEvent(trigger: .mouseButton(button), phase: phase, receivedAt: time), secureInput: false)
        }
        #expect(press(.down, lift + 12_000_000) == false)
        #expect(press(.up, lift + 28_000_000) == false)
        #expect(h.mailbox.state.withLock { $0.inputActivity } == activity)
        #expect(h.mailbox.trackpadRuntime() == h.runtime)
        #expect(h.ready(at: lift + 60_000_000) == .single(.threeFinger))
    }

    /// A finger on either surface makes the press possibly physical, so it still cancels.
    @Test(arguments: [false, true])
    func pressWithAFingerDownIsActivityEvenRightAfterATap(_ onMagicTrackpad: Bool) throws {
        var h = try Harness(corners: [], threeFingerTap: true)
        let fingers: [(x: Float, y: Float)] = [(0.3, 0.5), (0.4, 0.5), (0.5, 0.5)]
        h.consume(fingers, at: lift - 40_000_000)
        h.consume(fingers, at: lift - 20_000_000)
        h.consume([], at: lift)
        var touch = NativeTrackpadFrame(receipt: lift + 5_000_000, revision: 0, activity: 0, frame: 1, time: 4.005, count: 1)
        touch.first = .init(id: 9, x: 0.5, y: 0.5, pressure: 45)
        if onMagicTrackpad { h.mailbox.state.withLock { $0.magicTrackpadClicks.observe(touch) } }
        else { h.consume([(0.5, 0.5)], at: lift + 5_000_000) }
        let activity = h.mailbox.state.withLock { $0.inputActivity }
        #expect(h.click(.down, at: lift + 12_000_000) == false)
        #expect(h.mailbox.state.withLock { $0.inputActivity } != activity)
    }

    @Test func pausedOrEditingRulesNeverConsumeAClick() throws {
        var h = try Harness(corners: [.topLeft])
        h.tap(x: 0.1, y: 0.9, endingAt: lift)
        h.mailbox.state.withLock { $0.editing = true }
        #expect(h.click(.down, at: lift + 12_000_000) == false)
        #expect(h.click(.up, at: lift + 28_000_000) == false)
    }
}
