import CoreGraphics
import Foundation
import Testing
@testable import rebind

@MainActor struct ExcludedApplicationTests {
    private let output = KeyboardShortcut(keyCode: 0, modifiers: .command)
    private let game = ApplicationTarget(url: URL(filePath: "/Applications/Game.app"), bundleIdentifier: "com.example.game")

    private func configuration() -> Configuration {
        var configuration = Configuration(isEnabled: true, bindings: [
            rebind.Binding(scope: .allMice, trigger: .mouseButton(3), modifiers: [], action: .shortcut(output))])
        configuration.excludedApplications = [ExcludedApplication(target: game)]
        return configuration
    }

    private func mailbox() -> EngineMailbox {
        let mailbox = EngineMailbox()
        mailbox.configure(configuration())
        mailbox.state.withLock { $0.status = .active }
        return mailbox
    }

    private func event(_ phase: InputEvent.Phase) -> InputEvent { InputEvent(trigger: .mouseButton(3), phase: phase) }

    @Test func inputPassesThroughOnlyWhileAnExcludedAppIsInFront() {
        let mailbox = mailbox()
        mailbox.setForegroundApplication("com.apple.Safari")
        #expect(mailbox.handle(event(.down), secureInput: false))
        #expect(mailbox.handle(event(.up), secureInput: false))
        mailbox.setForegroundApplication(game.bundleIdentifier)
        #expect(mailbox.state.withLock { $0.pending.isEmpty && $0.enabled })
        #expect(mailbox.handle(event(.down), secureInput: false) == false)
        #expect(mailbox.handle(event(.up), secureInput: false) == false)
        #expect(mailbox.trackpadRuntime() == nil)
        mailbox.setForegroundApplication(nil)
        #expect(mailbox.handle(event(.down), secureInput: false))
        #expect(mailbox.state.withLock { $0.pending } == [.shortcut(output)])
    }

    @Test func enteringAnExcludedAppKeepsTheReleaseOfASwallowedPressAndDropsQueuedWork() throws {
        let mailbox = mailbox()
        #expect(mailbox.handle(event(.down), secureInput: false))
        let dispatch = try #require(mailbox.nextAction())
        mailbox.setForegroundApplication(game.bundleIdentifier)
        #expect(mailbox.dispatchIsCurrent(dispatch) == false)
        #expect(mailbox.handle(event(.up), secureInput: false))
    }

    @Test func theListPersistsRejectsDuplicatesAndRebindItselfAndOldSchemasCannotCarryIt() throws {
        let configuration = configuration()
        let decoded = try JSONDecoder().decode(Configuration.self, from: JSONEncoder().encode(configuration))
        #expect(decoded == configuration)
        var invalid = configuration
        invalid.excludedApplications.append(ExcludedApplication(target: game))
        #expect(throws: ConfigurationError.invalid) { try invalid.validate() }
        invalid.excludedApplications = [ExcludedApplication(target: ApplicationTarget(
            url: URL(filePath: "/Applications/Rebind.app"), bundleIdentifier: "blinks44.rebind"))]
        #expect(throws: ConfigurationError.invalid) { try invalid.validate() }
        var old = configuration
        old.schemaVersion = 33
        #expect(throws: ConfigurationError.invalid) { try old.migrated() }
    }

    @Test func theModelAddsAndRemovesAppsThroughStorage() throws {
        let store = ConfigurationStore(url: FileManager.default.temporaryDirectory
            .appending(path: "RebindExcluded-\(UUID())").appending(path: "config.json"))
        defer { try? FileManager.default.removeItem(at: store.url.deletingLastPathComponent()) }
        let model = AppModel(store: store, loadConfiguration: false)
        #expect(model.excludeApplication(game))
        #expect(model.excludeApplication(game) == false)
        #expect(try store.load().excludedApplications.map(\.target) == [game])
        #expect(model.mailbox.state.withLock { $0.excludedApplications } == [game.bundleIdentifier])
        model.includeApplication(game.bundleIdentifier)
        #expect(try store.load().excludedApplications.isEmpty)
    }
}

@MainActor struct ExclusionTogglesAndSmoothScrollingTests {
    private let game = ApplicationTarget(url: URL(filePath: "/Applications/Game.app"), bundleIdentifier: "com.example.game")
    private let output = KeyboardShortcut(keyCode: 0, modifiers: .command)

    private func mailbox(allowsBindings: Bool, allowsSmoothScrolling: Bool) -> EngineMailbox {
        var configuration = Configuration(isEnabled: true, bindings: [
            rebind.Binding(scope: .allMice, trigger: .mouseButton(3), modifiers: [], action: .shortcut(output))])
        configuration.smoothScrolling = true
        configuration.excludedApplications = [ExcludedApplication(target: game, allowsBindings: allowsBindings,
                                                                  allowsSmoothScrolling: allowsSmoothScrolling)]
        let mailbox = EngineMailbox()
        mailbox.configure(configuration)
        mailbox.state.withLock { $0.status = .active }
        mailbox.setForegroundApplication(game.bundleIdentifier)
        return mailbox
    }

