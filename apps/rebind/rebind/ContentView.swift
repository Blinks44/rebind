import SwiftUI

struct ContentView: View {
    let model: AppModel
    @Environment(\.openWindow) private var openWindow
    @State private var selection: MainDestination = .input(.allKeyboards)
    @State private var editor: EditorSelection?
    @State private var pendingDeletion: Binding?
    @State private var showingProfiles = false
    @State private var setupPresentation = PermissionSetupPresentation()
    @State private var titlebarInset: CGFloat?

    /// The window reopens on the input category last shown (a window preference, not configuration).
    private static let lastScopeKey = "MainWindowLastScope"

    init(model: AppModel, initialDestination: MainDestination? = nil) {
        self.model = model
        let lastScope = UserDefaults.standard.string(forKey: Self.lastScopeKey).flatMap(DeviceScope.init(rawValue:))
        _selection = State(initialValue: initialDestination ?? .input(lastScope ?? .allKeyboards))
    }

    var body: some View {
        HStack(spacing: 0) {
            MainSidebar(selection: $selection, showAbout: { openWindow(id: "about") })
                .frame(width: 240)
                .background { MainWindowSizing(titlebarInset: $titlebarInset).allowsHitTesting(false).accessibilityHidden(true) }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("main-sidebar")
            Group {
                switch selection {
                case .input(let scope):
                    BindingsView(model: model, scope: scope,
                        add: { editor = EditorSelection(scope: scope, binding: nil) },
                        edit: { editor = EditorSelection(scope: scope, binding: $0) },
                        duplicate: { editor = EditorSelection(scope: scope, binding: $0.duplicated(), isCopy: true) },
                        delete: { pendingDeletion = $0 },
                        manageProfiles: { showingProfiles = true },
                        openPermissions: { selection = .settings(.permissions) })
                case .settings: SettingsView(model: model, selection: settingsSection).padding(.top, 28)
                }
            }.frame(minWidth: 640, maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("main-detail")
        }
        .background { ThemeCanvas() }
        .frame(minWidth: 880, minHeight: titlebarInset.map { max(0, 600 - $0) })
        .ignoresSafeArea(.container, edges: .top)
        // An empty unified toolbar gives the window the tall titlebar of a sidebar app, so macOS
        // itself places the window buttons inside the sidebar panel. Content starts below that strip.
        .toolbar { ToolbarItem(placement: .navigation) { Color.clear.frame(width: 1, height: 1) }.sharedBackgroundVisibility(.hidden) }
        .toolbar(removing: .title)
        .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
        .sheet(item: $setupPresentation.context) { context in
            PermissionSetupView(model: model, context: context)
        }
        .sheet(item: $editor) { selection in
            BindingEditor(model: model, scope: selection.scope, existing: selection.binding, isCopy: selection.isCopy)
        }
        .sheet(isPresented: $showingProfiles) { ProfileManagerView(model: model) }
        .onChange(of: selection) {
            if case .input(let scope) = selection { UserDefaults.standard.set(scope.rawValue, forKey: Self.lastScopeKey) }
        }
        .onChange(of: model.configuration.selectedProfileID) {
            editor = nil
            pendingDeletion = nil
        }
        .onChange(of: model.configurationReplacementRevision) {
            editor = nil
            pendingDeletion = nil
            showingProfiles = false
        }
        .onAppear {
            setupPresentation.beginIfNeeded(needsSetup: model.needsPermissionSetup)
        }
        .onChange(of: model.permissions.allowsRemapping) { wasAllowed, isAllowed in
            // Recover once while idle. Active editors and later revocations keep the inline notice.
            setupPresentation.permissionsChanged(wasAllowed: wasAllowed, isAllowed: isAllowed,
                canPresent: NSApp.isActive && editor == nil && pendingDeletion == nil
                    && !showingProfiles)
        }
        .alert(.deleteBinding, isPresented: deletionPresented) {
            Button(.cancel, role: .cancel) { pendingDeletion = nil }
            Button(.deleteBinding, role: .destructive) {
                if let binding = pendingDeletion { model.delete(binding.id) }
                pendingDeletion = nil
            }
        } message: { Text(.deleteBindingConfirmation) }
    }

    private var deletionPresented: SwiftUI.Binding<Bool> {
        SwiftUI.Binding(get: { pendingDeletion != nil }, set: { if !$0 { pendingDeletion = nil } })
    }

    private var settingsSection: SwiftUI.Binding<SettingsSection> {
        SwiftUI.Binding(get: {
            if case .settings(let section) = selection { return section }
            return .general
        }, set: { selection = .settings($0) })
    }
}

private struct EditorSelection: Identifiable {
    let id = UUID()
    let scope: DeviceScope
    var binding: Binding?
    var isCopy = false
}
