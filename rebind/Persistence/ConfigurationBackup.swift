import Foundation

/// A validated configuration staged for backup or explicit replacement.
nonisolated struct ConfigurationBackup: Sendable {
    let configuration: Configuration

    /// Validates current configuration without writing or activating it.
    init(configuration: Configuration) throws {
        try configuration.validate()
        self.configuration = configuration
    }

    /// Decodes and migrates a bounded backup without changing its original bytes.
    init(data: Data) throws {
        guard data.count <= ConfigurationStore.maximumBytes else { throw ConfigurationError.invalid }
        configuration = try JSONDecoder().decode(Configuration.self, from: data).migrated()
    }

    /// Reads at most the size limit plus one byte before validation.
    init(contentsOf url: URL) throws {
        // A fresh URL avoids stale resource metadata after a failed save/retry.
        guard url.isFileURL,
              try URL(fileURLWithPath: url.path).resourceValues(forKeys: [.isRegularFileKey]).isRegularFile == true else {
            throw ConfigurationError.invalid
        }
        let file = try FileHandle(forReadingFrom: url)
        defer { try? file.close() }
        let limit = ConfigurationStore.maximumBytes
        var data = Data()
        while data.count <= limit {
            let chunk = try file.read(upToCount: limit + 1 - data.count) ?? Data()
            if chunk.isEmpty { break }
            data.append(chunk)
        }
        try self.init(data: data)
    }

    var profileCount: Int { configuration.profiles.count }

    /// The number of rules across all profiles; O(number of profiles).
    var bindingCount: Int { configuration.profiles.reduce(0) { $0 + $1.bindings.count } }

    /// Encodes a current-schema backup within the same size limit as local storage.
    func encoded() throws -> Data {
        let data = try JSONEncoder().encode(configuration)
        guard data.count <= ConfigurationStore.maximumBytes else { throw ConfigurationError.invalid }
        return data
    }
}