    @Test func bindingsAndSmoothScrollingAreExcludedIndependently() {
        let bindingsOnly = mailbox(allowsBindings: true, allowsSmoothScrolling: false)
        #expect(bindingsOnly.handle(InputEvent(trigger: .mouseButton(3), phase: .down), secureInput: false))
        #expect(bindingsOnly.smoothScrolling == nil)
        let smoothOnly = mailbox(allowsBindings: false, allowsSmoothScrolling: true)
        #expect(smoothOnly.handle(InputEvent(trigger: .mouseButton(3), phase: .down), secureInput: false) == false)
        #expect(smoothOnly.smoothScrolling == SmoothScrollingSettings(glide: .standard, scope: .steppedWheels))
        smoothOnly.setForegroundApplication("com.apple.Safari")
        #expect(smoothOnly.smoothScrolling != nil)
        smoothOnly.state.withLock { $0.enabled = false }
        #expect(smoothOnly.smoothScrolling == nil)
    }

    @Test func olderExclusionsKeepSkippingBindingsAndAllowSmoothScrolling() throws {
        var old = Configuration(isEnabled: true)
        old.excludedApplications = [ExcludedApplication(target: game, allowsBindings: false, allowsSmoothScrolling: true)]
        old.schemaVersion = 35
        let data = try JSONEncoder().encode(old)
        #expect(String(decoding: data, as: UTF8.self).contains("allowsBindings") == false)
        let migrated = try JSONDecoder().decode(Configuration.self, from: data).migrated()
        #expect(migrated.schemaVersion == Configuration.currentSchemaVersion)
        #expect(migrated.excludedApplications == [ExcludedApplication(target: game, allowsBindings: false, allowsSmoothScrolling: true)])
        var newer = Configuration()
        newer.smoothScrolling = true
        newer.schemaVersion = 35
        #expect(throws: ConfigurationError.invalid) { try newer.migrated() }
    }

    @Test func aGlideEasesOutAndFinishesTheLastPoint() {
        let first = SmoothScroller.step(remaining: 100, interval: 1.0 / 120, timeConstant: 0.09)
        #expect(first > 8 && first < 9)
        #expect(SmoothScroller.step(remaining: -0.6, interval: 1.0 / 120, timeConstant: 0.09) == -0.6)
        var remaining = 120.0
        var frames = 0
        while remaining != 0, frames < 1000 {
            remaining -= SmoothScroller.step(remaining: remaining, interval: 1.0 / 120, timeConstant: 0.09)
            frames += 1
        }
        #expect(frames > 30 && frames < 90)
        #expect(SmoothScroller.add(-10, to: 50) == -10)
        #expect(SmoothScroller.add(10, to: 50) == 60)
    }

    @Test(arguments: [false, true])
    func glidesOnlyUnmodifiedPhaseLessWheels(_ continuous: Bool) throws {
        let stepped = SmoothScrollingSettings(glide: .standard, scope: .steppedWheels)
        let all = SmoothScrollingSettings(glide: .standard, scope: .allWheels)
        let event = try #require(CGEvent(scrollWheelEvent2Source: nil, units: continuous ? .pixel : .line, wheelCount: 1,
                                         wheel1: 3, wheel2: 0, wheel3: 0))
        #expect(SmoothScroller.applies(to: event, settings: stepped) == !continuous)
        #expect(SmoothScroller.applies(to: event, settings: all))
        event.flags = .maskCommand
        #expect(SmoothScroller.applies(to: event, settings: all) == false)
        event.flags = .maskShift
        #expect(SmoothScroller.applies(to: event, settings: all) == false)
        event.flags = .maskAlternate
        #expect(SmoothScroller.applies(to: event, settings: all))
        event.setIntegerValueField(.scrollWheelEventScrollPhase, value: 2)
        #expect(SmoothScroller.applies(to: event, settings: all) == false)
    }

    @Test func hidingTheWarningIsRememberedPerApp() throws {
        let store = ConfigurationStore(url: FileManager.default.temporaryDirectory
            .appending(path: "RebindCompanion-\(UUID())").appending(path: "config.json"))
        defer { try? FileManager.default.removeItem(at: store.url.deletingLastPathComponent()) }
        let model = AppModel(store: store, loadConfiguration: false)
        let hub = try #require(CompanionApp.known.first { $0.name == "Logitech G HUB" })
        model.dismissCompanionWarning(for: [hub])
        #expect(try store.load().dismissedCompanionApps == ["Logitech G HUB"])
        model.dismissCompanionWarning(for: [hub])
        #expect(model.configuration.dismissedCompanionApps == ["Logitech G HUB"])
    }
}
