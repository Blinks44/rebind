import CoreGraphics
import Foundation
import Synchronization
import Testing
@testable import rebind

struct CatalogActionTests {
    @Test func aHeldNamedShortcutKeepsTheEditableRepeatOption() throws {
        let shortcut = try #require(ActionKind.copy.fixedShortcut)
        var binding = rebind.Binding(scope: .allKeyboards, trigger: .key(0), modifiers: [], action: .shortcut(shortcut))
        #expect(ActionKind(binding: binding) == .copy)
        binding.holdsOutput = true
        #expect(ActionKind(binding: binding) == .keyboardShortcut)
        #expect(ActionKind(binding: binding).canBeHeld)
    }

    @Test func everyNamedShortcutIsDistinctSupportedAndRoundTrips() {
        let named = ActionKind.allCases.filter { $0.fixedShortcut != nil }
        #expect(named.count == 17)
        #expect(Set(named.compactMap(\.fixedShortcut)).count == named.count)
        for kind in named {
            let action = kind.configuredAction(shortcut: nil)
            #expect(action?.isSupported == true)
            #expect(action.map(ActionKind.init(action:)) == kind)
            #expect(kind.canBeHeld == false)
        }
    }

    @Test func everyWindowLayoutHasExactlyOneCatalogEntry() {
        for layout in WindowLayoutAction.allCases {
            let kinds = ActionKind.allCases.filter { $0.windowLayoutAction == layout }
            #expect(kinds.count == 1)
            #expect(kinds.first.map { ActionKind(action: .windowLayout(layout)) == $0 } == true)
        }
    }

    @Test func textIsValidatedSplitOnCharacterBoundariesAndPostedAsBalancedTaggedPairs() {
        #expect(ActionKind.insertText.configuredAction(shortcut: nil, text: "") == nil)
        #expect(ActionKind.insertText.configuredAction(shortcut: nil, text: "line\nbreak") == nil)
        #expect(ActionKind.insertText.configuredAction(shortcut: nil, text: String(repeating: "a", count: 501)) == nil)
        #expect(ActionKind.insertText.configuredAction(shortcut: nil, text: "Hi") == .text("Hi"))
        let family = "👨‍👩‍👧‍👦"
        let chunks = TextSender.chunks(of: String(repeating: "a", count: 19) + family + "b")
        #expect(chunks.map(\.count) == [19, family.utf16.count + 1])
        #expect(chunks.flatMap { $0 } == Array((String(repeating: "a", count: 19) + family + "b").utf16))
        var posted: [CGEvent] = []
        #expect(TextSender.perform("héllo", canPerform: { true }, post: { posted.append($0) }) == .performed)
        #expect(posted.map(\.type) == [.keyDown, .keyUp])
        #expect(posted.allSatisfy { $0.getIntegerValueField(.eventSourceUserData) == ShortcutSender.eventTag && $0.flags.isEmpty })
        posted = []
        #expect(TextSender.perform("x", canPerform: { false }, post: { posted.append($0) }) == .cancelled)
        #expect(posted.isEmpty)
    }

    @Test func aTextRuleRunsThroughTheWorkerAndOlderSchemasCannotCarryNewActions() throws {
        let binding = rebind.Binding(scope: .allMice, trigger: .mouseButton(3), modifiers: [], action: .text("Hi"))
        let mailbox = EngineMailbox()
        mailbox.configure(Configuration(isEnabled: true, bindings: [binding]))
        mailbox.state.withLock { $0.status = .active }
        let typed = Mutex<[String]>([])
        let worker = ActionWorker(mailbox: mailbox, capabilities: { AudioOutputCapabilities() },
                                  performText: { text, _ in typed.withLock { $0.append(text) }; return .performed },
                                  secureInput: { false }, postingAllowed: { true })
        #expect(mailbox.handle(InputEvent(trigger: .mouseButton(3), phase: .down), secureInput: false))
        worker.service(at: 0)
        #expect(typed.withLock { $0 } == ["Hi"])
        for action in [RebindAction.text("Hi"), .windowLayout(.nextDisplay)] {
            var old = Configuration(schemaVersion: 33, isEnabled: true, bindings: [binding])
            old.bindings[0].action = action
            #expect(throws: ConfigurationError.invalid) { try old.migrated() }
        }
        var old = Configuration(schemaVersion: 33, isEnabled: true, bindings: [binding])
        old.bindings[0].action = .windowLayout(.leftHalf)
        #expect(try old.migrated().schemaVersion == Configuration.currentSchemaVersion)
    }

    @Test func cancellingTextAfterADownStillReleasesThatKeyAndStopsBeforeTheNextChunk() {
        var allowed = true
        var posted: [CGEventType] = []
        let text = String(repeating: "a", count: 100)
        let result = TextSender.perform(text, canPerform: { allowed }, post: {
            posted.append($0.type)
            allowed = false
        })
        #expect(result == .cancelled)
        #expect(posted == [.keyDown, .keyUp])
    }

    @Test func extendedGraphemesRespectTheQuartzLimitWithoutLosingScalars() {
        let text = "a" + String(repeating: "\u{301}", count: 45) + "🫶🏽"
        #expect(TextSnippet.isValid(text))
        let chunks = TextSender.chunks(of: text)
        #expect(chunks.allSatisfy { (1...TextSender.unitsPerEvent).contains($0.count) })
        #expect(chunks.flatMap { $0 } == Array(text.utf16))
        #expect(chunks.allSatisfy { String(decoding: $0, as: UTF16.self).utf16.elementsEqual($0) })
        let excessive = "a" + String(repeating: "\u{301}", count: TextSnippet.maximumUTF16Length)
        #expect(excessive.count == 1)
        #expect(TextSnippet.isValid(excessive) == false)
    }
}
