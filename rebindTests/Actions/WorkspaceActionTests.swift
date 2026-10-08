import Foundation
import Testing
@testable import rebind

struct WorkspaceActionTests {
    @Test(arguments: ["https://example.com/a?q=1#part", "http://localhost:8080/", "HTTPS://example.com", "  https://example.com  "])
    func acceptsExplicitWebAddresses(_ address: String) {
        #expect(WorkspaceAction.webURL(address) != nil)
    }

    @Test(arguments: ["", "example.com", "https:///", "file:///tmp/a", "javascript:alert(1)", "shortcuts://run-shortcut?name=X", "https://user:secret@example.com", "https://example.com/\na", "https://example.com/a b", String(repeating: "a", count: 8193)])
    func rejectsIncompleteOrUnsupportedWebAddresses(_ address: String) {
        #expect(WorkspaceAction.webURL(address) == nil)
    }

    @Test(arguments: ["/", "/tmp/a\n.txt", "/Applications/Example.app"])
    func rejectsInvalidDocumentTargets(_ path: String) {
        #expect(WorkspaceAction.openFile(URL(filePath: path)).isSupported == false)
    }

    @Test func catalogRequiresTheSelectedParameterAndRejectsSelf() throws {
        let application = ApplicationTarget(url: URL(filePath: "/Applications/Example.app"), bundleIdentifier: "org.example.app")
        let file = URL(filePath: "/tmp/My Document.txt")
        let url = try #require(WorkspaceAction.webURL("https://example.com"))
        #expect(ActionKind.openApplication.configuredAction(shortcut: nil) == nil)
        #expect(ActionKind.activateApplication.configuredAction(shortcut: nil) == nil)
        #expect(ActionKind.openURL.configuredAction(shortcut: nil) == nil)
        #expect(ActionKind.openFile.configuredAction(shortcut: nil) == nil)
        #expect(ActionKind.openApplication.configuredAction(shortcut: nil, application: application) == .workspace(.openApplication(application)))
        #expect(ActionKind.activateApplication.configuredAction(shortcut: nil, application: application) == .workspace(.activateApplication(application)))
        #expect(ActionKind.openURL.configuredAction(shortcut: nil, webAddress: "https://example.com") == .workspace(.openURL(url)))
        #expect(ActionKind.openFile.configuredAction(shortcut: nil, file: file) == .workspace(.openFile(file)))
        var invalid = application
        invalid.bundleIdentifier = "blinks44.rebind"
        #expect(invalid.isSupported == false)
        invalid.bundleIdentifier = "contains whitespace"
        #expect(invalid.isSupported == false)
        let remote = try #require(URL(string: "file://remote-host/tmp/a"))
        #expect(WorkspaceAction.openFile(remote).isSupported == false)
    }

    @Test func activationMatchesTheChosenCopyAcrossDirectoryURLRepresentations() {
        let selected = ApplicationTarget(url: URL(filePath: "/Applications/Example.app", directoryHint: .isDirectory), bundleIdentifier: "org.example.app")
        #expect(selected.matchesRunningApplication(bundleIdentifier: "org.example.app", url: URL(filePath: "/Applications/Example.app", directoryHint: .notDirectory)))
        #expect(selected.matchesRunningApplication(bundleIdentifier: "org.example.app", url: URL(filePath: "/Users/example/Applications/Example.app")) == false)
        #expect(selected.matchesRunningApplication(bundleIdentifier: "org.example.other", url: selected.url) == false)
        #expect(selected.matchesRunningApplication(bundleIdentifier: "org.example.app", url: nil) == false)
    }

    @Test(arguments: 0...3, [InputTrigger.key(0), .mouseButton(99), .scroll(.up)])
    func everyWorkspaceActionMatchesWithoutAudioAndRoundTrips(_ index: Int, _ trigger: InputTrigger) throws {
        let action = try action(index)
        let binding = rebind.Binding(scope: trigger.scope, trigger: trigger, modifiers: [], action: .workspace(action))
        let configuration = Configuration(isEnabled: true, bindings: [binding])
        let data = try JSONEncoder().encode(configuration)
        #expect(try JSONDecoder().decode(Configuration.self, from: data).migrated() == configuration)
        let kind = ActionKind(action: binding.action)
        #expect(kind.category == .windows && kind.needsWorkspaceParameters)
        #expect(kind.isAvailable(with: AudioOutputCapabilities()))
        let mailbox = EngineMailbox()
        mailbox.configure(configuration)
        mailbox.state.withLock { $0.status = .active }
        #expect(mailbox.handle(InputEvent(trigger: trigger, phase: trigger.isScroll ? .scroll : .down), secureInput: false))
        #expect(mailbox.nextAction()?.action == binding.action)
    }

