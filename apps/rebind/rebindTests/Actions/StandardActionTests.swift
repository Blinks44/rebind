import AppKit
import CoreGraphics
import Foundation
import Synchronization
import Testing
@testable import rebind

struct StandardActionTests {
    @MainActor @Test func newCatalogNamesAndSymbolsResolveInEveryLanguage() {
        let kinds: [ActionKind] = [.spotlight, .forceQuitWindow, .emojiSymbols, .toggleDock, .hideOthers, .lookUp,
            .quitFrontApplication, .newWindow, .find, .reload, .save, .openApps, .fastForward, .rewind,
            .toggleMicrophoneMute, .fillWindowWithStageManager]
        for kind in kinds {
            #expect(NSImage(systemSymbolName: kind.symbol, accessibilityDescription: nil) != nil)
            for language in AppLanguage.allCases {
                let title = AppLocalization.string(kind.title, language: language)
                #expect(title.isEmpty == false)
                #expect(title.hasSuffix("Action") == false)
            }
        }
    }

    @Test func fixedCommandsHaveTheDocumentedKeys() {
        let expected: [(ActionKind, UInt16, ModifierSet)] = [
            (.spotlight, 49, .command), (.forceQuitWindow, 53, [.option, .command]),
            (.emojiSymbols, 49, [.control, .command]), (.toggleDock, 2, [.option, .command]),
            (.hideOthers, 4, [.option, .command]), (.lookUp, 2, [.control, .command]),
            (.quitFrontApplication, 12, .command), (.newWindow, 45, .command),
            (.find, 3, .command), (.reload, 15, .command), (.save, 1, .command)
        ]
        for (kind, code, modifiers) in expected {
            #expect(kind.fixedShortcut == KeyboardShortcut(keyCode: code, modifiers: modifiers))
        }
    }

