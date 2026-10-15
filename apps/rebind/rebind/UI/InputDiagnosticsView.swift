import SwiftUI

struct InputDiagnosticsView: View {
    let model: AppModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(.inputDiagnostics).font(Theme.titleSmall).accessibilityAddTraits(.isHeader)
            Text(.advancedDiagnosticsPrivacy).font(Theme.body).foregroundStyle(Theme.textSecondary).fixedSize(horizontal: false, vertical: true)
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
            VStack(spacing: 0) {
                row([.advancedDiagnosticColumnTime, .advancedDiagnosticColumnInput, .advancedDiagnosticColumnRaw,
                     .advancedDiagnosticColumnPhase, .advancedDiagnosticColumnModifiers, .advancedDiagnosticColumnOutcome]
                    .map { Text($0) }, font: Theme.overline, isHeader: true)
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(model.diagnostics.entries) { entry in
                            Theme.separator.frame(height: 1).padding(.horizontal, 20)
                            row([Text(entry.elapsedMilliseconds, format: .number).monospacedDigit(),
                                 Text(entry.inputLabel).font(Theme.bodyStrong), rawButton(entry), Text(entry.phaseLabel),
                                 Text(entry.modifiers.glyphs + (entry.modifiers.contains(.function) ? "fn" : "")),
                                 Text(entry.outcomeLabel)], font: Theme.body)
                                .accessibilityElement(children: .combine)
                        }
                    }
                }
            }
            .frame(maxHeight: .infinity)
            .background(Theme.cardSurface, in: .rect(cornerRadius: 16, style: .continuous))
            .overlay { RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Theme.borderSubtle) }
            .overlay {
                if model.diagnostics.entries.isEmpty {
                    VStack(spacing: 8) {
                        Text(model.diagnostics.isRunning ? LocalizedStringResource.advancedDiagnosticsWait : .advancedDiagnosticsEmpty)
                            .font(Theme.bodyStrong).foregroundStyle(Theme.textPrimary)
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

    /// One table line; the Input column takes the remaining width.
    private func row(_ cells: [Text], font: Font, isHeader: Bool = false) -> some View {
        let widths: [CGFloat?] = [80, nil, 100, 130, 110, 150]
        return HStack(spacing: 12) {
            ForEach(cells.indices, id: \.self) { index in
                cells[index].lineLimit(1)
                    .frame(width: widths[index], alignment: .leading)
                    .frame(maxWidth: widths[index] == nil ? .infinity : nil, alignment: .leading)
            }
        }
        .font(font).textCase(isHeader ? .uppercase : nil)
        .foregroundStyle(isHeader ? Theme.textSecondary : Theme.textPrimary)
        .padding(.horizontal, 20).frame(height: isHeader ? 40 : 44)
    }

    private func rawButton(_ entry: InputDiagnostic) -> Text {
        if case .button(let number) = entry.kind { return Text(number, format: .number).monospacedDigit() }
        return Text(verbatim: "–")
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
        case .button(let number): InputLabels.buttonName(number)
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
        case .adjusted: .diagnosticsAdjusted
        case .suppressed: .diagnosticsSuppressed
        case .queued: .diagnosticsQueued
        }
    }
}
