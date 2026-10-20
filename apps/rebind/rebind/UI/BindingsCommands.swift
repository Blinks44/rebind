import SwiftUI

/// Native key-equivalent routing stays available while the sidebar or a row owns focus.
struct BindingsCommands: Commands {
    @FocusedValue(\.findBindings) private var findBindings

    var body: some Commands {
        CommandGroup(after: .textEditing) {
            Button(.mouseSearchBindings) { findBindings?() }
                .keyboardShortcut("f", modifiers: .command)
                .disabled(findBindings == nil)
        }
    }
}

private struct FindBindingsKey: FocusedValueKey {
    typealias Value = () -> Void
}

extension FocusedValues {
    var findBindings: (() -> Void)? {
        get { self[FindBindingsKey.self] }
        set { self[FindBindingsKey.self] = newValue }
    }
}
