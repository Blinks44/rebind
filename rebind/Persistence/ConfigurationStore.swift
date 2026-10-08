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
        let data = try Data(contentsOf: url)
        guard data.count <= Self.maximumBytes else { throw ConfigurationError.invalid }
        let configuration = try JSONDecoder().decode(Configuration.self, from: data)
        // Migration is in memory. Preserve the original until a successful save.
        return try configuration.migrated()
    }

    func save(_ configuration: Configuration) throws {
        try configuration.validate()
        let data = try JSONEncoder().encode(configuration)
        guard data.count <= Self.maximumBytes else { throw ConfigurationError.invalid }
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                                withIntermediateDirectories: true)
        // If reading fails, the UI locks editing; never overwrite an unreadable file.
        try data.write(to: url, options: .atomic)
    }
}
