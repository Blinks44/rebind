#if DEBUG
import SwiftUI

/// A real-window keyboard fixture: no AppModel, storage, input capture or output actions.
struct KeyboardNavigationFixture: View {
    @State private var destination: MainDestination = .input(.allKeyboards)
    @State private var section: SettingsSection = .general
    @State private var text = ""
    @State private var enabled = false
    @State private var activations = 0

    var body: some View {
        HStack(spacing: 0) {
            MainSidebar(selection: $destination, showAbout: {}).frame(width: 240).focusSection()
            VStack(alignment: .leading, spacing: 24) {
                Text("Keyboard navigation fixture").font(Theme.title)
                Text(String(describing: destination)).accessibilityIdentifier("fixture-destination")
                SettingsSectionPicker(selection: $section)
                Text(String(describing: section)).accessibilityIdentifier("fixture-section")
                ThemeTextField(title: .mouseSearchBindings, text: $text, symbol: "magnifyingglass")
                MenuSelector(selection: $section, title: .settingsTitle, choices: SettingsSection.allCases, label: { $0.title })
                Toggle("Fixture switch", isOn: $enabled).toggleStyle(ThemeSwitchStyle())
                OptionsMenu(label: .profileOptions) {
                    Button("Fixture menu action") { activations += 1 }
                    Menu("Fixture submenu") { Button("Fixture nested action") { activations += 2 } }
                    Button("Fixture unavailable") {}.disabled(true)
                }.accessibilityIdentifier("fixture-options")
                Button("Fixture action") { activations += 1 }.primaryButton()
                Text("Activations: \(activations)")
                Spacer()
            }.padding(32).frame(maxWidth: .infinity, maxHeight: .infinity).focusSection()
        }.background { ThemeCanvas() }.frame(width: 1080, height: 720)
    }
}
#endif
