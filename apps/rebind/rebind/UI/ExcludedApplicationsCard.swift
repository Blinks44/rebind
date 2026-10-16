import SwiftUI
import UniformTypeIdentifiers

/// Apps in which Rebind skips bindings and/or smooth scrolling while they are in front.
struct ExcludedApplicationsCard: View {
    let model: AppModel
    @State private var showingPicker = false
    @State private var selectionFailed = false

    private var applications: [ExcludedApplication] { model.configuration.excludedApplications }
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
                if !applications.isEmpty {
                    HStack(spacing: 0) {
                        Spacer(minLength: 0)
                        columnTitle(.excludedBindingsColumn)
                        columnTitle(.smoothScrollingTitle)
                        Color.clear.frame(width: 28 + 10)
                    }
                    .accessibilityHidden(true)
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

    /// Each switch column is as wide as its title so the switches line up under it.
    private static let columnWidth: CGFloat = 112

    private func columnTitle(_ title: LocalizedStringResource) -> some View {
        Text(title).font(Theme.caption).foregroundStyle(Theme.textSecondary).lineLimit(2)
            .multilineTextAlignment(.center).frame(width: Self.columnWidth)
    }

    private func row(_ application: ExcludedApplication) -> some View {
        let name = application.target.url.deletingPathExtension().lastPathComponent
        let id = application.bundleIdentifier
        return HStack(spacing: 12) {
            Image(nsImage: NSWorkspace.shared.icon(forFile: application.target.url.path)).resizable()
                .frame(width: 28, height: 28).accessibilityHidden(true)
            Text(verbatim: name).font(Theme.body).foregroundStyle(Theme.textPrimary).lineLimit(1)
            Spacer(minLength: 8)
            HStack(spacing: 0) {
                allowance(.excludedBindingsColumn, app: name, isOn: application.allowsBindings) {
                    model.setExclusion(id, allowsBindings: $0)
                }
                allowance(.smoothScrollingTitle, app: name, isOn: application.allowsSmoothScrolling) {
                    model.setExclusion(id, allowsSmoothScrolling: $0)
                }
            }
            .padding(.trailing, -12)
            CircleIconButton(symbol: "minus") { model.includeApplication(application.bundleIdentifier) }
            .accessibilityLabel(Text(.removeExcludedApp(name))).help(Text(.removeExcludedApp(name)))
        }
        .padding(.leading, 12).padding(.trailing, 10).frame(minHeight: 48)
        .insetSurface()
    }

    /// On: this feature keeps working while the app is in front.
    private func allowance(_ title: LocalizedStringResource, app: String, isOn: Bool,
                           set: @escaping @MainActor @Sendable (Bool) -> Void) -> some View {
        Toggle(isOn: SwiftUI.Binding(get: { isOn }, set: set)) { Text(title) }
            .toggleStyle(ThemeSwitchStyle()).labelsHidden()
            .frame(width: Self.columnWidth)
            .accessibilityLabel(Text(verbatim: "\(app), \(AppLocalization.string(title))"))
    }
}
