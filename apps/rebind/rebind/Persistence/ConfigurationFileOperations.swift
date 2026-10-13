import Foundation

nonisolated enum ConfigurationReplacementError: Error {
    case protectedOriginal, staleReview, protectedDestination
}

/// File work is outside MainActor and never runs from an input callback.
nonisolated enum ConfigurationFileOperations {
    @concurrent static func readBackup(at url: URL) async throws -> ConfigurationBackup {
        try Task.checkCancellation()
        let access = url.startAccessingSecurityScopedResource()
        defer { if access { url.stopAccessingSecurityScopedResource() } }
        let backup = try ConfigurationBackup(contentsOf: url)
        try Task.checkCancellation()
        return backup
    }

    @concurrent static func export(_ backup: ConfigurationBackup, to destination: URL,
                                   protecting original: URL) async throws {
        let access = destination.startAccessingSecurityScopedResource()
        defer { if access { destination.stopAccessingSecurityScopedResource() } }
        try validateDestination(destination, protecting: original)
        let bytes = try backup.encoded()
        try Task.checkCancellation()
        try bytes.write(to: destination, options: .atomic)
    }

    @concurrent static func exportOriginal(at original: URL, to destination: URL) async throws {
        let access = destination.startAccessingSecurityScopedResource()
        defer { if access { destination.stopAccessingSecurityScopedResource() } }
        try validateDestination(destination, protecting: original)
        guard try URL(fileURLWithPath: original.path).resourceValues(forKeys: [.isRegularFileKey]).isRegularFile == true else {
            throw ConfigurationError.invalid
        }
        // Copy raw bytes through a replacement directory on the destination volume.
        // FileManager bounds memory even for a corrupt file beyond the JSON size limit.
        let manager = FileManager.default
        let staging = try manager.url(for: .itemReplacementDirectory, in: .userDomainMask,
                                      appropriateFor: destination, create: true)
        defer { try? manager.removeItem(at: staging) }
        let copy = staging.appending(path: "original.json")
        try Task.checkCancellation()
        try manager.copyItem(at: original.resolvingSymlinksInPath(), to: copy)
        try Task.checkCancellation()
        try validateDestination(destination, protecting: original)
        if manager.fileExists(atPath: destination.path) {
            _ = try manager.replaceItemAt(destination, withItemAt: copy)
        } else {
            try manager.moveItem(at: copy, to: destination)
        }
    }

    private static func validateDestination(_ destination: URL, protecting original: URL) throws {
        guard destination.isFileURL,
              destination.standardizedFileURL.resolvingSymlinksInPath()
                != original.standardizedFileURL.resolvingSymlinksInPath() else {
            throw ConfigurationReplacementError.protectedDestination
        }
        if FileManager.default.fileExists(atPath: destination.path) {
            let keys: Set<URLResourceKey> = [.fileResourceIdentifierKey, .isRegularFileKey]
            let target = try URL(fileURLWithPath: destination.path).resourceValues(forKeys: keys)
            guard target.isRegularFile == true else { throw ConfigurationError.invalid }
            let source = try? URL(fileURLWithPath: original.path).resourceValues(forKeys: keys)
            if let targetID = target.fileResourceIdentifier as? NSObject,
               let sourceID = source?.fileResourceIdentifier as? NSObject, targetID == sourceID {
                throw ConfigurationReplacementError.protectedDestination
            }
        }
    }
}
