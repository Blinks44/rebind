import Foundation
import Testing

@testable import rebind

@MainActor struct StarterSetupTests {
    private func store() -> ConfigurationStore {
        ConfigurationStore(url: FileManager.default.temporaryDirectory.appending(path: "StarterSetup-\(UUID())/config.json"))
    }
    private func review(
        _ setup: StarterSetup = .windows, in configuration: Configuration = Configuration(), existing: Bool = false,
        selected: Set<String>? = nil, safari: ApplicationTarget? = nil
    ) -> StarterSetupReview {
        StarterSetupReview(
            setup: setup, selectedIDs: selected ?? Set(setup.entries(safari: safari).map(\.id)),
            destinationID: existing ? configuration.selectedProfileID : nil, configuration: configuration, safari: safari)
    }

    @Test(arguments: StarterSetup.allCases)
    func catalogContainsSmallValidIndependentSets(_ setup: StarterSetup) throws {
        let entries = setup.entries(safari: nil)
        #expect(entries.count == 3 && Set(entries.map(\.id)).count == 3)
        try Configuration(bindings: entries.map(\.binding)).validate()
        #expect(entries.allSatisfy { $0.binding.isEnabled && $0.binding.activation == .press && !$0.binding.holdsOutput })
        if setup == .browser {
            #expect(entries.allSatisfy { $0.binding.application?.bundleIdentifier == "com.apple.Safari" })
            #expect(entries.map(\.binding.trigger) == [.mouseButton(3), .mouseButton(4), .mouseButton(2)])
        } else {
            #expect(entries.allSatisfy { $0.binding.application == nil })
        }
    }

