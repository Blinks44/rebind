import AppKit
import SwiftUI

struct StarterSetupsView: View {
    let model: AppModel
    private let existingProfileID: UUID
    @State private var setup: StarterSetup?
    @State private var selectedIDs: Set<String>
    @State private var useExisting: Bool
    @State private var name: String
    @State private var safari: ApplicationTarget?
    @State private var notice: LocalizedStringResource?
    @State private var result: StarterSetupResult?
    @Environment(\.dismiss) private var dismiss

    init(
        model: AppModel, initialSetup: StarterSetup? = nil, initialDestinationID: UUID? = nil,
        safari: ApplicationTarget? = StarterSetupAvailability.safari()
    ) {
        self.model = model
        existingProfileID = initialDestinationID ?? model.configuration.selectedProfileID
        _useExisting = State(initialValue: initialDestinationID != nil)
        _setup = State(initialValue: initialSetup)
        _selectedIDs = State(initialValue: Set(initialSetup?.entries(safari: safari).map(\.id) ?? []))
        _name = State(initialValue: initialSetup.map { model.starterProfileName(AppLocalization.string($0.title)) } ?? "")
        _safari = State(initialValue: safari)
    }

    var body: some View {
        Group {
            if let result { completion(result) } else if let setup { preview(setup) } else { catalog }
        }
        .frame(width: result == nil ? 680 : 560)
        .frame(idealHeight: result == nil ? 600 : 360, maxHeight: result == nil ? 600 : 360)
        .background(Theme.sheetSurface)
        .onAppear { model.beginEditing() }
        .onDisappear { model.endEditing() }
        .onChange(of: model.configuration.selectedProfileID) { if result == nil { dismiss() } }
        .onChange(of: model.configurationReplacementRevision) { dismiss() }
        .onChange(of: selectedIDs) { notice = nil }
        .onChange(of: useExisting) { notice = nil }
        .onChange(of: name) { notice = nil }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            safari = StarterSetupAvailability.safari()
        }
    }

    private var catalog: some View {
        VStack(alignment: .leading, spacing: 0) {
            heading(.starterTitle, subtitle: .starterCatalogHint)
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(StarterSetup.allCases) { setup in
                        Button {
                            choose(setup)
                        } label: {
                            Card(cornerRadius: 16) {
                                HStack(spacing: 20) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(setup.title).font(Theme.headline).foregroundStyle(Theme.textPrimary)
                                        Text(setup.summary).font(Theme.callout).foregroundStyle(Theme.textSecondary)
                                    }.frame(maxWidth: .infinity, alignment: .leading)
                                    Image(systemName: "chevron.right").foregroundStyle(Theme.iconSecondary).accessibilityHidden(true)
                                }.frame(minHeight: 40)
                            }
                        }.buttonStyle(.plain).keyboardFocusRing()
                    }
                    Text(.starterOfflineHint).font(Theme.callout).foregroundStyle(Theme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading).padding(.top, 12)
                }.padding(.horizontal, 28).padding(.vertical, 20)
            }
            HStack {
                Text(.starterSelectionUnchanged).font(Theme.callout).foregroundStyle(Theme.textSecondary)
                Spacer(minLength: 16)
                Button(.diagnosticsClose) { dismiss() }.secondaryButton().keyboardShortcut(.cancelAction)
            }.padding(28)
        }
    }

    private func preview(_ setup: StarterSetup) -> some View {
        let review = StarterSetupReview(
            setup: setup, selectedIDs: selectedIDs, destinationID: useExisting ? existingProfileID : nil,
            configuration: model.configuration, safari: safari)
        let revision = model.configurationReplacementRevision
        let canInstall =
            !model.storageLocked && !review.additions.isEmpty
            && (useExisting
                || (model.configuration.profiles.count < Configuration.maximumProfiles && model.starterProfileNameIsValid(name)))
        return VStack(alignment: .leading, spacing: 0) {
            heading(setup.title, subtitle: setup.introduction)
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(.starterSelectedCount(review.additions.count)).font(Theme.calloutStrong).foregroundStyle(Theme.textPrimary)
                    VStack(spacing: 8) {
                        ForEach(review.rows) { row in entryRow(row) }
                    }
                    destination
                    if !useExisting {
                        HStack(spacing: 16) {
                            Text(.profileName).font(Theme.calloutStrong).frame(width: 96, alignment: .leading)
                            ThemeTextField(title: .profileName, text: $name).frame(maxWidth: 360)
                            Spacer(minLength: 0)
                        }
                        Text(.starterSelectionUnchanged).font(Theme.callout).foregroundStyle(Theme.textSecondary)
                        if !model.starterProfileNameIsValid(name) { feedback(.profileInvalid, isError: true) }
                        if model.configuration.profiles.count >= Configuration.maximumProfiles { feedback(.profileLimit, isError: true) }
                    } else {
                        if existingProfileID == model.configuration.selectedProfileID, model.configuration.isEnabled {
                            feedback(.starterActiveProfileWarning, isError: false)
                        }
                        Text(.starterExistingKept).font(Theme.callout).foregroundStyle(Theme.textSecondary)
                    }
                    if review.skippedCount > 0 {
                        feedback(.starterSkippedCount(review.skippedCount), isError: false)
                    }
                    if setup == .browser && safari == nil { feedback(.starterMissingSafari, isError: false) }
                    if setup == .magicMouse { feedback(.starterConnectMagicMouse, isError: false) }
                    if setup != .windows || model.permissions.allowsRemapping {
                        Text(setup.guidance).font(Theme.callout).foregroundStyle(Theme.textSecondary)
                    }
                    if !model.permissions.allowsRemapping { feedback(.starterAccessHint, isError: false) }
                    if review.additions.isEmpty {
                        Text(review.skippedCount == review.rows.count ? .starterNothingNew : .starterChooseBinding)
                            .font(Theme.callout).foregroundStyle(Theme.textSecondary)
                    }
                    if model.storageLocked {
                        feedback(.storageUnreadable, isError: true)
                    } else if let notice {
                        feedback(notice, isError: true)
                    }
                }.padding(.horizontal, 28).padding(.vertical, 20)
            }
            HStack(spacing: 12) {
                Button(.starterBack) {
                    self.setup = nil
                    notice = nil
                }.secondaryButton()
                Button(.cancel) { dismiss() }.secondaryButton().keyboardShortcut(.cancelAction)
                Spacer()
                Button(.starterAddCount(review.additions.count), systemImage: "plus") {
                    if let installed = model.installStarterSetup(review, name: name, expectedRevision: revision) {
                        result = installed
                    } else {
                        notice = model.error ?? .starterSaveFailed
                    }
                }.primaryButton().disabled(!canInstall)
            }.controlSize(.large).padding(.horizontal, 28).padding(.vertical, 20)
        }
    }

    private var destination: some View {
        HStack(alignment: .center, spacing: 16) {
            Text(.starterAddTo).font(Theme.calloutStrong).frame(width: 96, alignment: .leading)
            MenuSelector(
                selection: $useExisting, title: .starterAddTo, choices: [false, true],
                label: { existing in
                    if existing {
                        let profile = model.configuration.profiles.first { $0.id == existingProfileID }
                        return .starterExistingDestination(profile?.title ?? "")
                    }
                    return .starterNewProfile
                },
                isChoiceEnabled: { existing in
                    existing || model.configuration.profiles.count < Configuration.maximumProfiles
                }
            ).frame(maxWidth: 360)
            Spacer(minLength: 0)
        }.foregroundStyle(Theme.textPrimary)
    }

    private func entryRow(_ row: StarterSetupReview.Row) -> some View {
        let binding = row.entry.binding
        let available = row.availability == .available
        return Card(insets: EdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20), cornerRadius: 12) {
            Toggle(
                isOn: SwiftUI.Binding(
                    get: { available && selectedIDs.contains(row.id) },
                    set: { selected in
                        if selected { selectedIDs.insert(row.id) } else { selectedIDs.remove(row.id) }
                    })
            ) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .top, spacing: 16) {
                        Text(InputLabels.trigger(binding.trigger, modifiers: binding.modifiers))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(binding.action.label).frame(maxWidth: .infinity, alignment: .leading)
                    }.font(Theme.bodyStrong).foregroundStyle(Theme.textPrimary)
                    Text(scopeLabel(binding)).font(Theme.callout).foregroundStyle(Theme.textSecondary)
                    switch row.availability {
                    case .alreadyAdded: Text(.starterAlreadyAdded).font(Theme.callout).foregroundStyle(Theme.textSecondary)
                    case .conflict(let used):
                        Text(
                            .starterConflictWith(
                                used.action.label, used.application?.displayName ?? AppLocalization.string(.bindingAllApps))
                        )
                        .font(Theme.callout).foregroundStyle(Theme.warningText)
                    case .missingApplication: Text(.starterTargetUnavailable).font(Theme.callout).foregroundStyle(Theme.warningText)
                    case .available: EmptyView()
                    }
                }.padding(.leading, 12).frame(maxWidth: .infinity, alignment: .leading)
            }.toggleStyle(.checkbox).disabled(!available || model.storageLocked)
        }
    }

    private func scopeLabel(_ binding: Binding) -> String {
        AppLocalization.string(binding.scope.title) + " · "
            + (binding.application.map { AppLocalization.string(.bindingOnlyInApp($0.displayName)) }
                ?? AppLocalization.string(.bindingAllApps))
    }

    private func completion(_ result: StarterSetupResult) -> some View {
        let title = model.configuration.profiles.first { $0.id == result.profileID }?.title ?? ""
        return VStack(alignment: .leading, spacing: 24) {
            Text(.starterAddedTitle).font(Theme.titleSmall).foregroundStyle(Theme.textPrimary).accessibilityAddTraits(.isHeader)
            Text(.starterAddedResult(result.addedCount, title)).font(Theme.body).foregroundStyle(Theme.textPrimary)
            if result.createdProfile { Text(.starterSelectionUnchanged).font(Theme.body).foregroundStyle(Theme.textSecondary) }
            Spacer(minLength: 0)
            if let notice { feedback(notice, isError: true) }
            HStack {
                Button(.starterDone) { dismiss() }.secondaryButton().keyboardShortcut(.cancelAction)
                Spacer()
                if model.configuration.selectedProfileID != result.profileID {
                    Button(.selectProfile) {
                        if model.selectProfile(result.profileID) { dismiss() } else { notice = model.error }
                    }.primaryButton().disabled(model.storageLocked)
                }
            }
        }.padding(28)
    }

    private func heading(_ title: LocalizedStringResource, subtitle: LocalizedStringResource) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(Theme.titleSmall).foregroundStyle(Theme.textPrimary).accessibilityAddTraits(.isHeader)
            Text(subtitle).font(Theme.body).foregroundStyle(Theme.textSecondary)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 28).padding(.top, 26)
    }

    private func feedback(_ text: LocalizedStringResource, isError: Bool) -> some View {
        Text(text).font(Theme.callout).foregroundStyle(isError ? Theme.dangerText : Theme.warningText)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func choose(_ setup: StarterSetup) {
        self.setup = setup
        selectedIDs = Set(setup.entries(safari: safari).map(\.id))
        name = model.starterProfileName(AppLocalization.string(setup.title))
        useExisting = false
        notice = nil
    }
}
