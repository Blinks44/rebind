import SwiftUI

struct InputDiagnosticsView: View {
    let model: AppModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(.inputDiagnostics).font(Theme.titleSmall).accessibilityAddTraits(.isHeader)
            Text(.advancedDiagnosticsPrivacy).foregroundStyle(Theme.textSecondary).fixedSize(horizontal: false, vertical: true)
            HStack {
                Label(model.diagnostics.isRunning ? LocalizedStringResource.advancedDiagnosticsRecording : .advancedDiagnosticsStopped,
                      systemImage: model.diagnostics.isRunning ? "record.circle" : "pause.circle")
                Spacer()
                Button(model.diagnostics.isRunning ? LocalizedStringResource.advancedDiagnosticsStop : .advancedDiagnosticsStart) {
                    if model.diagnostics.isRunning { model.stopDiagnostics() } else { model.startDiagnostics() }
                }.disabled(!model.diagnostics.isRunning && !model.canStartDiagnostics).secondaryButton()
                Button(.advancedDiagnosticsClear) { model.clearDiagnostics() }.disabled(model.diagnostics.entries.isEmpty && model.diagnostics.omitted == 0).secondaryButton()
            }
            if !model.canStartDiagnostics && !model.diagnostics.isRunning {
                Label(.advancedDiagnosticsUnavailableTitle, systemImage: "exclamationmark.circle")
                    .font(Theme.callout)
                Text(blockedDescription).font(Theme.caption).foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Table(model.diagnostics.entries) {
                TableColumn(AppLocalization.string(.advancedDiagnosticColumnTime)) { entry in
                    Text(entry.elapsedMilliseconds, format: .number).monospacedDigit()
                }.width(75)
                TableColumn(AppLocalization.string(.advancedDiagnosticColumnInput)) { entry in Text(entry.inputLabel) }.width(min: 130, ideal: 160)
                TableColumn(AppLocalization.string(.advancedDiagnosticColumnRaw)) { entry in
                    if case .button(let number) = entry.kind { Text(number, format: .number).monospacedDigit() }
                    else { Text(verbatim: "—") }
                }.width(min: 80, ideal: 95)
                TableColumn(AppLocalization.string(.advancedDiagnosticColumnPhase)) { entry in Text(entry.phaseLabel) }.width(min: 90, ideal: 115)
                TableColumn(AppLocalization.string(.advancedDiagnosticColumnModifiers)) { entry in
                    Text(entry.modifiers.glyphs + (entry.modifiers.contains(.function) ? "fn" : ""))
                }.width(min: 95, ideal: 115)
                TableColumn(AppLocalization.string(.advancedDiagnosticColumnOutcome)) { entry in Text(entry.outcomeLabel) }.width(min: 115, ideal: 140)
            }.overlay {
                if model.diagnostics.entries.isEmpty {
                    VStack(spacing: 8) {
                        Text(model.diagnostics.isRunning ? LocalizedStringResource.advancedDiagnosticsWait : .advancedDiagnosticsEmpty)
                        Text(.advancedDiagnosticsStartHint).font(Theme.callout).foregroundStyle(Theme.textSecondary)
                    }.padding().allowsHitTesting(false)
                }
            }
            Text(.advancedDiagnosticCount(count1: model.diagnostics.entries.count, count2: Int(clamping: model.diagnostics.omitted)))
                .font(Theme.caption).foregroundStyle(Theme.textSecondary)
            HStack {
                Text(.advancedDiagnosticsLimits).font(Theme.caption).foregroundStyle(Theme.textSecondary).fixedSize(horizontal: false, vertical: true)
                Spacer()
                Button(.diagnosticsClose) { dismiss() }.keyboardShortcut(.cancelAction).secondaryButton()
            }
        }.padding(24).frame(width: 840, height: 570)
            .background(Theme.sheetSurface)
            .onDisappear { model.closeDiagnostics() }
    }

    private var blockedDescription: LocalizedStringResource {
        if model.storageLocked { return .advancedDiagnosticsUnavailableBody }
        if case .secureInput = model.status { return .advancedDiagnosticsSecureInput }
        return .advancedDiagnosticsBlocked
    }
}

private extension InputDiagnostic {
    var inputLabel: String {
        switch kind {
        case .button(let number): AppLocalization.string(.mouseButton(Int(number) + 1))
        case .wheel(let direction): AppLocalization.string(direction.label)
        case .unsupportedScroll: AppLocalization.string(.diagnosticsUnsupportedScroll)
        }
    }
    var phaseLabel: LocalizedStringResource {
        switch phase {
        case .down: .diagnosticsDown
        case .up: .diagnosticsUp
        case .drag: .diagnosticsDrag
        case .scroll: .mouseWheelInput
        case .activation: .holdActivation
        }
    }
    var outcomeLabel: LocalizedStringResource {
        switch outcome {
        case .passedThrough: .diagnosticsPassed
        case .suppressed: .diagnosticsSuppressed
        case .queued: .diagnosticsQueued
        }
    }
}
