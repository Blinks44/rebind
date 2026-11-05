import AppKit
import CoreGraphics
import Foundation
import Synchronization
import Testing

@testable import rebind

struct StandardActionTests {
    @MainActor @Test func newCatalogNamesAndSymbolsResolveInEveryLanguage() {
        let kinds: [ActionKind] = [
            .spotlight, .forceQuitWindow, .emojiSymbols, .toggleDock, .hideOthers, .lookUp,
            .quitFrontApplication, .newWindow, .find, .reload, .save, .openApps, .fastForward, .rewind,
            .toggleMicrophoneMute, .fillWindowWithStageManager, .fillWindowCentered,
        ]
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
            (.find, 3, .command), (.reload, 15, .command), (.save, 1, .command),
        ]
        for (kind, code, modifiers) in expected {
            #expect(kind.fixedShortcut == KeyboardShortcut(keyCode: code, modifiers: modifiers))
        }
    }

    @Test func appsUsesTheVerifiedSystemBundleWithoutLaunchingIt() {
        let action = WorkspaceAction.openApps
        #expect(action.isSupported)
        #expect(
            WorkspacePreparation.prepare(action)
                == .application(
                    ApplicationTarget(
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
        let result = CoreAudioInput.toggleMute(
            device: 71, canPerform: { true }, defaultDevice: { 71 },
            read: { _ in muted },
            write: { device, value in
                #expect(device == 71)
                writes.append(value)
                return true
            })
        #expect(result == .performed)
        #expect(writes == [!muted])
    }

    @Test func replacedOrCancelledMicrophoneNeverReceivesTheQueuedWrite() {
        var current: UInt32 = 71
        var writes = 0
        let replaced = CoreAudioInput.toggleMute(
            device: 71, canPerform: { true }, defaultDevice: { current },
            read: { _ in
                current = 72
                return false
            },
            write: { _, _ in
                writes += 1
                return true
            })
        #expect(replaced == .unavailable)
        var allowed = true
        let cancelled = CoreAudioInput.toggleMute(
            device: 71, canPerform: { allowed }, defaultDevice: { 71 },
            read: { _ in
                allowed = false
                return false
            },
            write: { _, _ in
                writes += 1
                return true
            })
        #expect(cancelled == .cancelled)
        #expect(writes == 0)
    }

    @Test func mouseRuleQueuesTheDefaultMicrophoneRatherThanTheOutput() throws {
        let caps = AudioOutputCapabilities(deviceID: 5, volume: true, mute: true, inputDeviceID: 71, microphoneMute: true)
        let mailbox = EngineMailbox()
        mailbox.updateAudioCapabilities(caps)
        mailbox.configure(
            Configuration(
                isEnabled: true,
                bindings: [
                    .init(
                        scope: .allMice, trigger: .mouseButton(3),
                        modifiers: [], action: .system(.toggleMicrophoneMute))
                ]))
        mailbox.state.withLock { $0.status = .active }
        let devices = Mutex<[UInt32]>([])
        let worker = ActionWorker(
            mailbox: mailbox, capabilities: { caps },
            performAudio: { action, device, canPerform in
                #expect(action == .toggleMicrophoneMute && canPerform())
                devices.withLock { $0.append(device) }
                return .performed
            }, secureInput: { false }, postingAllowed: { true })
        #expect(mailbox.handle(InputEvent(trigger: .mouseButton(3), phase: .down), secureInput: false))
        worker.service(at: 0)
        #expect(devices.withLock { $0 } == [71])
    }

    @Test(arguments: [
        RebindAction.system(.toggleMicrophoneMute), .media(.fastForward), .media(.rewind),
        .workspace(.openApps), .windowLayout(.fillWithStageManager),
    ])
    func newPayloadsRoundTripAndCannotBeSmuggledIntoSchema44(_ action: RebindAction) throws {
        let binding = rebind.Binding(scope: .allMice, trigger: .mouseButton(3), modifiers: [], action: action)
        let config = Configuration(bindings: [binding])
        #expect(try JSONDecoder().decode(Configuration.self, from: JSONEncoder().encode(config)) == config)
        var old = Configuration(schemaVersion: 44)
        old.profiles.append(RuleProfile(name: "Inactive", bindings: [binding]))
        #expect(throws: ConfigurationError.invalid) { try old.migrated() }
        #expect(try Configuration(schemaVersion: 44).migrated().schemaVersion == Configuration.currentSchemaVersion)
    }
}

struct LeftInsetFillTests {
    let display = WindowDisplay(
        frame: CGRect(x: 0, y: 0, width: 2560, height: 1440),
        visibleFrame: CGRect(x: 0, y: 30, width: 2560, height: 1329))
    let window = CGRect(x: 200, y: 100, width: 800, height: 600)

    @Test func fillNeedsOnlyDisplayGeometryEvenWithoutStageManagerMetadata() throws {
        let target = try #require(WindowLayoutGeometry.target(.fillWithStageManager, window: window, displays: [display]))
        #expect(target.minX == 244)
        #expect(target.minY == display.visibleFrame.minY && target.maxY == display.visibleFrame.maxY)
        #expect(target.maxX == display.visibleFrame.maxX)
        #expect(WindowLayoutGeometry.target(.fill, window: window, displays: [display]) == display.visibleFrame)
        #expect(WindowLayoutGeometry.target(.fillWithStageManager, window: target, displays: [display]) == target)
    }

    @Test func selectedDisplayAndDockExclusionsAreRespectedWithoutDoubleInset() throws {
        let external = WindowDisplay(
            frame: CGRect(x: -1920, y: -200, width: 1920, height: 1080),
            visibleFrame: CGRect(x: -1820, y: -170, width: 1720, height: 1050))
        let target = try #require(
            WindowLayoutGeometry.target(
                .fillWithStageManager,
                window: CGRect(x: -1600, y: 0, width: 800, height: 600), displays: [display, external]))
        #expect(target.minX == -1737)
        #expect(target.maxX == external.visibleFrame.maxX)
        #expect(target.minY == external.visibleFrame.minY && target.maxY == external.visibleFrame.maxY)
    }

    @Test func unsafeNarrowAreaAndFullScreenRemainUnavailable() {
        let narrow = WindowDisplay(
            frame: CGRect(x: 0, y: 0, width: 400, height: 800),
            visibleFrame: CGRect(x: 0, y: 30, width: 60, height: 770))
        #expect(
            WindowLayoutGeometry.target(
                .fillWithStageManager,
                window: CGRect(x: 20, y: 50, width: 300, height: 500), displays: [narrow]) == nil)
        #expect(WindowLayoutGeometry.target(.fillWithStageManager, window: display.frame, displays: [display]) == nil)
    }
}

