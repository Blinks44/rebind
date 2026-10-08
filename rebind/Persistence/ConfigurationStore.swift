import Foundation

nonisolated struct Configuration: Codable, Equatable, Sendable {
    static let currentSchemaVersion = 2
    var schemaVersion = Self.currentSchemaVersion
    var isEnabled = false
    var bindings: [Binding] = []

    func validate() throws {
        guard schemaVersion == Self.currentSchemaVersion else { throw ConfigurationError.incompatible }
        guard bindings.count <= 1000, Set(bindings.map(\.id)).count == bindings.count,
              bindings.allSatisfy(\.isValid) else { throw ConfigurationError.invalid }
        let keys = bindings.filter(\.isEnabled).map(\.matchKey)
        guard Set(keys).count == keys.count else { throw ConfigurationError.conflict }
    }

    func migrated() throws -> Configuration {
        var result = self
        if schemaVersion == 1 {
            // Version 1 supports key/button rules only. Reject disguised future
            // content rather than silently accepting it as a legacy configuration.
            guard bindings.allSatisfy({ if case .scroll = $0.trigger { return false }; return true }) else {
                throw ConfigurationError.invalid
            }
            result.schemaVersion = Self.currentSchemaVersion
        }
        try result.validate()
        return result
    }
}

nonisolated enum ConfigurationError: Error, Equatable { case incompatible, invalid, conflict }

nonisolated struct ConfigurationStore: Sendable {
    let url: URL

    static var applicationStore: Self {
        let directory = URL.applicationSupportDirectory.appending(path: "Rebind", directoryHint: .isDirectory)
        return Self(url: directory.appending(path: "configuration.json"))
    }

    func load() throws -> Configuration {
        guard FileManager.default.fileExists(atPath: url.path) else { return Configuration() }
        let data = try Data(contentsOf: url)
        guard data.count <= 2_000_000 else { throw ConfigurationError.invalid }
        let configuration = try JSONDecoder().decode(Configuration.self, from: data)
        // Migration is in memory. Preserve the original until a successful save.
        return try configuration.migrated()
    }

    func save(_ configuration: Configuration) throws {
        try configuration.validate()
        let data = try JSONEncoder().encode(configuration)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                                withIntermediateDirectories: true)
        // If reading fails, the UI locks editing; never overwrite an unreadable file.
        try data.write(to: url, options: .atomic)
    }
}
