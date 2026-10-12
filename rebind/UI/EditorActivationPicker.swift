import SwiftUI

/// Fixed segment geometry and one passive glass track; selection never scales or morphs the control.
struct EditorActivationPicker: View {
    @SwiftUI.Binding var selection: PressActivation
    @Environment(\.isEnabled) private var isEnabled
    @FocusState private var focused: PressActivation?

    var body: some View {
        HStack(spacing: 0) {
            ForEach(PressActivation.allCases, id: \.self) { choice in
                Button {
                    selection = choice
                } label: {
                    Text(title(for: choice)).font(EditorTypography.label)
                        .foregroundStyle(selection == choice ? Color.white : Color(.editorTextPrimary))
                        .frame(maxWidth: .infinity, minHeight: EditorMetrics.buttonHeight)
                        .contentShape(.capsule)
                        .background {
                            if selection == choice { Capsule().fill(Color(.editorSelection)) }
                        }
                }
                .buttonStyle(.plain)
                .focused($focused, equals: choice)
            }
        }
        .modifier(EditorGlassSurface(interactive: false))
        .transaction { $0.animation = nil }
        .onKeyPress(.leftArrow) { moveSelection(by: -1) }
        .onKeyPress(.rightArrow) { moveSelection(by: 1) }
        .onChange(of: selection) { if focused != nil { focused = selection } }
        .accessibilityRepresentation {
            Picker(.activationTitle, selection: $selection) {
                ForEach(PressActivation.allCases, id: \.self) { choice in
                    Text(title(for: choice)).tag(choice)
                }
            }.pickerStyle(.radioGroup)
        }
    }

    private func title(for choice: PressActivation) -> LocalizedStringResource {
        switch choice {
        case .press: .pressActivation
        case .doublePress: .doublePressActivation
        case .hold: .holdActivation
        }
    }

    private func moveSelection(by offset: Int) -> KeyPress.Result {
        guard isEnabled else { return .ignored }
        let choices = PressActivation.allCases
        guard let index = choices.firstIndex(of: focused ?? selection) else { return .ignored }
        let next = min(max(index + offset, choices.startIndex), choices.count - 1)
        selection = choices[next]
        focused = choices[next]
        return .handled
    }
}
