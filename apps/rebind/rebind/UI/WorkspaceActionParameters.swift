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
                    Text(.webAddressInvalid).font(Theme.caption).foregroundStyle(Theme.warningText)
                }
            } else {
                let url = pickingApplication ? application?.url : file
                HStack(spacing: 12) {
                    if let url {
                        Image(nsImage: NSWorkspace.shared.icon(forFile: url.path)).resizable()
                            .frame(width: 32, height: 32).accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(verbatim: url.deletingPathExtension().lastPathComponent)
                                .font(Theme.bodyStrong).foregroundStyle(Theme.textPrimary).lineLimit(1)
                            Text(verbatim: url.path).font(Theme.caption).foregroundStyle(Theme.textSecondary)
                                .lineLimit(1).truncationMode(.middle).help(url.path)
                        }
                    } else {
                        Text(.targetNotSelected).font(Theme.body).foregroundStyle(Theme.textSecondary)
                    }
                    Spacer(minLength: 8)
                    Button(pickingApplication ? LocalizedStringResource.chooseApplication : .chooseFile) {
                        selectionFailed = false
                        showingPicker = true
                    }.secondaryButton().fixedSize()
                }
                .padding(.leading, 14).padding(.trailing, 10)
                .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
                .background(Theme.insetSurface, in: .rect(cornerRadius: 16, style: .continuous))
                .overlay { RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Theme.borderSubtle) }
                if selectionFailed { Text(.targetSelectionFailed).font(Theme.caption).foregroundStyle(Theme.warningText) }
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
