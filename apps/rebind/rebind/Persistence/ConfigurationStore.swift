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

    /// Copies of the file as it loaded at launch, in `Backups` next to it. Any of them can be
    /// restored with Settings → Advanced → Import if the configuration is ever lost or damaged.
    var backupDirectory: URL { url.deletingLastPathComponent().appending(path: "Backups", directoryHint: .isDirectory) }
    static let keptBackups = 10

    /// Keeps a copy of the current file whenever it differs from the newest copy, and the newest
    /// `keptBackups` copies. Only called after the file loaded successfully. A copy per change,
    /// not per day: a launch with unexpected contents never replaces the copy taken before it.
    func backUpLoadedFile(on date: Date = .now) {
        guard let data = try? Data(contentsOf: url), !data.isEmpty else { return }
        let manager = FileManager.default
        try? manager.createDirectory(at: backupDirectory, withIntermediateDirectories: true)
        let copies = ((try? manager.contentsOfDirectory(at: backupDirectory, includingPropertiesForKeys: nil)) ?? [])
            .filter { $0.lastPathComponent.hasPrefix("configuration-") }
            .sorted { $0.lastPathComponent > $1.lastPathComponent }
        guard copies.first.flatMap({ try? Data(contentsOf: $0) }) != data else { return }
        let stamp = date.formatted(.iso8601.year().month().day().time(includingFractionalSeconds: false)
            .timeSeparator(.omitted).dateTimeSeparator(.standard))
        try? data.write(to: backupDirectory.appending(path: "configuration-\(stamp).json"), options: .atomic)
        for old in copies.dropFirst(Self.keptBackups - 1) { try? manager.removeItem(at: old) }
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
