import Foundation

nonisolated enum ReleaseUpdate: Equatable, Sendable {
    case available(version: String)
    case current
    case noRelease

    static let releasesURL = URL(string: "https://github.com/Blinks44/rebind/releases")!
    static let latestURL = URL(string: "https://github.com/Blinks44/rebind/releases/latest")!

    /// No account, cookies, configuration or device information is included.
    static func check(currentVersion: String) async throws -> Self {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpCookieStorage = nil
        configuration.urlCredentialStorage = nil
        configuration.urlCache = nil
        configuration.timeoutIntervalForRequest = 15
        configuration.timeoutIntervalForResource = 20
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }
        var request = URLRequest(url: URL(string: "https://api.github.com/repos/Blinks44/rebind/releases/latest")!)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("Rebind", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await session.data(for: request)
        try Task.checkCancellation()
        guard let response = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        return try interpret(data: data, status: response.statusCode, currentVersion: currentVersion)
    }

    static func interpret(data: Data, status: Int, currentVersion: String) throws -> Self {
        guard let current = ReleaseVersion(currentVersion) else { throw URLError(.cannotParseResponse) }
        if status == 404 { return .noRelease }
        guard status == 200, data.count <= 1_000_000 else { throw URLError(.badServerResponse) }
        let release = try JSONDecoder().decode(PublishedRelease.self, from: data)
        guard !release.draft, !release.prerelease, let latest = ReleaseVersion(release.tag_name) else {
            throw URLError(.cannotParseResponse)
        }
        return latest > current ? .available(version: release.tag_name) : .current
    }
}

private nonisolated struct PublishedRelease: Decodable {
    let tag_name: String
    let draft: Bool
    let prerelease: Bool
}
