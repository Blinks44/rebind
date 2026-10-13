/// An output that lasts while its trigger stays down. A shortcut is one key press with
/// repeats and a release; a step action is queued again at the key-repeat rate.
nonisolated struct HeldOutput: Sendable, Equatable {
    var trigger: InputTrigger
    var action: RebindAction
    /// Worker time of the press; nil until the worker has performed it.
    var pressedAt: UInt64?
    var lastRepeatAt: UInt64?
    var released = false
}

nonisolated struct HeldKeyCommand: Sendable, Equatable {
    enum Phase: Sendable { case press, repeatPress, release }
    var shortcut: KeyboardShortcut
    var phase: Phase
}

nonisolated struct KeyRepeatTiming: Sendable, Equatable {
    var delayNanoseconds: UInt64 = 500_000_000
    var intervalNanoseconds: UInt64 = 80_000_000
}
