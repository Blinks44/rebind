import Foundation
import Testing
@testable import rebind

@MainActor struct InputHoldSettingsTests {
    @Test(arguments: [UInt32(100), 575, 5000])
    func changedDurationRetainsOtherRulesAndFailedDraftCanRetry(_ duration: UInt32) throws {
        let store = ConfigurationStore(url: FileManager.default.temporaryDirectory
            .appending(path: "RebindHoldUI-\(UUID())/configuration.json"))
        defer { try? FileManager.default.removeItem(at: store.url.deletingLastPathComponent()) }
        let binding = rebind.Binding(scope: .allMice, trigger: .mouseButton(99), modifiers: [],
            action: .shortcut(KeyboardShortcut(keyCode: 0, modifiers: .command)), activation: .hold)
        var configuration = Configuration(bindings: [binding])
        configuration.languagePreference = .fr
        try configuration.createProfile(name: "Untouched", copying: configuration.selectedProfileID)
        try configuration.selectProfile(RuleProfile.defaultID)
        try store.save(configuration)
        let model = AppModel(store: store)
        var draft = binding
        draft.holdDurationMilliseconds = duration
        let bytes = try Data(contentsOf: store.url)
        try FileManager.default.removeItem(at: store.url)
        try FileManager.default.createDirectory(at: store.url, withIntermediateDirectories: false)
        #expect(!model.saveBinding(draft, profileID: configuration.selectedProfileID))
        #expect(model.configuration == configuration && draft.holdDurationMilliseconds == duration)
        #expect(model.error == .storageWriteFailed)
        try FileManager.default.removeItem(at: store.url)
        try bytes.write(to: store.url)
        #expect(model.saveBinding(draft, profileID: configuration.selectedProfileID))
        var expected = configuration
        expected.bindings = [draft]
        #expect(model.configuration == expected)
        #expect(try store.load() == expected)
    }
}
