import SwiftUI

struct MouseBindingsView: View {
    let model: AppModel
    let add: () -> Void
    let edit: (Binding) -> Void
    let delete: (Binding) -> Void
    let openPermissions: () -> Void
    let diagnostics: () -> Void
    @State private var search = ""

    private var bindings: [Binding] { model.configuration.bindings.filter { $0.scope == .allMice } }
    private var visible: [Binding] { MouseBindingList.matching(bindings, search: search) }
    private var profileName: String { model.configuration.selectedProfile?.title ?? "" }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(.mouseTitle).font(EditorTypography.title).accessibilityAddTraits(.isHeader)
                Text(.mouseScopeDescription(profileName)).foregroundStyle(.secondary)
            }
            HStack(spacing: 16) {
                TextField(.mouseSearchBindings, text: $search).textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 300).accessibilityIdentifier("mouse-search")
                Spacer(minLength: 0)
                Button(.addBinding, systemImage: "plus", action: add)
                    .buttonStyle(.borderedProminent).disabled(model.storageLocked)
            }
            if !model.permissions.allowsRemapping {
                PermissionRecoveryBanner(model: model, reviewPermissions: openPermissions)
            }
            if let error = model.error { Text(error).foregroundStyle(.red) }
            HStack(spacing: 16) {
                Text(.triggerTitle).frame(maxWidth: .infinity, alignment: .leading)
                Color.clear.frame(width: 16, height: 1)
                Text(.actionTitle).frame(maxWidth: .infinity, alignment: .leading)
                Text(.mouseEnabledTitle).frame(width: 48)
                Color.clear.frame(width: 24, height: 1)
            }.font(.caption).foregroundStyle(.secondary).padding(.horizontal, 16)
                .accessibilityHidden(true)
            List {
                ForEach(visible) { binding in
                    MouseBindingRow(binding: binding, model: model,
                        edit: { edit(binding) }, delete: { delete(binding) })
                        .listRowBackground(Color(.permissionSurface))
                }
            }.listStyle(.inset).scrollContentBackground(.hidden)
                .overlay {
                    if visible.isEmpty {
                        ContentUnavailableView {
                            Label(bindings.isEmpty ? LocalizedStringResource.mouseNoBindings(profileName) : .mouseNoMatches,
                                  systemImage: bindings.isEmpty ? "computermouse" : "magnifyingglass")
                        } description: {
                            Text(bindings.isEmpty ? LocalizedStringResource.mouseEmptyHelp : .mouseSearchHelp)
                        } actions: {
                            if bindings.isEmpty {
                                Button(.addBinding, action: add).disabled(model.storageLocked)
                            } else { Button(.mouseClearSearch) { search = "" } }
                        }
                    }
                }
            HStack(spacing: 12) {
                Button(model.configuration.isEnabled ? LocalizedStringResource.pauseBindings : .resumeBindings) {
                    model.setEnabled(!model.configuration.isEnabled)
                }.disabled(model.storageLocked && !model.configuration.isEnabled)
                Text(model.statusText).foregroundStyle(.secondary)
                Spacer(minLength: 0)
                VStack(alignment: .trailing, spacing: 4) {
                    if search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(.mouseBindingCount(bindings.count))
                        Text(.mouseEnabledCount(bindings.filter(\.isEnabled).count))
                    } else { Text(.mouseVisibleBindingCount(visible.count, bindings.count)) }
                }.foregroundStyle(.secondary)
                Button(.inputDiagnostics, systemImage: "waveform.path", action: diagnostics)
                    .labelStyle(.iconOnly)
            }.font(.caption).help(Text(.emergencyHint))
        }.padding(.horizontal, 28).padding(.top, 32).padding(.bottom, 20)
            .background { PermissionCanvas() }
            .onChange(of: model.configuration.selectedProfileID) { search = "" }
    }
}
