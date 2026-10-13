nonisolated struct CompiledBinding: Sendable {
    var action: RebindAction
    var shortcut: KeyboardShortcut? { action.shortcut }
    var activation: PressActivation
    var holdDurationNanoseconds: UInt64 = 500_000_000
}
