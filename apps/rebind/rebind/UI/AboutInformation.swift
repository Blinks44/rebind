import Foundation

/// Identity and notices from the running application, independent of user configuration.
struct AboutInformation {
    let version: String?
    let build: String?
    let notices: String?

    init(bundle: Bundle = .main) {
        version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        build = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        if let url = bundle.url(forResource: "ThirdPartyNotices", withExtension: "txt"),
           let text = try? String(contentsOf: url, encoding: .utf8),
           !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            notices = text
        } else {
            notices = nil
        }
    }

    var versionLabel: LocalizedStringResource {
        switch (version, build) {
        case (.some(let version), .some(let build)): .aboutVersionBuild(version, build)
        case (.some(let version), nil): .aboutVersion(version)
        case (nil, .some(let build)): .aboutBuild(build)
        case (nil, nil): .aboutVersionUnavailable
        }
    }
}
