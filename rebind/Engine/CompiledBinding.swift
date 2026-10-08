nonisolated struct CompiledBinding: Sendable {
    var shortcut: KeyboardShortcut
    var activation: PressActivation
    var holdDurationNanoseconds: UInt64 = 500_000_000
}
