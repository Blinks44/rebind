nonisolated struct DiagnosticSnapshot: Equatable, Sendable {
    var revision: UInt64 = 0
    var isRunning = false
    var entries: [InputDiagnostic] = []
    var omitted: UInt64 = 0
}
