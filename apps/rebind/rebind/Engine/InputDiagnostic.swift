// Numeric mouse metadata only: no keyboard codes, text, positions, CGEvents or actions.
nonisolated struct InputDiagnostic: Identifiable, Equatable, Sendable {
    enum Kind: Equatable, Sendable {
        case button(UInt32), wheel(ScrollDirection), unsupportedScroll
    }
    enum Phase: Equatable, Sendable { case down, up, drag, scroll, activation }
    /// `adjusted`: passed on with the wheel reversed or sped up (Input settings).
    enum Outcome: Equatable, Sendable { case passedThrough, adjusted, suppressed, queued }

    let id: UInt64
    let elapsedMilliseconds: UInt64
    let kind: Kind
    let phase: Phase
    let modifiers: ModifierSet
    let outcome: Outcome
}
