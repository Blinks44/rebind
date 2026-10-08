import Foundation

nonisolated struct Configuration: Codable, Equatable, Sendable {
    var schemaVersion = 1
    var isEnabled = false
    var bindings: [Binding] = []

    func validate() throws {
        guard schemaVersion == 1 else { throw ConfigurationError.incompatible }
        guard bindings.count <= 1000, Set(bindings.map(\.id)).count == bindings.count,
              bindings.allSatisfy(\.isValid) else { throw ConfigurationError.invalid }
        let keys = bindings.filter(\.isEnabled).map(\.matchKey)
        guard Set(keys).count == keys.count else { throw ConfigurationError.conflict }
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
        try configuration.validate()
        return configuration
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
