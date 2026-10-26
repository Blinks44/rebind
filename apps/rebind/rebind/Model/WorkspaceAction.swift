import Foundation

nonisolated struct ApplicationTarget: Codable, Equatable, Sendable {
    var url: URL
    var bundleIdentifier: String

    var isSupported: Bool {
        WorkspaceAction.isLocalFile(url) && url.pathExtension.lowercased() == "app"
            && !bundleIdentifier.isEmpty && bundleIdentifier.utf8.count <= 255
            && !bundleIdentifier.unicodeScalars.contains { CharacterSet.whitespacesAndNewlines.contains($0) || CharacterSet.controlCharacters.contains($0) }
            && bundleIdentifier != "blinks44.rebind"
    }

    func matchesRunningApplication(bundleIdentifier identifier: String?, url candidate: URL?) -> Bool {
        // Directory URL hints/trailing slashes differ between the picker and
        // Launch Services. Compare filesystem paths, not URL representation.
        identifier == bundleIdentifier && candidate?.standardizedFileURL.path == url.standardizedFileURL.path
    }
}

extension ApplicationTarget {
    /// A user-picked application bundle, or nil when it is not an app Rebind can target.
    init?(bundleURL url: URL) {
        guard let bundle = Bundle(url: url), let identifier = bundle.bundleIdentifier,
              bundle.infoDictionary?["CFBundlePackageType"] as? String == "APPL" else { return nil }
        self.init(url: url.standardizedFileURL, bundleIdentifier: identifier)
        guard isSupported else { return nil }
    }
}

nonisolated enum WorkspaceAction: Codable, Equatable, Sendable {
    case openApplication(ApplicationTarget)
    case activateApplication(ApplicationTarget)
    case quitApplication(ApplicationTarget)
    case previousApplication
    case openSystemSettings
    case openApps
    case openURL(URL)
    case openFile(URL)

    var application: ApplicationTarget? {
        switch self {
        case .openApplication(let target), .activateApplication(let target), .quitApplication(let target): target
        default: nil
        }
    }

    var url: URL? {
        switch self {
        case .openApplication(let target), .activateApplication(let target), .quitApplication(let target): target.url
        case .openURL(let url), .openFile(let url): url
        case .openSystemSettings, .openApps, .previousApplication: nil
        }
    }

    var isSupported: Bool {
        switch self {
        case .openApplication(let target), .activateApplication(let target), .quitApplication(let target): target.isSupported
        case .openSystemSettings, .openApps, .previousApplication: true
        case .openURL(let url): Self.webURL(url.absoluteString) != nil
        case .openFile(let url): Self.isLocalFile(url) && url.pathExtension.lowercased() != "app"
        }
    }

    static func webURL(_ text: String) -> URL? {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, text.utf8.count <= 8192,
              !text.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) }),
              let url = URL(string: text, encodingInvalidCharacters: false),
              let scheme = url.scheme?.lowercased(), ["http", "https"].contains(scheme),
              let host = url.host, !host.isEmpty, url.user == nil, url.password == nil else { return nil }
        return url
    }

    static func isLocalFile(_ url: URL) -> Bool {
        url.isFileURL && url.path.hasPrefix("/") && url.path != "/"
            && url.path.utf8.count <= 4096 && !url.path.unicodeScalars.contains { CharacterSet.controlCharacters.contains($0) }
            && (url.host == nil || url.host == "" || url.host == "localhost")
            && url.query == nil && url.fragment == nil && url.user == nil && url.password == nil
    }
}