struct CenteredFillTests {
    private let window = CGRect(x: 300, y: 100, width: 800, height: 600)

    @Test(arguments: [CGFloat(0), 100, 300], [false, true])
    func equalDisplayMarginsRespectEitherSideDock(_ dockWidth: CGFloat, _ dockOnRight: Bool) throws {
        let frame = CGRect(x: -2560, y: -200, width: 2560, height: 1440)
        let display = WindowDisplay(
            frame: frame,
            visibleFrame: CGRect(x: frame.minX + (dockOnRight ? 0 : dockWidth), y: -170, width: 2560 - dockWidth, height: 1329))
        let original = CGRect(x: -1800, y: 0, width: 800, height: 600)
        let target = try #require(WindowLayoutGeometry.target(.fillCentered, window: original, displays: [display]))
        let margin = max(244, dockWidth)
        #expect(target.minX - frame.minX == margin)
        #expect(frame.maxX - target.maxX == margin)
        #expect(target.minY == display.visibleFrame.minY && target.maxY == display.visibleFrame.maxY)
        #expect(display.visibleFrame.contains(target))
        #expect(WindowLayoutGeometry.target(.fillCentered, window: target, displays: [display]) == target)
        let left = try #require(WindowLayoutGeometry.target(.fillWithStageManager, window: original, displays: [display]))
        #expect(left.minX == target.minX || dockOnRight)
        #expect(left.maxX == display.visibleFrame.maxX)
    }

