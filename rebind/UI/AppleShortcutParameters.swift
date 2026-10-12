import SwiftUI

struct AppleShortcutParameters: View {
    @SwiftUI.Binding var target: AppleShortcutTarget?
    @State private var shortcuts: [AppleShortcutTarget] = []
    @State private var refreshID = 0
    @State private var loading = true
    @State private var failed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker(.appleShortcutTitle, selection: $target) {
                Text(.targetNotSelected).tag(Optional<AppleShortcutTarget>.none)
                if let target, !shortcuts.contains(target) {
                    Text(verbatim: target.name).tag(Optional(target))
                }
                ForEach(shortcuts) { shortcut in
                    Text(verbatim: shortcut.name).tag(Optional(shortcut))
                }
            }.disabled(loading)
            HStack {
                Button(.refreshAppleShortcuts) { refreshID += 1 }.disabled(loading)
                if loading { ProgressView().controlSize(.small) }
            }
            if failed { Text(.appleShortcutsListFailed).foregroundStyle(Theme.textSecondary) }
            else if !loading, shortcuts.isEmpty { Text(.appleShortcutsEmpty).foregroundStyle(Theme.textSecondary) }
            else if !loading, let target, !shortcuts.contains(where: { $0.id == target.id }) {
                Text(.appleShortcutMissing).foregroundStyle(Theme.textSecondary)
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