    @Test func metadataPreparationChecksAppIdentityAndMissingFilesWithoutOpeningThem() throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: "RebindWorkspace-\(UUID())", directoryHint: .isDirectory)
        defer { try? FileManager.default.removeItem(at: folder) }
        let app = folder.appending(path: "Example.app", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: app.appending(path: "Contents"), withIntermediateDirectories: true)
        let metadata = ["CFBundleIdentifier": "org.example.fixture", "CFBundlePackageType": "APPL", "CFBundleName": "Example"]
        let plist = try PropertyListSerialization.data(fromPropertyList: metadata, format: .xml, options: 0)
        try plist.write(to: app.appending(path: "Contents/Info.plist"))
        let target = ApplicationTarget(url: app, bundleIdentifier: "org.example.fixture")
        #expect(WorkspacePreparation.prepare(.openApplication(target)) == .application(target, activateOnly: false))
        #expect(WorkspacePreparation.prepare(.activateApplication(target)) == .application(target, activateOnly: true))
        var wrong = target
        wrong.bundleIdentifier = "org.example.other"
        #expect(WorkspacePreparation.prepare(.openApplication(wrong)) == nil)
        let file = folder.appending(path: "document.txt")
        #expect(WorkspacePreparation.prepare(.openFile(file)) == nil)
        try Data("fixture".utf8).write(to: file)
        #expect(WorkspacePreparation.prepare(.openFile(file)) == .document(file))
        #expect(WorkspacePreparation.prepare(.openFile(folder)) == .document(folder))
        let alias = folder.appending(path: "alias")
        try FileManager.default.createSymbolicLink(at: alias, withDestinationURL: app)
        #expect(WorkspacePreparation.prepare(.openFile(alias)) == nil)
    }

    @Test func schemaEightProfilesWindowAndAudioActionsMigrateWithoutRewriting() throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: "RebindWorkspaceStore-\(UUID())")
        defer { try? FileManager.default.removeItem(at: folder) }
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let store = ConfigurationStore(url: folder.appending(path: "config.json"))
        let bindings = [
            rebind.Binding(scope: .allMice, trigger: .mouseButton(3), modifiers: [], action: .window(.close)),
            rebind.Binding(scope: .allMice, trigger: .mouseButton(4), modifiers: [], action: .system(.volumeDown))
        ]
        var original = Configuration(isEnabled: true, bindings: bindings)
        try original.createProfile(name: "Second", copying: RuleProfile.defaultID)
        original.schemaVersion = 8
        let bytes = try JSONEncoder().encode(original)
        try bytes.write(to: store.url)
        var migrated = try store.load()
        #expect(migrated.schemaVersion == Configuration.currentSchemaVersion)
        #expect(migrated.profiles == original.profiles && migrated.selectedProfileID == original.selectedProfileID && migrated.isEnabled)
        #expect(try Data(contentsOf: store.url) == bytes)
        migrated.bindings[0].action = .workspace(try action(0))
        try store.save(migrated)
        #expect(try store.load() == migrated)
    }

    @Test(arguments: 1...8)
    func workspaceActionsCannotMasqueradeAsOlderSchemas(_ version: Int) throws {
        let binding = rebind.Binding(scope: .allMice, trigger: .mouseButton(3), modifiers: [], action: .workspace(try action(2)))
        let bytes = try JSONEncoder().encode(Configuration(schemaVersion: version, bindings: [binding]))
        let decoded = try JSONDecoder().decode(Configuration.self, from: bytes)
        #expect(throws: ConfigurationError.invalid) { try decoded.migrated() }
    }

    @Test func invalidOrUnknownWorkspaceActionsAreNotPersisted() throws {
        let invalid = RebindAction.workspace(.openFile(URL(filePath: "/Applications/Example.app")))
        let binding = rebind.Binding(scope: .allMice, trigger: .mouseButton(3), modifiers: [], action: invalid)
        #expect(binding.isValid == false)
        #expect(throws: ConfigurationError.invalid) { try Configuration(bindings: [binding]).validate() }
        let valid = rebind.Binding(scope: .allMice, trigger: .mouseButton(3), modifiers: [], action: .workspace(try action(2)))
        let bytes = try JSONEncoder().encode(Configuration(bindings: [valid]))
        let unknown = Data(String(decoding: bytes, as: UTF8.self).replacingOccurrences(of: "openURL", with: "executeArbitraryCode").utf8)
        #expect(throws: (any Error).self) { try JSONDecoder().decode(Configuration.self, from: unknown) }
    }

    @Test func oversizedTargetConfigurationsCannotMakeTheStoreUnreadable() throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: "RebindWorkspaceSize-\(UUID())")
        defer { try? FileManager.default.removeItem(at: folder) }
        let store = ConfigurationStore(url: folder.appending(path: "config.json"))
        let original = Configuration()
        try store.save(original)
        let bytes = try Data(contentsOf: store.url)
        let url = try #require(WorkspaceAction.webURL("https://example.com/" + String(repeating: "a", count: 4096)))
        let bindings = (3..<703).map { index in
            rebind.Binding(scope: .allMice, trigger: .mouseButton(UInt32(index)), modifiers: [], action: .workspace(.openURL(url)))
        }
        let large = Configuration(bindings: bindings)
        try large.validate()
        #expect(throws: ConfigurationError.invalid) { try store.save(large) }
        #expect(try Data(contentsOf: store.url) == bytes)
        #expect(try store.load() == original)
    }

    private func action(_ index: Int) throws -> WorkspaceAction {
        let app = ApplicationTarget(url: URL(filePath: "/Applications/Example.app"), bundleIdentifier: "org.example.app")
        switch index {
        case 0: return .openApplication(app)
        case 1: return .activateApplication(app)
        case 2: return .openURL(try #require(WorkspaceAction.webURL("https://example.com")))
        default: return .openFile(URL(filePath: "/tmp/document.txt"))
        }
    }
}
