import SwiftUI

/// Main detail for one input category: header, profile and status row, then the rules card.
struct BindingsView: View {
    let model: AppModel
    let scope: DeviceScope
    let add: () -> Void
    let edit: (Binding) -> Void
    let delete: (Binding) -> Void
    let manageProfiles: () -> Void
    let openPermissions: () -> Void
    @State private var search = ""
    @FocusState private var searchFocused: Bool

    private var bindings: [Binding] { model.configuration.bindings.filter { $0.scope == scope } }
    private var visible: [Binding] { bindings.filter { MouseBindingList.matches($0, search: search) } }

    private var title: LocalizedStringResource {
        switch scope {
        case .allKeyboards: LocalizedStringResource("keyboardNavigationTitle", table: "Navigation")
        case .allMice: .mouseTitle
        case .builtInTrackpad: LocalizedStringResource("trackpadNavigationTitle", table: "Navigation")
        }
    }

    private var subtitle: LocalizedStringResource {
        switch scope {
        case .allKeyboards: .keyboardSubtitle
        case .allMice: .mouseSubtitle
        case .builtInTrackpad: .trackpadSubtitle
        }
    }

    private var statusKind: StatusPill.Kind {
        if !model.permissions.allowsRemapping { return .attention }
        if !model.configuration.isEnabled { return .paused }
        switch model.status {
        case .active: return .on
        case .paused, .secureInput: return .paused
        case .permissionRequired: return .attention
        case .tapFailed, .interrupted, .outputFailed: return .error
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            summary
            // An empty ScrollView collapses to its content width; keep it as wide as the detail.
            ScrollView {
                if !visible.isEmpty { card.padding(.top, 24).padding(.leading, 32).padding(.trailing, 40).padding(.bottom, 32) }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay { if visible.isEmpty { emptyState } }
        }
        .onChange(of: model.configuration.selectedProfileID) { search = "" }
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 0) {
            header.padding(.top, 56)
            statusRow.padding(.top, 30)
            if !model.permissions.allowsRemapping {
                PermissionRecoveryBanner(model: model, reviewPermissions: openPermissions).padding(.top, 24)
            }
            if let error = model.error {
                Text(error).font(Theme.callout).foregroundStyle(Theme.dangerText).padding(.top, 12)
            }
        }
        .padding(.leading, 32).padding(.trailing, 40)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title).font(Theme.largeTitle).foregroundStyle(Theme.textPrimary)
                    .lineLimit(1).frame(height: 36).accessibilityAddTraits(.isHeader)
                Text(subtitle).font(Theme.body).foregroundStyle(Theme.textSecondary).lineLimit(2)
            }
            Spacer(minLength: 12)
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass").font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.iconSecondary).accessibilityHidden(true)
                TextField(text: $search, prompt: Text(.mouseSearchBindings).foregroundStyle(Theme.textTertiary)) {
                    Text(.mouseSearchBindings)
                }.textFieldStyle(.plain).font(Theme.body).foregroundStyle(Theme.textPrimary)
                    .focused($searchFocused).focusEffectDisabled()
                    .accessibilityIdentifier("bindings-search")
            }
            .padding(.horizontal, 14).frame(height: Theme.controlHeight)
            .frame(minWidth: 140, idealWidth: 220, maxWidth: 220)
            .modifier(ControlSurface(isFocused: searchFocused))
            Button(action: add) {
                HStack(spacing: 8) {
                    Image(systemName: "plus").font(.system(size: 12, weight: .heavy))
                    Text(.addBinding).lineLimit(1)
                }
            }
            .buttonStyle(PrimaryButtonStyle()).keyboardFocusRing().fixedSize().disabled(model.storageLocked)
        }
    }

    private var statusRow: some View {
        HStack(spacing: 16) {
            Menu {
                ProfilePicker(model: model).pickerStyle(.inline).labelsHidden()
                Divider()
                Button(.manageProfiles, action: manageProfiles)
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "square.on.square").font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.accent).frame(width: 16)
                    Text(verbatim: model.configuration.selectedProfile?.title ?? "")
                        .font(Theme.bodyStrong).foregroundStyle(Theme.textPrimary).lineLimit(1)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.up.chevron.down").font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Theme.iconSecondary)
                }
                .padding(.leading, 14).padding(.trailing, 16)
                .frame(width: 196, height: Theme.controlHeight).contentShape(.capsule)
            }
            .menuStyle(.button).buttonStyle(.plain).menuIndicator(.hidden).fixedSize()
            .modifier(ControlSurface())
            .keyboardFocusRing()
            .disabled(model.storageLocked)
            .accessibilityLabel(Text(.profileTitle))
            .accessibilityIdentifier("bindings-profile")

            Text("\(AppLocalization.string(.mouseBindingCount(bindings.count))), \(AppLocalization.string(.mouseEnabledCount(bindings.filter(\.isEnabled).count)))")
                .font(Theme.callout).foregroundStyle(Theme.textSecondary).lineLimit(1)
            Spacer(minLength: 0)
            Button {
                if model.permissions.allowsRemapping { model.setEnabled(!model.configuration.isEnabled) } else { openPermissions() }
            } label: { StatusPill(kind: statusKind) }
                .buttonStyle(.plain)
                .keyboardFocusRing()
                .disabled(model.storageLocked && !model.configuration.isEnabled)
                .help(Text("\(Text(model.statusText))\n\(Text(.emergencyHint))"))
                .accessibilityValue(Text(model.statusText))
        }
    }

    private var card: some View {
        VStack(spacing: 0) {
            ForEach(visible) { binding in
                BindingRow(binding: binding, model: model, edit: { edit(binding) }, delete: { delete(binding) })
                    .overlay(alignment: .top) {
                        if binding.id != visible.first?.id {
                            Theme.separator.frame(height: 1).padding(.horizontal, 20)
                        }
                    }
            }
        }
        .background {
            RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous).fill(Theme.cardSurface)
                .shadow(color: Theme.shadowAmbient, radius: 0.5, y: 1)
                .shadow(color: Theme.shadowAmbient, radius: 16, y: 12)
        }
        .overlay {
            RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous).strokeBorder(Theme.borderSubtle)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 0) {
            Image(systemName: bindings.isEmpty ? scope.symbol : "magnifyingglass")
                .font(.system(size: 24, weight: .medium)).foregroundStyle(Theme.accent)
                .frame(width: 56, height: 56)
                .background(Theme.accentTint, in: .rect(cornerRadius: 18, style: .continuous))
                .accessibilityHidden(true)
            Text(bindings.isEmpty ? LocalizedStringResource.noBindings : .mouseNoMatches)
                .font(.system(size: 17, weight: .semibold)).foregroundStyle(Theme.textPrimary).padding(.top, 20)
            if bindings.isEmpty {
                Text(.addBindingHint).font(Theme.body).foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center).frame(maxWidth: 420).padding(.top, 8)
                Button(action: add) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus").font(.system(size: 12, weight: .heavy))
                        Text(.addBinding)
                    }
                }.buttonStyle(PrimaryButtonStyle()).keyboardFocusRing().disabled(model.storageLocked).padding(.top, 24)
            } else {
                Button(.mouseClearSearch) { search = "" }.buttonStyle(.plain)
                    .font(Theme.bodyStrong).foregroundStyle(Theme.accent).padding(.top, 20)
            }
        }
        .padding(.horizontal, 40)
    }
}
