@testable import rebind

/// Shortcut-typed views of `TrackpadRuntime.actions` for the tap-engine suites.
extension TrackpadRuntime {
    init(revision: UInt64, inputActivity: UInt64, fourFingerShortcut: KeyboardShortcut?) {
        self.init(revision: revision, inputActivity: inputActivity)
        self.fourFingerShortcut = fourFingerShortcut
    }

    func shortcut(for gesture: TrackpadTapGesture) -> KeyboardShortcut? { actions[gesture]?.shortcut }
    func shortcut(for tap: TrackpadSingleTap) -> KeyboardShortcut? { shortcut(for: .single(tap)) }

    private subscript(shortcut gesture: TrackpadTapGesture) -> KeyboardShortcut? {
        get { actions[gesture]?.shortcut }
        set { actions[gesture] = newValue.map(RebindAction.shortcut) }
    }

    var threeFingerShortcut: KeyboardShortcut? {
        get { self[shortcut: .single(.threeFinger)] } set { self[shortcut: .single(.threeFinger)] = newValue }
    }
    var fourFingerShortcut: KeyboardShortcut? {
        get { self[shortcut: .single(.fourFinger)] } set { self[shortcut: .single(.fourFinger)] = newValue }
    }
    var threeFingerDoubleShortcut: KeyboardShortcut? {
        get { self[shortcut: .double(.threeFinger)] } set { self[shortcut: .double(.threeFinger)] = newValue }
    }
    var fourFingerDoubleShortcut: KeyboardShortcut? {
        get { self[shortcut: .double(.fourFinger)] } set { self[shortcut: .double(.fourFinger)] = newValue }
    }
    var twoFingerDoubleShortcut: KeyboardShortcut? {
        get { self[shortcut: .twoFingerDouble] } set { self[shortcut: .twoFingerDouble] = newValue }
    }
}
