import Foundation
import Testing
@testable import rebind

@MainActor struct ReleaseUpdateTests {
    @Test(arguments: [("1.0", "v1.0.0"), ("2", "2.0.0"), ("1.2", "1.2.0")])
    func equivalentVersions(pair: (String, String)) {
        #expect(ReleaseVersion(pair.0) == ReleaseVersion(pair.1))
    }

    @Test(arguments: [("1.9", "1.10"), ("1.0.9", "1.1"), ("1.9.9", "2"), ("1.0", "v1.0.1")])
    func numericVersionOrdering(pair: (String, String)) throws {
        #expect(try #require(ReleaseVersion(pair.0)) < #require(ReleaseVersion(pair.1)))
    }

    @Test(arguments: ["", "v", "1..0", "1.0.0.1", "1.0-beta", " 1.0", "-1.0", "1.a", "１.０", "999999999999999999999999999999"])
    func invalidVersionsAreNotUpdates(value: String) {
        #expect(ReleaseVersion(value) == nil)
    }

    @Test func responseOutcomesDoNotConfuseNoReleaseOrErrorsWithCurrentVersion() throws {
        #expect(try ReleaseUpdate.interpret(data: Data(), status: 404, currentVersion: "1.0") == .noRelease)
        #expect(try ReleaseUpdate.interpret(data: payload("v1.0.0"), status: 200, currentVersion: "1.0") == .current)
        #expect(try ReleaseUpdate.interpret(data: payload("v0.9"), status: 200, currentVersion: "1.0") == .current)
        #expect(try ReleaseUpdate.interpret(data: payload("v1.0.1"), status: 200, currentVersion: "1.0") == .available(version: "v1.0.1"))
        for status in [401, 403, 429, 500] {
            #expect(throws: (any Error).self) { try ReleaseUpdate.interpret(data: Data(), status: status, currentVersion: "1.0") }
        }
        for data in [Data(), payload("v1.1", draft: true), payload("v1.1", prerelease: true), payload("unexpected"), Data(repeating: 32, count: 1_000_001)] {
            #expect(throws: (any Error).self) { try ReleaseUpdate.interpret(data: data, status: 200, currentVersion: "1.0") }
        }
    }

    @Test func everyUpdateMessageExistsInEverySupportedLanguage() {
        let keys = ["checkForUpdates", "checkingUpdates", "updateAvailableTitle", "updateAvailableMessage %@ %@", "updateCurrentTitle",
                    "updateCurrentMessage %@", "updateNoReleaseTitle", "updateNoReleaseMessage", "updateCheckFailedTitle",
                    "updateCheckFailedMessage", "updateOpenRelease"]
        for language in AppLanguage.allCases {
            for key in keys {
                let value = AppLocalization.string(LocalizedStringResource(String.LocalizationValue(key)), language: language)
                #expect(value != key)
            }
        }
    }

    private func payload(_ tag: String, draft: Bool = false, prerelease: Bool = false) -> Data {
        Data("{\"tag_name\":\"\(tag)\",\"draft\":\(draft),\"prerelease\":\(prerelease)}".utf8)
    }
}
