import SwiftUI

/// Sparkle's own automatic-check preference, shared by Settings and first-run setup.
struct UpdateSettingsRow: View {
    let updater: AppUpdater

    var body: some View {
        Card {
            Toggle(isOn: SwiftUI.Binding(get: { updater.automaticallyChecksForUpdates },
                                         set: { updater.automaticallyChecksForUpdates = $0 })) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(.automaticUpdates).font(Theme.bodyStrong).foregroundStyle(Theme.textPrimary)
                    Text(.automaticUpdatesDescription).font(Theme.callout).foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .toggleStyle(ThemeSwitchStyle())
        }
    }
}
