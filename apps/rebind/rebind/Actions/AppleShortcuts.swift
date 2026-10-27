import Foundation

nonisolated enum AppleShortcutRunResult: Sendable { case performed, cancelled, failed }

nonisolated enum AppleShortcuts {
    @concurrent static func list() async throws -> [AppleShortcutTarget] {
        let data = try await ShortcutsProcess.execute(arguments: ["list", "--show-identifiers"], collectOutput: true,
                                               timeout: 10, canContinue: { !Task.isCancelled })
        try Task.checkCancellation()
        return try AppleShortcutTarget.parseList(data)
    }

    static func run(_ target: AppleShortcutTarget, canPerform: @escaping @Sendable () -> Bool,
                    execute: @escaping @Sendable ([String], @escaping @Sendable () -> Bool) async throws -> Void = { arguments, allowed in
                        _ = try await ShortcutsProcess.execute(arguments: arguments, collectOutput: false,
                                                         timeout: 60, canContinue: allowed)
                    }) async -> AppleShortcutRunResult {
        guard target.isSupported else { return .failed }
        do {
            // UUID is one positional argument. Names never become shell code,
            // options, clipboard input or a fallback to a different shortcut.
            guard canPerform() else { return .cancelled }
            try await execute(["run", target.id.uuidString], canPerform)
            return .performed
        } catch is CancellationError { return .cancelled }
        catch ShortcutsProcess.Failure.cancelled { return .cancelled }
        catch { return .failed }
    }
}