    @Test func fillsHeightAndWidthWithoutChangingOrdinaryFillOrCenter() throws {
        let display = WindowDisplay(
            frame: CGRect(x: 0, y: 0, width: 2560, height: 1440),
            visibleFrame: CGRect(x: 0, y: 30, width: 2560, height: 1329))
        let target = try #require(WindowLayoutGeometry.target(.fillCentered, window: window, displays: [display]))
        #expect(target == CGRect(x: 244, y: 30, width: 2072, height: 1329))
        #expect(WindowLayoutGeometry.target(.fill, window: window, displays: [display]) == display.visibleFrame)
        let centered = try #require(WindowLayoutGeometry.target(.center, window: window, displays: [display]))
        #expect(centered.size == window.size)
        #expect(centered.midX == display.visibleFrame.midX && centered.midY == display.visibleFrame.midY)
        #expect(WindowLayoutGeometry.target(.fillCentered, window: display.frame, displays: [display]) == nil)
    }

    @Test(arguments: [CGFloat(0), 499, 500, 501])
    func sideDockMustLeavePositiveCenteredWidth(_ dockWidth: CGFloat) {
        let display = WindowDisplay(
            frame: CGRect(x: 0, y: 0, width: 1000, height: 800),
            visibleFrame: CGRect(x: dockWidth, y: 30, width: 1000 - dockWidth, height: 770))
        let target = WindowLayoutGeometry.target(.fillCentered, window: CGRect(x: 10, y: 50, width: 100, height: 200), displays: [display])
        #expect((target == nil) == (dockWidth >= 500))
    }

    @Test(arguments: [(CGFloat(1440), CGFloat(137)), (1920, 183), (2560, 244), (3840, 366), (5120, 488)])
    func bothLayoutsUseTheSelectedDisplaysCalibratedProportion(_ width: CGFloat, _ margin: CGFloat) throws {
        let display = WindowDisplay(
            frame: CGRect(x: -width, y: 0, width: width, height: 1080),
            visibleFrame: CGRect(x: -width, y: 30, width: width, height: 1000))
        let primary = WindowDisplay(
            frame: CGRect(x: 0, y: 0, width: 2560, height: 1440),
            visibleFrame: CGRect(x: 0, y: 30, width: 2560, height: 1329))
        let original = CGRect(x: -width + 100, y: 100, width: 800, height: 600)
        let left = try #require(WindowLayoutGeometry.target(.fillWithStageManager, window: original, displays: [primary, display]))
        let center = try #require(WindowLayoutGeometry.target(.fillCentered, window: original, displays: [primary, display]))
        #expect(left.minX - display.frame.minX == margin)
        #expect(center.minX == left.minX)
        #expect(display.frame.maxX - center.maxX == margin)
        #expect(left.maxX == display.visibleFrame.maxX)
        #expect(WindowLayoutGeometry.target(.fillCentered, window: center, displays: [primary, display]) == center)
    }

    @Test func schema49PreservesExistingLeftMarginButRejectsNewPayloadInInactiveProfile() throws {
        let binding = rebind.Binding(scope: .allMice, trigger: .mouseButton(3), modifiers: [], action: .windowLayout(.fillWithStageManager))
        var previous = Configuration(schemaVersion: 49, bindings: [binding])
        #expect(try previous.migrated().bindings == [binding])
        previous.profiles.append(
            RuleProfile(
                name: "Other",
                bindings: [
                    rebind.Binding(scope: .allMice, trigger: .mouseButton(4), modifiers: [], action: .windowLayout(.fillCentered))
                ]))
        let decoded = try JSONDecoder().decode(Configuration.self, from: JSONEncoder().encode(previous))
        #expect(throws: ConfigurationError.invalid) { try decoded.migrated() }
        previous.schemaVersion = Configuration.currentSchemaVersion
        #expect(try JSONDecoder().decode(Configuration.self, from: JSONEncoder().encode(previous)).migrated() == previous)
    }
}
