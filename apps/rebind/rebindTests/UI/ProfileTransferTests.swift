import Foundation
import Testing
@testable import rebind

@MainActor struct ProfileTransferTests {
    private func binding(_ button: UInt32) -> rebind.Binding {
        rebind.Binding(scope: .allMice, trigger: .mouseButton(button), modifiers: [],
                       action: .shortcut(KeyboardShortcut(keyCode: 0, modifiers: .command)))
    }

    private func store() -> ConfigurationStore {
        ConfigurationStore(url: FileManager.default.temporaryDirectory
            .appending(path: "RebindTransfer-\(UUID())").appending(path: "config.json"))
    }

    @Test func anExportedProfileCarriesOnlyThatProfileAndNoAppPreferences() throws {
        var configuration = Configuration(isEnabled: true, bindings: [binding(3)])
        try configuration.createProfile(name: "Work")
        configuration.bindings = [binding(4)]
        configuration.excludedApplications = [ExcludedApplication(target: ApplicationTarget(
            url: URL(filePath: "/Applications/Game.app"), bundleIdentifier: "com.example.game"))]
        configuration.reversesMouseWheel = true
        let work = configuration.selectedProfileID
        let exported = try configuration.exportingProfile(work)
        #expect(exported.profiles.map(\.name) == ["Work"] && exported.bindings == configuration.bindings)
        #expect(exported.excludedApplications.isEmpty && !exported.reversesMouseWheel && !exported.isEnabled)
        #expect(throws: ConfigurationError.profileInvalid) { try configuration.exportingProfile(UUID()) }
        let data = try ConfigurationBackup(configuration: exported).encoded()
        #expect(try ConfigurationBackup(data: data).configuration == exported)
    }

    @Test func importingAddsProfilesWithFreshIdentifiersAndUnusedNamesWithoutReplacingAnything() throws {
        let store = store()
        defer { try? FileManager.default.removeItem(at: store.url.deletingLastPathComponent()) }
        var original = Configuration(isEnabled: true, bindings: [binding(3)])
        try original.createProfile(name: "Work")
        try original.selectProfile(RuleProfile.defaultID)
        try store.save(original)
        let model = AppModel(store: store)
        var file = Configuration(bindings: [binding(5)])
        try file.createProfile(name: "work")
        file.bindings = [binding(6)]
        let backup = try ConfigurationBackup(configuration: file)
        #expect(model.importProfiles(from: backup) == 2)
        let profiles = model.configuration.profiles
        #expect(profiles.count == 4 && Array(profiles.prefix(2)) == original.profiles)
        #expect(Set(profiles.map(\.title)).count == 4 && profiles[3].title == "work 2")
        // Default has one rule, Work none, and the two imported profiles one each.
        #expect(Set(profiles.flatMap(\.bindings).map(\.id)).count == 3)
        #expect(model.configuration.selectedProfileID == RuleProfile.defaultID && model.configuration.isEnabled)
        #expect(try store.load() == model.configuration)
    }

    @Test func anImportThatWouldExceedTheProfileLimitChangesNothing() throws {
        let store = store()
        defer { try? FileManager.default.removeItem(at: store.url.deletingLastPathComponent()) }
        var full = Configuration()
        for index in 1..<Configuration.maximumProfiles { try full.createProfile(name: "P\(index)") }
        try store.save(full)
        let model = AppModel(store: store)
        #expect(model.importProfiles(from: try ConfigurationBackup(configuration: Configuration())) == nil)
        #expect(model.configuration == full)
    }
}
