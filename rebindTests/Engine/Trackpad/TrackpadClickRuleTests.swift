import Foundation
import Synchronization
import Testing
@testable import rebind

struct TrackpadClickRuleTests {
    private let now: UInt64 = 4_000_000_000

    private struct Harness {
        let mailbox = EngineMailbox()
        var nextID: Int32 = 1

        init(fingers: [Int] = [2, 3, 4]) {
            let rules = fingers.map {
                rebind.Binding(scope: .builtInTrackpad, trigger: .trackpadClick(fingers: $0), modifiers: [],
                               action: .shortcut(.init(keyCode: UInt16(10 + $0), modifiers: .command)))
            }
            mailbox.configure(Configuration(isEnabled: true, bindings: rules))
            mailbox.state.withLock { $0.status = .active; $0.foregroundPID = 100 }
        }

        mutating func rest(fingers: Int, at time: UInt64) {
            var frame = NativeTrackpadFrame(receipt: time, revision: 0, activity: 0, frame: nextID,
                                            time: Double(time) / 1_000_000_000, count: fingers)
            nextID += 1
            let contacts = (0..<fingers).map {
                ShortContactRecognizer.Contact(id: Int32($0), x: 0.3 + Float($0) * 0.1, y: 0.5, pressure: 120)
            }
            frame.first = contacts.first
            if fingers > 1 { frame.second = contacts[1] }
            if fingers > 2 { frame.third = contacts[2] }
            if fingers > 3 { frame.fourth = contacts[3] }
            mailbox.state.withLock { $0.trackpadClicks.observe(frame) }
        }

        func button(_ number: UInt32, _ phase: InputEvent.Phase, at time: UInt64) -> Bool {
            mailbox.handle(InputEvent(trigger: .mouseButton(number), phase: phase, receivedAt: time), secureInput: false)
        }

        var queued: [KeyboardShortcut] { mailbox.state.withLock { $0.pending.compactMap(\.shortcut) } }
    }

    @Test(arguments: [3, 4])
    func pressWithRestingFingersRunsTheRuleInsteadOfTheClick(_ fingers: Int) {
        var h = Harness()
        h.rest(fingers: fingers, at: now)
        let activity = h.mailbox.state.withLock { $0.inputActivity }
        #expect(h.button(0, .down, at: now + 5_000_000))
        #expect(h.button(0, .drag, at: now + 8_000_000))
        #expect(h.button(0, .up, at: now + 40_000_000))
        #expect(h.queued == [.init(keyCode: UInt16(10 + fingers), modifiers: .command)])
        #expect(h.mailbox.state.withLock { $0.inputActivity } != activity)
        #expect(h.button(0, .up, at: now + 50_000_000) == false)
    }

    @Test func twoFingersCountOnlyForTheSecondaryButton() {
        var h = Harness()
        h.rest(fingers: 2, at: now)
        #expect(h.button(0, .down, at: now + 5_000_000) == false)
        #expect(h.button(0, .up, at: now + 20_000_000) == false)
        #expect(h.queued.isEmpty)
        h.rest(fingers: 2, at: now + 30_000_000)
        #expect(h.button(1, .down, at: now + 35_000_000))
        #expect(h.button(1, .up, at: now + 60_000_000))
        #expect(h.queued == [.init(keyCode: 12, modifiers: .command)])
    }

    @Test func otherClicksPassThrough() {
        var h = Harness(fingers: [3])
        h.rest(fingers: 1, at: now)
        #expect(h.button(0, .down, at: now + 5_000_000) == false)
        h.rest(fingers: 4, at: now + 10_000_000)
        #expect(h.button(0, .down, at: now + 15_000_000) == false)
        h.rest(fingers: 3, at: now + 20_000_000)
        #expect(h.button(0, .down, at: now + 20_000_000 + TrackpadClickFilter.maximumFrameAge + 1) == false)
        h.rest(fingers: 0, at: now + 400_000_000)
        #expect(h.button(0, .down, at: now + 405_000_000) == false)
        #expect(h.queued.isEmpty)
    }

    @Test func pausedEditingOrSecureInputNeverConsumes() {
        var h = Harness()
        h.rest(fingers: 3, at: now)
        #expect(h.mailbox.handle(InputEvent(trigger: .mouseButton(0), phase: .down, receivedAt: now + 1), secureInput: true) == false)
        h.mailbox.state.withLock { $0.status = .active; $0.editing = true }
        h.rest(fingers: 3, at: now + 10_000_000)
        #expect(h.button(0, .down, at: now + 15_000_000) == false)
        #expect(h.queued.isEmpty)
    }

    @Test func clickRulesAloneKeepContactCaptureRunning() {
        let h = Harness(fingers: [4])
        #expect(h.mailbox.trackpadRuntime()?.hasClickRules == true)
        #expect(Harness(fingers: []).mailbox.trackpadRuntime() == nil)
    }

    @Test(arguments: 2...4)
    func clickRuleRoundTripsAndOlderSchemasCannotCarryIt(_ fingers: Int) throws {
        let binding = rebind.Binding(scope: .builtInTrackpad, trigger: .trackpadClick(fingers: fingers), modifiers: [],
                                     action: .shortcut(.init(keyCode: 13, modifiers: .command)))
        let configuration = Configuration(isEnabled: true, bindings: [binding])
        try configuration.validate()
        let decoded = try JSONDecoder().decode(Configuration.self, from: JSONEncoder().encode(configuration))
        #expect(decoded.bindings == [binding])
        var old = configuration
        old.schemaVersion = 28
        #expect(throws: ConfigurationError.invalid) { try old.migrated() }
        var invalid = binding
        invalid.trigger = .trackpadClick(fingers: 5)
        #expect(invalid.isValid == false)
    }

    @MainActor @Test(arguments: [AppLanguage.en, .ru, .de, .fr])
    func clickLabelsAreDistinctAndTranslated(_ language: AppLanguage) {
        let titles = (2...4).map { AppLocalization.string(TrackpadPreset.clickTitle(fingers: $0), language: language) }
        #expect(Set(titles).count == 3)
        if language != .en {
            #expect(titles != (2...4).map { AppLocalization.string(TrackpadPreset.clickTitle(fingers: $0), language: .en) })
        }
    }
}
