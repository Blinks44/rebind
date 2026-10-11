import Foundation

nonisolated enum ConfigurationError: Error, Equatable { case incompatible, invalid, conflict, profileInvalid, profileLimit, lastProfile }

nonisolated struct ConfigurationStore: Sendable {
    static let maximumBytes = 2_000_000
    let url: URL

    static var applicationStore: Self {
        let directory = URL.applicationSupportDirectory.appending(path: "Rebind", directoryHint: .isDirectory)
        return Self(url: directory.appending(path: "configuration.json"))
    }

    func load() throws -> Configuration {
        guard FileManager.default.fileExists(atPath: url.path) else { return Configuration() }
        // Migration is in memory. Preserve the original until a successful save.
        return try ConfigurationBackup(contentsOf: url).configuration
    }

    func save(_ configuration: Configuration) throws {
        let data = try ConfigurationBackup(configuration: configuration).encoded()
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                                withIntermediateDirectories: true)
        // If reading fails, the UI locks editing; never overwrite an unreadable file.
        try data.write(to: url, options: .atomic)
    }
}