    @Test func appsUsesTheVerifiedSystemBundleWithoutLaunchingIt() {
        let action = WorkspaceAction.openApps
        #expect(action.isSupported)
        #expect(WorkspacePreparation.prepare(action) == .application(ApplicationTarget(
            url: URL(filePath: "/System/Applications/Apps.app").standardizedFileURL,
            bundleIdentifier: "com.apple.apps.launcher"), activateOnly: false))
        #expect(ActionKind.openApps.configuredAction(shortcut: nil) == .workspace(.openApps))
    }

    @Test func microphoneAvailabilityIsIndependentOfTheOutputAndNeverSendsASoundKey() {
        let input = AudioOutputCapabilities(inputDeviceID: 71, microphoneMute: true)
        #expect(input.supports(.toggleMicrophoneMute))
        #expect(input.supports(.volumeUp) == false)
        #expect(input.deviceID(for: .system(.toggleMicrophoneMute)) == 71)
        #expect(AudioOutputCapabilities(deviceID: 5, volume: true, mute: true).supports(.toggleMicrophoneMute) == false)
        #expect(MediaKeySender.events(SystemAction.toggleMicrophoneMute) == nil)
        #expect(RebindAction.system(.toggleMicrophoneMute).canBeHeld == false)
    }

    @Test(arguments: [false, true])
    func microphoneToggleReadsCurrentStateAndDoesNotRememberAnOldVolume(_ muted: Bool) {
        var writes: [Bool] = []
        let result = CoreAudioInput.toggleMute(device: 71, canPerform: { true }, defaultDevice: { 71 },
            read: { _ in muted }, write: { device, value in #expect(device == 71); writes.append(value); return true })
        #expect(result == .performed)
        #expect(writes == [!muted])
    }

    @Test func replacedOrCancelledMicrophoneNeverReceivesTheQueuedWrite() {
        var current: UInt32 = 71
        var writes = 0
        let replaced = CoreAudioInput.toggleMute(device: 71, canPerform: { true }, defaultDevice: { current },
            read: { _ in current = 72; return false }, write: { _, _ in writes += 1; return true })
        #expect(replaced == .unavailable)
        var allowed = true
        let cancelled = CoreAudioInput.toggleMute(device: 71, canPerform: { allowed }, defaultDevice: { 71 },
            read: { _ in allowed = false; return false }, write: { _, _ in writes += 1; return true })
        #expect(cancelled == .cancelled)
        #expect(writes == 0)
    }

    @Test func mouseRuleQueuesTheDefaultMicrophoneRatherThanTheOutput() throws {
        let caps = AudioOutputCapabilities(deviceID: 5, volume: true, mute: true, inputDeviceID: 71, microphoneMute: true)
        let mailbox = EngineMailbox()
        mailbox.updateAudioCapabilities(caps)
        mailbox.configure(Configuration(isEnabled: true, bindings: [.init(scope: .allMice, trigger: .mouseButton(3),
            modifiers: [], action: .system(.toggleMicrophoneMute))]))
        mailbox.state.withLock { $0.status = .active }
        let devices = Mutex<[UInt32]>([])
        let worker = ActionWorker(mailbox: mailbox, capabilities: { caps }, performAudio: { action, device, canPerform in
            #expect(action == .toggleMicrophoneMute && canPerform())
            devices.withLock { $0.append(device) }; return .performed
        }, secureInput: { false }, postingAllowed: { true })
        #expect(mailbox.handle(InputEvent(trigger: .mouseButton(3), phase: .down), secureInput: false))
        worker.service(at: 0)
        #expect(devices.withLock { $0 } == [71])
    }

    @Test(arguments: [RebindAction.system(.toggleMicrophoneMute), .media(.fastForward), .media(.rewind),
                      .workspace(.openApps), .windowLayout(.fillWithStageManager)])
    func newPayloadsRoundTripAndCannotBeSmuggledIntoSchema44(_ action: RebindAction) throws {
        let binding = rebind.Binding(scope: .allMice, trigger: .mouseButton(3), modifiers: [], action: action)
        let config = Configuration(bindings: [binding])
        #expect(try JSONDecoder().decode(Configuration.self, from: JSONEncoder().encode(config)) == config)
        var old = Configuration(schemaVersion: 44)
        old.profiles.append(RuleProfile(name: "Inactive", bindings: [binding]))
        #expect(throws: ConfigurationError.invalid) { try old.migrated() }
        #expect(try Configuration(schemaVersion: 44).migrated().schemaVersion == 45)
    }
}

struct LeftInsetFillTests {
    let display = WindowDisplay(frame: CGRect(x: 0, y: 0, width: 2560, height: 1440),
                                visibleFrame: CGRect(x: 0, y: 30, width: 2560, height: 1329))
    let window = CGRect(x: 200, y: 100, width: 800, height: 600)

    @Test func fillNeedsOnlyDisplayGeometryEvenWithoutStageManagerMetadata() throws {
        let target = try #require(WindowLayoutGeometry.target(.fillWithStageManager, window: window, displays: [display]))
        #expect(target.minX == 220)
        #expect(target.minY == display.visibleFrame.minY && target.maxY == display.visibleFrame.maxY)
        #expect(target.maxX == display.visibleFrame.maxX)
        #expect(WindowLayoutGeometry.target(.fill, window: window, displays: [display]) == display.visibleFrame)
        #expect(WindowLayoutGeometry.target(.fillWithStageManager, window: target, displays: [display]) == target)
    }

    @Test func selectedDisplayAndDockExclusionsAreRespectedWithoutDoubleInset() throws {
        let external = WindowDisplay(frame: CGRect(x: -1920, y: -200, width: 1920, height: 1080),
            visibleFrame: CGRect(x: -1820, y: -170, width: 1720, height: 1050))
        let target = try #require(WindowLayoutGeometry.target(.fillWithStageManager,
            window: CGRect(x: -1600, y: 0, width: 800, height: 600), displays: [display, external]))
        #expect(target.minX == -1700)
        #expect(target.maxX == external.visibleFrame.maxX)
        #expect(target.minY == external.visibleFrame.minY && target.maxY == external.visibleFrame.maxY)
    }

    @Test func unsafeNarrowAreaAndFullScreenRemainUnavailable() {
        let narrow = WindowDisplay(frame: CGRect(x: 0, y: 0, width: 400, height: 800),
            visibleFrame: CGRect(x: 0, y: 30, width: 400, height: 770))
        #expect(WindowLayoutGeometry.target(.fillWithStageManager,
            window: CGRect(x: 20, y: 50, width: 300, height: 500), displays: [narrow]) == nil)
        #expect(WindowLayoutGeometry.target(.fillWithStageManager, window: display.frame, displays: [display]) == nil)
    }
}
