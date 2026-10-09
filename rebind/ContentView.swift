import SwiftUI

struct ContentView: View {
    let model: AppModel
    @State private var selection: DeviceScope = .allKeyboards
    @State private var editor: EditorSelection?
    @State private var pendingDeletion: Binding?
    @State private var showingDiagnostics = false
    @State private var showingProfiles = false

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Section(.inputCategories) {
                    Label(.allKeyboards, systemImage: "keyboard").tag(DeviceScope.allKeyboards)
                    Label(.allMice, systemImage: "computermouse").tag(DeviceScope.allMice)
                }
                Section(.plannedInputs) {
                    Label(.trackpadNotAvailable, systemImage: "rectangle.and.hand.point.up.left").disabled(true)
                    Label(.magicMouseNotAvailable, systemImage: "computermouse").disabled(true)
                }.foregroundStyle(.secondary)
            }.navigationSplitViewColumnWidth(min: 180, ideal: 220)
        } detail: {
            bindingsView(scope: selection)
        }.frame(minWidth: 850, minHeight: 560)
        .sheet(item: $editor) { selection in
            BindingEditor(model: model, scope: selection.scope, existing: selection.binding)
        }
        .sheet(isPresented: $showingDiagnostics) { InputDiagnosticsView(model: model) }
        .sheet(isPresented: $showingProfiles) { ProfileManagerView(model: model) }
        .onChange(of: model.configuration.selectedProfileID) {
            editor = nil
            pendingDeletion = nil
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
                    Text(scope == .allKeyboards ? LocalizedStringResource.allKeyboards : .allMice).font(.title2.bold())
                    Text(model.statusText).foregroundStyle(.secondary)
                }
                Spacer()
                Button(model.configuration.isEnabled ? LocalizedStringResource.pauseBindings : .resumeBindings) {
                    model.setEnabled(!model.configuration.isEnabled)
                }.disabled(model.storageLocked && !model.configuration.isEnabled)
                Button(.addBinding, systemImage: "plus") { editor = EditorSelection(scope: scope, binding: nil) }.disabled(model.storageLocked)
            }.padding(20)
            Divider()
            if !model.canRecord { PermissionView(model: model); Divider() }
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
                            if !model.audioCapabilities.supports(binding.action) {
                                Text(.audioActionUnavailable).font(.caption).foregroundStyle(.secondary)
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
                    ContentUnavailableView(.noBindings, systemImage: scope == .allKeyboards ? "keyboard" : "computermouse", description: Text(.addBindingHint))
                }
            }
            Divider()
            VStack(alignment: .leading, spacing: 5) {
                Text(.phaseOneHint)
                if model.workspaceActionInProgress { Text(.openingTargetStatus) }
                if model.appleShortcutInProgress { Text(.runningAppleShortcutStatus) }
                Text(.emergencyHint)
                Text(.deviceScopeHint)
                if scope == .allMice { Text(.wheelMappingHint) }
                Button(.inputDiagnostics, systemImage: "waveform.path") { showingDiagnostics = true }
            }.font(.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .leading).padding(16)
        }.navigationTitle("Rebind")
    }

    private var deletionPresented: SwiftUI.Binding<Bool> {
        SwiftUI.Binding(get: { pendingDeletion != nil }, set: { if !$0 { pendingDeletion = nil } })
    }
}

private struct EditorSelection: Identifiable {
    let id = UUID()
    let scope: DeviceScope
    var binding: Binding?
}
