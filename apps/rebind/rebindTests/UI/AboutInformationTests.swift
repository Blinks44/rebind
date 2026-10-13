import Foundation
import Testing
@testable import rebind

@MainActor struct AboutInformationTests {
    @Test func shippedIdentityAndCompleteNoticesAreAvailable() throws {
        let information = AboutInformation()
        #expect(information.version == Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String)
        #expect(information.build == Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String)
        #expect(information.version != nil)
        #expect(information.build != nil)
        let resource = try #require(Bundle.main.url(forResource: "ThirdPartyNotices", withExtension: "txt"))
        #expect(information.notices == (try String(contentsOf: resource, encoding: .utf8)))
        let notices = try #require(information.notices)
        #expect(notices.contains("MIT License"))
        #expect(notices.contains("Apache License"))
        #expect(notices.contains("END OF TERMS AND CONDITIONS"))
    }
}
