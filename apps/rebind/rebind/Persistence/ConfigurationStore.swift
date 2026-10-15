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

    /// Daily copies of the file as it loaded at launch, in `Backups` next to it. Any of them can be
    /// restored with Settings → Advanced → Import if the configuration is ever lost or damaged.
    var backupDirectory: URL { url.deletingLastPathComponent().appending(path: "Backups", directoryHint: .isDirectory) }
    static let keptBackups = 7

    /// Keeps today's copy of the current file and the newest `keptBackups` days; only called
    /// after the file loaded successfully, so a damaged file never replaces a good copy.
    func backUpLoadedFile(on date: Date = .now) {
        guard let data = try? Data(contentsOf: url), !data.isEmpty else { return }
        let manager = FileManager.default
        try? manager.createDirectory(at: backupDirectory, withIntermediateDirectories: true)
        let day = date.formatted(.iso8601.year().month().day())
        try? data.write(to: backupDirectory.appending(path: "configuration-\(day).json"), options: .atomic)
        let copies = (try? manager.contentsOfDirectory(at: backupDirectory, includingPropertiesForKeys: nil)) ?? []
        let dated = copies.filter { $0.lastPathComponent.hasPrefix("configuration-") }
            .sorted { $0.lastPathComponent > $1.lastPathComponent }
        for old in dated.dropFirst(Self.keptBackups) { try? manager.removeItem(at: old) }
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
