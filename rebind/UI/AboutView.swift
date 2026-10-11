import AppKit
import SwiftUI

/// The released About composition, using the delivered application icon.
struct AboutView: View {
    let information: AboutInformation
    @Environment(\.dismiss) private var dismiss
    @State private var showingLicenses = false

    init(information: AboutInformation = AboutInformation()) {
        self.information = information
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        Image(nsImage: NSWorkspace.shared.icon(forFile: Bundle.main.bundlePath))
                            .resizable().frame(width: 80, height: 80)
                            .accessibilityHidden(true)
                        VStack(spacing: 4) {
                            Text("Rebind").font(.largeTitle.bold()).accessibilityAddTraits(.isHeader)
                            Text(information.versionLabel).font(.caption).foregroundStyle(.secondary)
                                .textSelection(.enabled)
                        }
                    }
                    Text(.aboutDescription).foregroundStyle(.secondary)
                    Divider().frame(maxWidth: 200)
                    VStack(spacing: 12) {
                        Text(.aboutCredits).font(.callout).foregroundStyle(.secondary)
                        Button(.aboutLicenses) { showingLicenses = true }.buttonStyle(.bordered)
                    }
                }
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24).padding(.top, 32).padding(.bottom, 24)
            }
            HStack {
                Spacer()
                Button(.aboutDone) { dismiss() }.buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
            }.padding(24)
        }
        .background(PermissionCanvas())
        .frame(minWidth: 440, idealWidth: 440, minHeight: 448, idealHeight: 448)
        .sheet(isPresented: $showingLicenses) {
            ThirdPartyNoticesView(text: information.notices)
        }
        .onExitCommand {
            if !showingLicenses { dismiss() }
        }
    }
}
