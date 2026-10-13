import SwiftUI

struct AppleShortcutParameters: View {
    @SwiftUI.Binding var target: AppleShortcutTarget?
    @State private var shortcuts: [AppleShortcutTarget] = []
    @State private var refreshID = 0
    @State private var loading = true
    @State private var failed = false

    /// Listed shortcuts, keeping a saved one that is no longer installed selectable.
    private var choices: [AppleShortcutTarget] {
        (target.map { saved in shortcuts.contains(saved) ? [] : [saved] } ?? []) + shortcuts
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                MenuSelector(selection: $target, title: .appleShortcutTitle,
                    choices: [nil] + choices.map(Optional.some),
                    label: { $0.map { "\($0.name)" } ?? .targetNotSelected }, singleLine: true,
                    menuActionTitle: .refreshAppleShortcuts, menuAction: { refreshID += 1 })
                    .disabled(loading)
                if loading { ProgressView().controlSize(.small) }
            }
            if failed { Text(.appleShortcutsListFailed).font(Theme.caption).foregroundStyle(Theme.warningText) }
            else if !loading, shortcuts.isEmpty { Text(.appleShortcutsEmpty).font(Theme.caption).foregroundStyle(Theme.warningText) }
            else if !loading, let target, !shortcuts.contains(where: { $0.id == target.id }) {
                Text(.appleShortcutMissing).font(Theme.caption).foregroundStyle(Theme.warningText)
            }
            Text(.appleShortcutHint).font(Theme.caption).foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .task(id: refreshID) {
            loading = true; failed = false
            do {
                let loaded = try await AppleShortcuts.list()
                guard !Task.isCancelled else { return }
                shortcuts = loaded.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
                if let target, let renamed = shortcuts.first(where: { $0.id == target.id }) { self.target = renamed }
            } catch {
                guard !Task.isCancelled else { return }
                failed = true
            }
            loading = false
        }
    }
}
