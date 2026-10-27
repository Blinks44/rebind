import SwiftUI

/// Running device companion apps, on the Mouse page and in Devices.
struct CompanionBanner: View {
    let apps: [CompanionApp]
    var dismiss: (() -> Void)?
    var message: LocalizedStringResource = .companionRunningMessage

    private var title: LocalizedStringResource {
        let names = apps.map(\.name).formatted(.list(type: .and).locale(AppLocalization.language.locale))
        return apps.count == 1 ? .companionRunningOne(names) : .companionRunningMany(names)
    }

    var body: some View {
        Banner(severity: .warning, title: title, message: message, dismiss: dismiss)
    }
}
