import SwiftUI

struct ContentView: View {
    let model: AppModel
    @State private var selection: MainDestination = .input(.allKeyboards)
    @State private var editor: EditorSelection?
    @State private var pendingDeletion: Binding?
    @State private var showingDiagnostics = false
    @State private var showingProfiles = false
    @State private var setupPresentation = PermissionSetupPresentation()

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Section(.inputCategories) {
                    Label(.allKeyboards, systemImage: "keyboard").tag(MainDestination.input(.allKeyboards))
                    Label(.allMice, systemImage: "computermouse").tag(MainDestination.input(.allMice))
                    Label(.builtInTrackpad, systemImage: "rectangle.and.hand.point.up.left").tag(MainDestination.input(.builtInTrackpad))
                }
                Section(.plannedInputs) {
                    Label(.magicMouseNotAvailable, systemImage: "computermouse").disabled(true)
                }.foregroundStyle(.secondary)
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 12) {
                    Divider()
                    Button(.settingsTitle, systemImage: "gearshape") { selection = .settings(.general) }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .buttonStyle(.borderless)
                        .padding(12)
                        .background(isShowingSettings ? Color.accentColor.opacity(0.15) : .clear,
                                    in: .rect(cornerRadius: 8))
                }.padding(16)
            }
            .navigationSplitViewColumnWidth(min: 232, ideal: 232)
        } detail: {
            switch selection {
            case .input(let scope): bindingsView(scope: scope)
            case .settings: SettingsView(model: model, selection: settingsSection)
            }
        }.frame(minWidth: 880, minHeight: 600)
        .sheet(item: $setupPresentation.context) { context in
            PermissionSetupView(model: model, context: context)
        }
        .sheet(item: $editor) { selection in
            BindingEditor(model: model, scope: selection.scope, existing: selection.binding)
        }
        .sheet(isPresented: $showingDiagnostics) { InputDiagnosticsView(model: model) }
        .sheet(isPresented: $showingProfiles) { ProfileManagerView(model: model) }
        .onChange(of: model.configuration.selectedProfileID) {
            editor = nil
            pendingDeletion = nil
        }
        .onAppear {
            setupPresentation.beginIfNeeded(needsSetup: model.needsPermissionSetup)
        }
        .onChange(of: model.permissions.allowsRemapping) { wasAllowed, isAllowed in
            // Recover once while idle. Active editors and later revocations keep the inline notice.
            setupPresentation.permissionsChanged(wasAllowed: wasAllowed, isAllowed: isAllowed,
                canPresent: NSApp.isActive && editor == nil && pendingDeletion == nil
                    && !showingProfiles && !showingDiagnostics)
        }
        .alert(.deleteBinding, isPresented: deletionPresented) {
            Button(.cancel, role: .cancel) { pendingDeletion = nil }
            Button(.deleteBinding, role: .destructive) {
                if let binding = pendingDeletion { model.delete(binding.id) }
                pendingDeletion = nil
            }
        } message: { Text(.deleteBindingConfirmation) }
    }

    private func bindingsView(scope: DeviceScope) -> some View {
        VStack(spacing: 0) {
            HStack {
                ProfilePicker(model: model).frame(maxWidth: 300)
                Button(.manageProfiles, systemImage: "slider.horizontal.3") { showingProfiles = true }
                    .disabled(model.storageLocked)
                Spacer()
            }.padding(.horizontal, 20).padding(.top, 16)
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(scope.title).font(.title2.bold())
                    Text(model.statusText).foregroundStyle(.secondary)
                }
                Spacer()
                Button(model.configuration.isEnabled ? LocalizedStringResource.pauseBindings : .resumeBindings) {
                    model.setEnabled(!model.configuration.isEnabled)
                }.disabled(model.storageLocked && !model.configuration.isEnabled)
                Button(.addBinding, systemImage: "plus") { editor = EditorSelection(scope: scope, binding: nil) }.disabled(model.storageLocked)
            }.padding(20)
            if scope == .builtInTrackpad {
                Text(model.trackpadStatus.text).font(.caption).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20).padding(.bottom, 12)
            }
            Divider()
            if !model.permissions.allowsRemapping {
                PermissionRecoveryBanner(model: model) { selection = .settings(.permissions) }
                    .padding(.horizontal, 28).padding(.vertical, 16)
            }
            if let error = model.error { Text(error).foregroundStyle(.red).padding() }
            List {
                ForEach(model.configuration.bindings.filter { $0.scope == scope }) { binding in
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(InputLabels.trigger(binding.trigger, modifiers: binding.modifiers)).font(.headline)
                            if binding.activation == .doublePress { Text(.doublePressActivation).font(.caption) }
                            if binding.activation == .hold {
                                Text(.holdDuration(Int(binding.holdDurationMilliseconds))).font(.caption)
                            }
                            Text("→ " + binding.action.label).foregroundStyle(.secondary)
                            if !ActionKind(action: binding.action).isAvailable(with: model.audioCapabilities) {
                                Text(ActionKind(action: binding.action).unavailableMessage).font(.caption).foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        Spacer()
                        Button(binding.isEnabled ? LocalizedStringResource.disableBinding : .enableBinding,
                               systemImage: binding.isEnabled ? "checkmark.circle.fill" : "circle") { model.toggle(binding) }
                            .labelStyle(.iconOnly).disabled(model.storageLocked)
                        Button(.editBinding, systemImage: "pencil") { editor = EditorSelection(scope: scope, binding: binding) }
                            .labelStyle(.iconOnly).disabled(model.storageLocked)
                        Button(.deleteBinding, systemImage: "trash", role: .destructive) { pendingDeletion = binding }
                            .labelStyle(.iconOnly).disabled(model.storageLocked)
                    }.padding(.vertical, 6)
                }
            }.overlay {
                if model.configuration.bindings.allSatisfy({ $0.scope != scope }) {
                    ContentUnavailableView(.noBindings, systemImage: scope.symbol, description: Text(.addBindingHint))
                }
            }
            Divider()
            VStack(alignment: .leading, spacing: 5) {
                if scope != .builtInTrackpad { Text(.phaseOneHint) }
                if model.workspaceActionInProgress { Text(.openingTargetStatus) }
                if model.appleShortcutInProgress { Text(.runningAppleShortcutStatus) }
                Text(.emergencyHint)
                if scope == .builtInTrackpad { Text(.trackpadTapHint) }
                else { Text(.deviceScopeHint) }
                if scope == .allMice { Text(.wheelMappingHint) }
                Button(.inputDiagnostics, systemImage: "waveform.path") { showingDiagnostics = true }
            }.font(.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .leading).padding(16)
        }.navigationTitle("Rebind")
    }

    private var deletionPresented: SwiftUI.Binding<Bool> {
        SwiftUI.Binding(get: { pendingDeletion != nil }, set: { if !$0 { pendingDeletion = nil } })
    }

    private var isShowingSettings: Bool {
        if case .settings = selection { return true }
        return false
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
}
