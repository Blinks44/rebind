import SwiftUI

/// A native document sheet keeps complete license text local, searchable and selectable.
struct ThirdPartyNoticesView: View {
    let text: String?
    @Environment(\.dismiss) private var dismiss
    @State private var findRequest = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(.aboutLicenses).font(.title2.bold()).accessibilityAddTraits(.isHeader)
                Spacer()
                if text != nil {
                    Button(.aboutFind, systemImage: "magnifyingglass") { findRequest += 1 }
                        .keyboardShortcut("f", modifiers: .command)
                }
            }
            if let text {
                ReadOnlyNoticesText(text: text, findRequest: findRequest)
            } else {
                Text(.aboutLicensesUnavailable).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
            }
            HStack {
                Spacer()
                Button(.aboutDone) { dismiss() }.buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(minWidth: 560, idealWidth: 640, minHeight: 400, idealHeight: 520)
        .onExitCommand { dismiss() }
    }
}
