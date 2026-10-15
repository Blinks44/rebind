import SwiftUI

/// One warning for every mouse maker's app that is running, on the Mouse page and in Devices.
struct CompanionBanner: View {
    let apps: [CompanionApp]
    var dismiss: (() -> Void)?

    private var title: LocalizedStringResource {
        let names = apps.map(\.name).formatted(.list(type: .and).locale(AppLocalization.language.locale))
        return apps.count == 1 ? .companionRunningOne(names) : .companionRunningMany(names)
    }

    var body: some View {
        Banner(severity: .warning, title: title, message: .companionRunningMessage, dismiss: dismiss)
    }
}