    @Test func subsetAddsFreshRulesAndPreservesSelectionAndPreferences() throws {
        var original = Configuration(isEnabled: true)
        original.reversesMouseWheel = true
        original.languagePreference = .ru
        original.showsDockIcon = false
        let entry = try #require(StarterSetup.windows.entries(safari: nil).first)
        let draft = review(in: original, selected: [entry.id])
        let installation = try draft.installing(name: "Windows")
        var expected = original
        expected.profiles.append(try #require(installation.configuration.profiles.last))
        #expect(installation.configuration == expected)
        #expect(installation.result.addedCount == 1 && installation.result.createdProfile)
        #expect(installation.configuration.selectedProfileID == original.selectedProfileID)
        let installed = try #require(installation.configuration.profiles.last?.bindings.first)
        #expect(installed.id != draft.additions.first?.id)
        #expect(installed.action == .windowLayout(.leftHalf))
    }

    @Test func repeatInstallationSkipsDuplicatesAndNeverCreatesEmptyProfiles() throws {
        let first = try review().installing(name: "Windows")
        var configuration = first.configuration
        try configuration.selectProfile(first.result.profileID)
        let again = review(in: configuration, existing: true)
        #expect(again.rows.allSatisfy { $0.availability == .alreadyAdded })
        #expect(again.additions.isEmpty && again.skippedCount == 3)
        #expect(throws: ConfigurationError.invalid) { try again.installing(name: "Unused") }
        #expect(throws: ConfigurationError.invalid) { try review(selected: []).installing(name: "Empty") }
        #expect(throws: ConfigurationError.invalid) { try review(selected: ["windows.left", "unknown"]).installing(name: "Invalid") }
    }

    @Test func disabledDuplicateAndEditedConflictStayUntouchedWhileOtherRulesAreAdded() throws {
        var rules = StarterSetup.windows.entries(safari: nil).map(\.binding)
        rules[0].isEnabled = false
        rules[0].note = "Keep my label"
        rules[1].action = .dock(.missionControl)
        let original = Configuration(bindings: Array(rules.prefix(2)))
        let draft = review(in: original, existing: true)
        #expect(draft.rows[0].availability == .alreadyAdded)
        #expect(draft.rows[1].availability == .conflict(rules[1]))
        #expect(draft.additions.count == 1)
        let added = try draft.installing(name: "Ignored")
        #expect(Array(added.configuration.bindings.prefix(2)) == original.bindings)
        #expect(added.configuration.profiles.count == 1 && !added.result.createdProfile)
        #expect(added.configuration.bindings.last?.action == .windowLayout(.fill))
    }

    @Test func overlappingAppScopesAreExplicitConflictsButOtherAppsRemainIndependent() {
        let safari = ApplicationTarget(url: URL(filePath: "/Applications/Safari.app"), bundleIdentifier: "com.apple.Safari")
        var rule = StarterSetup.browser.entries(safari: safari)[0].binding
        rule.application = nil
        #expect(review(.browser, in: Configuration(bindings: [rule]), existing: true, safari: safari).additions.count == 2)
        rule.application = ApplicationTarget(url: URL(filePath: "/Applications/Other.app"), bundleIdentifier: "com.example.other")
        #expect(review(.browser, in: Configuration(bindings: [rule]), existing: true, safari: safari).additions.count == 3)
    }

    @Test func missingTargetNeverBecomesAnUnrestrictedRule() throws {
        let missing = review(.browser)
        #expect(missing.rows.allSatisfy { $0.availability == .missingApplication })
        #expect(missing.additions.isEmpty)
        #expect(throws: ConfigurationError.invalid) { try missing.installing(name: "Browser") }
    }

    @Test func installationHonorsProfileAndRuleLimitsAndNameValidation() throws {
        var full = Configuration()
        for index in 1..<Configuration.maximumProfiles { try full.createProfile(name: "P\(index)") }
        #expect(throws: ConfigurationError.profileLimit) { try review(in: full).installing(name: "Extra") }
        #expect(try review(in: full, existing: true).installing(name: "Ignored").configuration.profiles.count == 20)
        #expect(throws: ConfigurationError.profileInvalid) { try review().installing(name: String(repeating: "x", count: 81)) }
        let many = (0..<1000).map { index in
            rebind.Binding(scope: .allMice, trigger: .mouseButton(UInt32(index + 10)), modifiers: [], action: .doNothing)
        }
        #expect(throws: ConfigurationError.invalid) { try review(in: Configuration(bindings: many)).installing(name: "Too many") }
    }

    @Test func successfulNewProfileSaveDoesNotReconfigureOrQueueActions() throws {
        let store = store()
        defer { try? FileManager.default.removeItem(at: store.url.deletingLastPathComponent()) }
        let original = Configuration(isEnabled: true)
        try store.save(original)
        let model = AppModel(store: store)
        model.mailbox.configure(original)
        model.beginEditing()
        let installed = try #require(model.installStarterSetup(review(in: original), name: "Windows", expectedRevision: 0))
        #expect(installed.addedCount == 3)
        #expect(model.configuration.selectedProfileID == original.selectedProfileID)
        #expect(model.mailbox.state.withLock { $0.pending.isEmpty && $0.profileID == original.selectedProfileID })
        #expect(try store.load() == model.configuration)
        let backup = try ConfigurationBackup(configuration: model.configuration.exportingProfile(installed.profileID))
        #expect(model.importProfiles(from: backup) == 1)
        #expect(model.configuration.selectedProfileID == original.selectedProfileID)
    }

    @Test func failedSaveRollsBackMemoryDiskAndQueuedOutput() throws {
        let store = store()
        defer { try? FileManager.default.removeItem(at: store.url.deletingLastPathComponent()) }
        let original = Configuration(isEnabled: true)
        try store.save(original)
        let model = AppModel(store: store)
        model.mailbox.configure(original)
        model.mailbox.state.withLock { $0.pending = [.dock(.missionControl)] }
        try FileManager.default.removeItem(at: store.url)
        try FileManager.default.createDirectory(at: store.url, withIntermediateDirectories: false)
        #expect(model.installStarterSetup(review(in: original), name: "Windows", expectedRevision: 0) == nil)
        #expect(model.configuration == original)
        #expect(model.mailbox.state.withLock { $0.pending == [.dock(.missionControl)] })
        #expect(try store.url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory == true)
    }

    @Test func currentProfileInstallationDoesNotDispatchAndRechecksMissingApplications() throws {
        let store = store()
        defer { try? FileManager.default.removeItem(at: store.url.deletingLastPathComponent()) }
        let original = Configuration(isEnabled: true)
        try store.save(original)
        let model = AppModel(store: store)
        model.mailbox.configure(original)
        model.beginEditing()
        let installed = try #require(model.installStarterSetup(review(in: original, existing: true), name: "Ignored", expectedRevision: 0))
        #expect(installed.profileID == original.selectedProfileID)
        #expect(model.configuration.bindings.count == 3 && model.configuration.isEnabled)
        #expect(model.mailbox.state.withLock { $0.pending.isEmpty })
        let unavailable = ApplicationTarget(
            url: store.url.deletingLastPathComponent().appending(path: "Missing.app"), bundleIdentifier: "com.apple.Safari")
        let current = model.configuration
        let browser = review(.browser, in: current, safari: unavailable)
        #expect(browser.additions.count == 3)
        #expect(model.installStarterSetup(browser, name: "Browser", expectedRevision: 0) == nil)
        #expect(model.configuration == current)
        #expect(try store.load() == current)
    }

    @Test func staleReviewAndCorruptStorageCannotInstall() throws {
        let store = store()
        defer { try? FileManager.default.removeItem(at: store.url.deletingLastPathComponent()) }
        try store.save(Configuration())
        let model = AppModel(store: store)
        let draft = review(in: model.configuration)
        #expect(model.createProfile(name: "Other"))
        let current = model.configuration
        #expect(model.installStarterSetup(draft, name: "Windows", expectedRevision: 0) == nil)
        #expect(model.configuration == current)
        #expect(model.installStarterSetup(review(in: current), name: "Windows", expectedRevision: 1) == nil)
        let bytes = Data("broken".utf8)
        try bytes.write(to: store.url)
        #expect(model.installStarterSetup(review(in: current), name: "Windows", expectedRevision: 0) == nil)
        #expect(model.configuration == current && model.storageLocked)
        #expect(try Data(contentsOf: store.url) == bytes)
    }
}
