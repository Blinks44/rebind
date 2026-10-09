import Foundation

nonisolated enum AppleShortcutRunResult: Sendable { case performed, cancelled, failed }

nonisolated enum AppleShortcuts {
    @concurrent static func list() async throws -> [AppleShortcutTarget] {
        let data = try ShortcutsProcess.execute(arguments: ["list", "--show-identifiers"], collectOutput: true,
                                               timeout: 10, canContinue: { !Task.isCancelled })
        try Task.checkCancellation()
        return try AppleShortcutTarget.parseList(data)
    }

    static func run(_ target: AppleShortcutTarget, canPerform: () -> Bool,
                    execute: @escaping ([String], () -> Bool) throws -> Void = { arguments, allowed in
                        _ = try ShortcutsProcess.execute(arguments: arguments, collectOutput: false,
                                                         timeout: 60, canContinue: allowed)
                    }) -> AppleShortcutRunResult {
        guard target.isSupported else { return .failed }
        do {
            // UUID is one positional argument. Names never become shell code,
            // options, clipboard input or a fallback to a different shortcut.
            guard canPerform() else { return .cancelled }
            try execute(["run", target.id.uuidString], { canPerform() })
            return .performed
        } catch ShortcutsProcess.Failure.cancelled { return .cancelled }
        catch { return .failed }
    }
}
