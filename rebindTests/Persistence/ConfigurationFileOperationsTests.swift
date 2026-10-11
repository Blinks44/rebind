import Foundation
import Testing
@testable import rebind

struct ConfigurationFileOperationsTests {
    private func directory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appending(path: "RebindFileOperations-\(UUID())")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    @Test(arguments: [false, true])
    func exportNeverOverwritesOriginalOrItsAliases(raw: Bool) async throws {
        let directory = try directory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let original = directory.appending(path: "configuration.json")
        let bytes = try ConfigurationBackup(configuration: Configuration()).encoded()
        try bytes.write(to: original)
        let symlink = directory.appending(path: "symlink.json")
        let hardlink = directory.appending(path: "hardlink.json")
        try FileManager.default.createSymbolicLink(at: symlink, withDestinationURL: original)
        try FileManager.default.linkItem(at: original, to: hardlink)
        for target in [original, symlink, hardlink] {
            do {
                if raw { try await ConfigurationFileOperations.exportOriginal(at: original, to: target) }
                else { try await ConfigurationFileOperations.export(ConfigurationBackup(configuration: Configuration()),
                                                                   to: target, protecting: original) }
                Issue.record("Original destination was accepted")
            } catch is ConfigurationReplacementError { }
            #expect(try Data(contentsOf: original) == bytes)
        }
    }

    @Test func rawExportSupportsOversizedCorruptionAndAtomicallyReplacesDestination() async throws {
        let directory = try directory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let original = directory.appending(path: "configuration.json")
        let destination = directory.appending(path: "export.json")
        let bytes = Data(repeating: 0xAB, count: ConfigurationStore.maximumBytes + 1)
        try bytes.write(to: original)
        try Data("previous backup".utf8).write(to: destination)
        try await ConfigurationFileOperations.exportOriginal(at: original, to: destination)
        #expect(try Data(contentsOf: destination) == bytes)
        #expect(try Data(contentsOf: original) == bytes)
        let previous = try Data(contentsOf: destination)
        do {
            try await ConfigurationFileOperations.exportOriginal(at: directory.appending(path: "missing.json"), to: destination)
            Issue.record("Missing source was accepted")
        } catch { }
        #expect(try Data(contentsOf: destination) == previous)
    }

    @MainActor @Test func healthyExportRoundTripsAndCanceledExportPreservesDestination() async throws {
        let directory = try directory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let original = directory.appending(path: "configuration.json")
        let destination = directory.appending(path: "backup.json")
        var configuration = Configuration(isEnabled: true)
        try configuration.createProfile(name: "Русский Français")
        configuration.languagePreference = .de
        let backup = try ConfigurationBackup(configuration: configuration)
        try await ConfigurationFileOperations.export(backup, to: destination, protecting: original)
        #expect(try ConfigurationBackup(contentsOf: destination).configuration == configuration)
        let bytes = try Data(contentsOf: destination)
        let task = Task { try await ConfigurationFileOperations.export(backup, to: destination, protecting: original) }
        task.cancel()
        do { try await task.value; Issue.record("Cancelled export committed") } catch is CancellationError { }
        #expect(try Data(contentsOf: destination) == bytes)
        #expect(!FileManager.default.fileExists(atPath: original.path))
    }

    @Test func retryReadsFreshFileTypeAfterReplacingADirectory() throws {
        let directory = try directory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appending(path: "configuration.json")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: false)
        #expect(throws: ConfigurationError.invalid) { try ConfigurationBackup(contentsOf: url) }
        try FileManager.default.removeItem(at: url)
        try ConfigurationBackup(configuration: Configuration()).encoded().write(to: url)
        #expect(try ConfigurationBackup(contentsOf: url).configuration == Configuration())
    }
}
