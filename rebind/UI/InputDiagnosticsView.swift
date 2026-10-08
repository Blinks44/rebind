import SwiftUI

struct InputDiagnosticsView: View {
    let model: AppModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(.inputDiagnostics).font(.title2.bold())
            Text(.diagnosticsHint).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            HStack {
                Label(model.diagnostics.isRunning ? LocalizedStringResource.diagnosticsRunning : .diagnosticsStopped,
                      systemImage: model.diagnostics.isRunning ? "record.circle" : "pause.circle")
                Spacer()
                Button(model.diagnostics.isRunning ? LocalizedStringResource.diagnosticsStop : .diagnosticsStart) {
                    if model.diagnostics.isRunning { model.stopDiagnostics() } else { model.startDiagnostics() }
                }.disabled(!model.diagnostics.isRunning && !model.canStartDiagnostics)
                Button(.clearRecording) { model.clearDiagnostics() }.disabled(model.diagnostics.entries.isEmpty && model.diagnostics.omitted == 0)
            }
            Text(model.statusText).font(.caption).foregroundStyle(.secondary)
            Table(model.diagnostics.entries) {
                TableColumn(String(localized: .diagnosticsTime)) { entry in
                    Text(entry.elapsedMilliseconds, format: .number).monospacedDigit()
                }.width(75)
                TableColumn(String(localized: .diagnosticsInput)) { entry in Text(entry.inputLabel) }.width(min: 140, ideal: 170)
                TableColumn(String(localized: .diagnosticsRawButton)) { entry in
                    if case .button(let number) = entry.kind { Text(number, format: .number).monospacedDigit() }
                    else { Text(verbatim: "—") }
                }.width(70)
                TableColumn(String(localized: .diagnosticsPhase)) { entry in Text(entry.phaseLabel) }.width(min: 90, ideal: 125)
                TableColumn(String(localized: .diagnosticsModifiers)) { entry in
                    Text(entry.modifiers.glyphs + (entry.modifiers.contains(.function) ? "fn" : ""))
                }.width(90)
                TableColumn(String(localized: .diagnosticsOutcome)) { entry in Text(entry.outcomeLabel) }.width(min: 120, ideal: 150)
            }.overlay {
                if model.diagnostics.entries.isEmpty {
                    ContentUnavailableView(.diagnosticsEmpty, systemImage: "computermouse")
                }
            }
            Text(.diagnosticsOmitted(Int(clamping: model.diagnostics.omitted))).font(.caption).foregroundStyle(.secondary)
            HStack {
                Text(.diagnosticsLimits).font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                Spacer()
                Button(.diagnosticsClose) { dismiss() }.keyboardShortcut(.cancelAction)
            }
        }.padding(24).frame(width: 840, height: 570)
            .onDisappear { model.closeDiagnostics() }
    }
}

private extension InputDiagnostic {
    var inputLabel: String {
        switch kind {
        case .button(let number): String(localized: .mouseButton(Int(number) + 1))
        case .wheel(let direction): String(localized: direction.label)
        case .unsupportedScroll: String(localized: .diagnosticsUnsupportedScroll)
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
