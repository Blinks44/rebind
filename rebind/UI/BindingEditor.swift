import SwiftUI

struct BindingEditor: View {
    let model: AppModel
    let scope: DeviceScope
    let existing: Binding?
    private let profileID: UUID
    private let configurationRevision: UInt64
    @Environment(\.dismiss) private var dismiss
    @State private var draft: BindingEditorDraft
    @State private var recordingRequest: RecordingRequest?
    @State private var showingPermissions = false
    @State private var actionKind: ActionKind
    @State private var application: ApplicationTarget?
    @State private var webAddress: String
    @State private var file: URL?
    @State private var appleShortcut: AppleShortcutTarget?

    init(model: AppModel, scope: DeviceScope, existing: Binding?) {
        self.model = model
        self.scope = scope
        self.existing = existing
        profileID = model.configuration.selectedProfileID
        configurationRevision = model.configurationReplacementRevision
        _draft = State(initialValue: BindingEditorDraft(scope: scope, existing: existing))
        _actionKind = State(initialValue: existing.map { ActionKind(action: $0.action) } ?? .keyboardShortcut)
        let workspace: WorkspaceAction?
        if case .workspace(let value) = existing?.action { workspace = value } else { workspace = nil }
        _application = State(initialValue: workspace?.application)
        if case .openURL(let url) = workspace { _webAddress = State(initialValue: url.absoluteString) }
        else { _webAddress = State(initialValue: "") }
        if case .openFile(let url) = workspace { _file = State(initialValue: url) }
        else { _file = State(initialValue: nil) }
        if case .appleShortcut(let target) = existing?.action { _appleShortcut = State(initialValue: target) }
        else { _appleShortcut = State(initialValue: nil) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(existing == nil ? LocalizedStringResource.addBinding : .editBinding).font(.title2.bold())
                if scope == .allMice {
                    Text(.mouseEditorScope(model.configuration.selectedProfile?.title ?? ""))
                        .foregroundStyle(.secondary)
                } else {
                    Text(scope == .builtInTrackpad ? LocalizedStringResource.trackpadTapHint : .recordingLimitations)
                        .foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                }
                if scope == .allMice {
                    MouseTriggerEditor(draft: $draft, model: model, record: { record(draft.mouseTarget) })
                } else {
                    GroupBox {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(.triggerTitle).font(.headline)
                            if scope == .allKeyboards {
                                Text(.activationTitle).font(.caption).foregroundStyle(.secondary)
                                Picker(.activationTitle, selection: $draft.activation) {
                                    Text(.pressActivation).tag(PressActivation.press)
                                    Text(.doublePressActivation).tag(PressActivation.doublePress)
                                    Text(.holdActivation).tag(PressActivation.hold)
                                }.pickerStyle(.segmented).labelsHidden()
                                if draft.activation == .doublePress {
                                    Text(.doublePressHint).font(.caption).foregroundStyle(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                if draft.activation == .hold {
                                    HoldDurationRow(milliseconds: $draft.holdDurationMilliseconds)
                                    Text(.holdHint).font(.caption).foregroundStyle(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            Text(draft.trigger.map { InputLabels.trigger($0.trigger, modifiers: $0.modifiers) } ?? AppLocalization.string(.notRecorded)).font(.title3.monospaced())
                            if scope != .builtInTrackpad {
                                Button(.recordTrigger) { record(scope == .allKeyboards ? .keyboardTrigger : draft.mouseTarget) }
                                    .disabled(!model.canRecord || model.recording != nil)
                            }
                        }.frame(maxWidth: .infinity, alignment: .leading).padding(8)
                    }
                }
                BindingEditorSection(usesCard: scope != .allMice) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(.actionTitle).font(.headline)
                        if scope == .builtInTrackpad {
                            Text(.outputShortcut)
                        } else { ActionPickerView(model: model, selection: $actionKind) }
                        if actionKind == .keyboardShortcut {
                            if scope == .allMice {
                                BindingCaptureField(value: draft.output.map(InputLabels.shortcut), target: .output,
                                    recording: model.recording, canRecord: model.canRecord,
                                    record: { record(.output) }, cancel: model.cancelRecording,
                                    clear: { draft.output = nil })
                                Text(.mouseOutputHelp).font(.caption).foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            } else {
                                Text(draft.output.map(InputLabels.shortcut) ?? AppLocalization.string(.notRecorded)).font(.title3.monospaced())
                                Button(.recordOutput) { record(.output) }.disabled(!model.canRecord || model.recording != nil)
                            }
                        } else if actionKind.mouseAction != nil {
                            Text(.mouseActionHint).font(.caption).foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        } else if actionKind.windowLayoutAction != nil {
                            Text(.windowLayoutHint).font(.caption).foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        } else if actionKind.mediaAction != nil {
                            Text(.mediaActionHint).font(.caption).foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        } else if let desktop = actionKind.desktopAction {
                            if desktop.dockNotification != nil {
                                Text(.dockActionHint).font(.caption).foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                                if !actionKind.isAvailable(with: model.audioCapabilities) {
                                    Text(.dockActionUnavailable).foregroundStyle(.secondary)
                                }
                            } else {
                                Text(.spaceActionHint).font(.caption).foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                                if !actionKind.isAvailable(with: model.audioCapabilities) {
                                    Text(.spaceActionUnavailable).foregroundStyle(.secondary)
                                }
                            }
                        } else if actionKind == .previousApplication {
                            Text(.previousApplicationHint).font(.caption).foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        } else if actionKind.windowCycleAction != nil {
                            Text(.windowCycleHint).font(.caption).foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        } else if actionKind == .lockScreen {
                            Text(.lockScreenHint).font(.caption).foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                            if !actionKind.isAvailable(with: model.audioCapabilities) {
                                Text(.lockScreenUnavailable).font(.caption).foregroundStyle(.secondary)
                            }
                        } else if actionKind == .sleepSystem {
                            Text(.sleepSystemHint).font(.caption).foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                            if !actionKind.isAvailable(with: model.audioCapabilities) {
                                Text(.sleepSystemUnavailable).font(.caption).foregroundStyle(.secondary)
                            }
                        } else if actionKind == .openSystemSettings {
                            Text(.openSystemSettingsHint).font(.caption).foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        } else if actionKind == .runAppleShortcut {
                            AppleShortcutParameters(target: $appleShortcut).disabled(model.recording != nil)
                        } else if actionKind.needsWorkspaceParameters {
                            WorkspaceActionParameters(kind: actionKind, application: $application, webAddress: $webAddress, file: $file)
                                .disabled(model.recording != nil)
                        } else {
                            Text(actionKind.windowAction == nil ? LocalizedStringResource.audioActionHint : .windowActionHint).font(.caption).foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                            if !actionKind.isAvailable(with: model.audioCapabilities) {
                                Text(.audioActionUnavailable).foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }.frame(maxWidth: .infinity, alignment: .leading).padding(scope == .allMice ? 0 : 8)
                }
                if model.recording != nil && scope != .allMice {
                    HStack {
                        Label(.listeningHint, systemImage: "record.circle").foregroundStyle(.tint)
                        Spacer()
                        Button(.cancelRecording) { model.cancelRecording() }
                    }
                }
                if !model.canRecord {
                    Text(recordingUnavailableHint).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    if !model.permissions.allowsRemapping {
                        Button(.mouseOpenPermissions) { model.cancelRecording(); showingPermissions = true }
                    }
                }
                switch model.status {
                case .tapFailed, .interrupted, .outputFailed, .secureInput:
                    Text(model.status.text).foregroundStyle(.secondary)
                default: EmptyView()
                }
                if let error = model.error {
                    if error == .storageWriteFailed {
                        PermissionCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(.bindingSaveFailed).font(.headline)
                                Text(.bindingSaveFailedDescription).foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    } else { Text(error).foregroundStyle(.red) }
                }
                if validationError == .conflict {
                    PermissionCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(.mouseTriggerConflict(model.configuration.selectedProfile?.title ?? ""))
                                .font(.headline)
                            Text(.mouseConflictHelp).foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                } else if validationError != nil { Text(.bindingInvalid).foregroundStyle(.red) }
            }.padding(24)
        }.safeAreaInset(edge: .bottom, spacing: 0) {
            HStack {
                if scope != .allMice {
                    Button(.clearRecording) {
                        model.cancelRecording()
                        draft = BindingEditorDraft(scope: scope, existing: nil)
                        actionKind = .keyboardShortcut
                        application = nil; webAddress = ""; file = nil; appleShortcut = nil
                    }
                }
                Spacer()
                Button(.cancel) { model.cancelRecording(); dismiss() }
                    .accessibilityIdentifier("binding-editor-cancel")
                Button(.saveBinding, action: save).keyboardShortcut(.defaultAction)
                    .accessibilityIdentifier("binding-editor-save")
                    .buttonStyle(.borderedProminent)
                    .disabled(candidate == nil || validationError != nil
                        || !actionKind.isAvailable(with: model.audioCapabilities)
                        || model.recording != nil || model.storageLocked)
            }.padding(24).background(Color(.permissionCanvasBottom))
        }.frame(width: scope == .allMice ? 512 : 540).frame(idealHeight: 640, maxHeight: 760)
        .background { PermissionCanvas() }
        .onExitCommand { if model.recording != nil { model.cancelRecording() } else { dismiss() } }
        .sheet(isPresented: $showingPermissions) { PermissionSetupView(model: model, context: .recovery) }
        .onAppear { model.error = nil; model.beginEditing() }
        .onDisappear { model.endEditing() }
        .onChange(of: model.configurationReplacementRevision) { dismiss() }
        .onChange(of: draft.mouseTarget) {
            model.cancelRecording()
            recordingRequest = nil
            draft.selectMouseTarget(draft.mouseTarget)
        }
        .onChange(of: actionKind) { model.cancelRecording() }
        .onChange(of: draft.activation) { model.cancelRecording() }
        .onChange(of: draft.holdDurationMilliseconds) { model.cancelRecording() }
        .onChange(of: draft.pointerDirection) { model.cancelRecording() }
        .onChange(of: model.lastRecording?.request.id) {
            guard let recorded = model.lastRecording else { return }
            draft.accept(recorded, for: recordingRequest, scope: scope)
            recordingRequest = nil
        }
        .onChange(of: model.recording?.id) {
            if model.recording == nil, model.lastRecording?.request != recordingRequest {
                recordingRequest = nil
            }
        }
        .onChange(of: validationError) {
            if validationError == .conflict {
                AccessibilityNotification.Announcement(AppLocalization.string(.mouseConflictHelp)).post()
            }
        }
    }

    private var configuredAction: RebindAction? {
        actionKind.configuredAction(shortcut: draft.output, application: application, webAddress: webAddress, file: file,
                                    appleShortcut: appleShortcut)
    }

    private var candidate: Binding? {
        configuredAction.flatMap { draft.binding(scope: scope, action: $0, existing: existing) }
    }

    private var validationError: ConfigurationError? {
        candidate.flatMap { BindingEditorValidation.error(for: $0, in: model.configuration) }
    }

    private var recordingUnavailableHint: LocalizedStringResource {
        if !model.permissions.allowsRemapping { return .mouseRecordingUnavailable }
        return model.recordingUnavailableHint
    }

    private func record(_ target: RecordingTarget) {
        model.beginRecording(target)
        recordingRequest = model.recording
    }

    private func save() {
        guard configurationRevision == model.configurationReplacementRevision else { dismiss(); return }
        guard let candidate, validationError == nil, actionKind.isAvailable(with: model.audioCapabilities) else { return }
        if model.saveBinding(candidate, profileID: profileID) { dismiss() }
    }
}
