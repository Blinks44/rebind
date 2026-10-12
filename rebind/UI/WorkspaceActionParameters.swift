import SwiftUI
import UniformTypeIdentifiers

struct WorkspaceActionParameters: View {
    let kind: ActionKind
    @SwiftUI.Binding var application: ApplicationTarget?
    @SwiftUI.Binding var webAddress: String
    @SwiftUI.Binding var file: URL?
    @State private var showingPicker = false
    @State private var selectionFailed = false

    private var pickingApplication: Bool { kind == .openApplication || kind == .activateApplication || kind == .quitApplication }

    private var hint: LocalizedStringResource {
        if kind == .quitApplication { return .quitApplicationHint }
        if kind == .activateApplication { return .activateApplicationHint }
        return .openTargetHint
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if kind == .openURL {
                ThemeTextField(title: .webAddressTitle, text: $webAddress, prompt: Text(verbatim: "https://example.com"))
                if !webAddress.isEmpty && WorkspaceAction.webURL(webAddress) == nil {
                    Text(.webAddressInvalid).foregroundStyle(Theme.textSecondary)
                }
            } else {
                if let url = pickingApplication ? application?.url : file {
                    Text(url.lastPathComponent).lineLimit(2)
                    Text(url.path).font(Theme.caption).foregroundStyle(Theme.textSecondary)
                        .lineLimit(3).help(url.path)
                } else { Text(.targetNotSelected).foregroundStyle(Theme.textSecondary) }
                Button(pickingApplication ? LocalizedStringResource.chooseApplication : .chooseFile) {
                    selectionFailed = false
                    showingPicker = true
                }.secondaryButton()
                if selectionFailed { Text(.targetSelectionFailed).foregroundStyle(Theme.textSecondary) }
            }
            Text(hint)
                .font(Theme.caption).foregroundStyle(Theme.textSecondary).fixedSize(horizontal: false, vertical: true)
        }
        .fileImporter(isPresented: $showingPicker,
                      allowedContentTypes: pickingApplication ? [.applicationBundle] : [.item, .folder]) { result in
            switch result {
            case .success(let url):
                let accessed = url.startAccessingSecurityScopedResource()
                defer { if accessed { url.stopAccessingSecurityScopedResource() } }
                if pickingApplication {
                    guard let bundle = Bundle(url: url), let identifier = bundle.bundleIdentifier,
                          bundle.infoDictionary?["CFBundlePackageType"] as? String == "APPL" else {
                        selectionFailed = true; return
                    }
                    let target = ApplicationTarget(url: url.standardizedFileURL, bundleIdentifier: identifier)
                    guard target.isSupported else { selectionFailed = true; return }
                    application = target
                } else {
                    let action = WorkspaceAction.openFile(url.standardizedFileURL)
                    guard action.isSupported else { selectionFailed = true; return }
                    file = action.url
                }
            case .failure:
                // Dismissing the native picker normally produces no selection.
                selectionFailed = true
            }
        }
        .onChange(of: kind) { selectionFailed = false }
    }
}
