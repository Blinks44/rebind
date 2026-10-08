import SwiftUI

struct ActionPickerView: View {
    let model: AppModel
    @SwiftUI.Binding var selection: ActionKind
    @State private var presented = false
    @State private var search = ""

    var body: some View {
        Button { search = ""; presented = true } label: {
            HStack {
                Text(selection.title)
                Spacer()
                Image(systemName: "chevron.up.chevron.down").accessibilityHidden(true)
            }
        }.accessibilityLabel(Text(.chooseAction)).accessibilityValue(Text(selection.title))
            .disabled(model.recording != nil)
            .sheet(isPresented: $presented) {
                VStack(alignment: .leading, spacing: 16) {
                    Text(.chooseAction).font(.title2.bold())
                    TextField(.searchActions, text: $search)
                    List {
                        ForEach(ActionKind.Category.allCases) { category in
                            if matchingKinds.contains(where: { $0.category == category }) {
                                Section { rows(category: category) } header: { Text(category.title) }
                            }
                        }
                        if matchingKinds.isEmpty { Text(.noMatchingActions).foregroundStyle(.secondary) }
                    }
                    HStack {
                        Spacer()
                        Button(.cancel) { presented = false }.keyboardShortcut(.cancelAction)
                    }
                }.padding(24).frame(width: 480, height: 380)
            }
    }

    private var matchingKinds: [ActionKind] {
        ActionKind.allCases.filter {
            return search.isEmpty
                || String(localized: $0.title).localizedStandardContains(search)
                || String(localized: $0.category.title).localizedStandardContains(search)
        }
    }

    private func rows(category: ActionKind.Category) -> some View {
        ForEach(matchingKinds.filter { $0.category == category }) { kind in
            let available = kind.isAvailable(with: model.audioCapabilities)
            Button {
                selection = kind
                presented = false
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(kind.title)
                        if !available {
                            Text(.audioActionUnavailable).font(.caption).foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    Spacer()
                    if selection == kind { Image(systemName: "checkmark").accessibilityLabel(Text(.profileSelected)) }
                }.frame(maxWidth: .infinity, alignment: .leading).contentShape(.rect)
            }.buttonStyle(.plain).disabled(!available)
        }
    }
}
