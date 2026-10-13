import SwiftUI
import UniformTypeIdentifiers

/// Apps in which Rebind leaves all input alone while they are in front.
struct ExcludedApplicationsCard: View {
    let model: AppModel
    @State private var showingPicker = false
    @State private var selectionFailed = false

    private var applications: [ApplicationTarget] { model.configuration.excludedApplications }
    private var atLimit: Bool { applications.count >= Configuration.maximumExcludedApplications }

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(.excludedAppsTitle).font(Theme.bodyStrong).foregroundStyle(Theme.textPrimary)
                            .accessibilityAddTraits(.isHeader)
                        Text(.excludedAppsDescription).font(Theme.callout).foregroundStyle(Theme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Button(.addExcludedApp) { selectionFailed = false; showingPicker = true }
                        .secondaryButton().fixedSize().disabled(atLimit)
                }
                ForEach(applications, id: \.bundleIdentifier) { row($0) }
                if selectionFailed {
                    Text(.excludedAppRejected).font(Theme.caption).foregroundStyle(Theme.warningText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .disabled(model.storageLocked)
        .fileImporter(isPresented: $showingPicker, allowedContentTypes: [.applicationBundle]) { result in
            guard case .success(let url) = result else { return }
            let accessed = url.startAccessingSecurityScopedResource()
            defer { if accessed { url.stopAccessingSecurityScopedResource() } }
            guard let target = ApplicationTarget(bundleURL: url), model.excludeApplication(target) else {
                selectionFailed = true
                return
            }
        }
    }

    private func row(_ application: ApplicationTarget) -> some View {
        let name = application.url.deletingPathExtension().lastPathComponent
        return HStack(spacing: 12) {
            Image(nsImage: NSWorkspace.shared.icon(forFile: application.url.path)).resizable()
                .frame(width: 28, height: 28).accessibilityHidden(true)
            Text(verbatim: name).font(Theme.body).foregroundStyle(Theme.textPrimary).lineLimit(1)
            Spacer(minLength: 8)
            CircleIconButton(symbol: "minus") { model.includeApplication(application.bundleIdentifier) }
            .accessibilityLabel(Text(.removeExcludedApp(name))).help(Text(.removeExcludedApp(name)))
        }
        .padding(.leading, 12).padding(.trailing, 10).frame(minHeight: 48)
        .insetSurface()
    }
}
