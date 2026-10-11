import Foundation

nonisolated enum ConfigurationError: Error, Equatable { case incompatible, invalid, conflict, profileInvalid, profileLimit, lastProfile }

/// An existing on-disk original cannot be safely replaced by an ordinary save.
nonisolated enum ConfigurationStoreError: Error, Equatable { case protectedOriginal }

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
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory), !isDirectory.boolValue {
            // Startup validation is insufficient: another process may have
            // replaced the original after launch. Reuse the bounded read/codec.
            do { _ = try ConfigurationBackup(contentsOf: url) }
            catch { throw ConfigurationStoreError.protectedOriginal }
        }
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                                withIntermediateDirectories: true)
        // Directory/write failures remain retryable; this is not interprocess locking.
        try data.write(to: url, options: .atomic)
    }
}
