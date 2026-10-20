import SwiftUI
import UniformTypeIdentifiers

/// Where a rule works: every app, or only while one chosen app is in front.
struct RuleApplicationField: View {
    @SwiftUI.Binding var application: ApplicationTarget?
    @Environment(\.locale) private var locale
    @State private var choosing = false
    @State private var rejected = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(.bindingAppTitle)
            AnchoredMenu(select: { _ in }, makeMenu: { _ in
                NSHostingMenu(rootView: Group {
                    Button(.bindingAllApps) { application = nil }
                    Button(.bindingChooseApp) { rejected = false; choosing = true }
                }.environment(\.locale, locale))
            }) {
                HStack(spacing: 10) {
                    if let application {
                        Image(nsImage: NSWorkspace.shared.icon(forFile: application.url.path)).resizable()
                            .frame(width: 18, height: 18).accessibilityHidden(true)
                        Text(verbatim: application.displayName)
                    } else {
                        Image(systemName: "square.grid.2x2").font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Theme.accent).frame(width: 18).accessibilityHidden(true)
                        Text(.bindingAllApps)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.up.chevron.down").font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Theme.iconSecondary)
                }
                .font(Theme.body).foregroundStyle(Theme.textPrimary).lineLimit(1)
                .padding(.horizontal, 16).frame(height: Theme.controlHeight).contentShape(.capsule)
            }
            .accessibilityLabel(Text(.bindingAppTitle))
            .accessibilityValue(Text(verbatim: application?.displayName ?? AppLocalization.string(.bindingAllApps)))
            Text(rejected ? LocalizedStringResource.bindingAppRejected : .bindingAppHint)
                .font(Theme.caption).foregroundStyle(rejected ? Theme.warningText : Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .fileImporter(isPresented: $choosing, allowedContentTypes: [.applicationBundle]) { result in
            guard case .success(let url) = result else { return }
            let accessed = url.startAccessingSecurityScopedResource()
            defer { if accessed { url.stopAccessingSecurityScopedResource() } }
            if let target = ApplicationTarget(bundleURL: url) { application = target } else { rejected = true }
        }
    }
}

extension ApplicationTarget {
    /// The app's name as Finder shows it, without the .app extension.
    var displayName: String { url.deletingPathExtension().lastPathComponent }
}
