// Compile-only public API availability probe, outside the app target.
// Constant bindings/environment samples do not establish runtime or visual acceptance.
import SwiftUI
import AppKit

struct RebindMaterialProbe: View {
    private let section = Binding.constant(0)
    private let language = Binding.constant(0)
    private let enabled = Binding.constant(true)
    private let scheme = ColorScheme.light
    private let contrast = ColorSchemeContrast.standard
    private let reduceTransparency = false
    private let reduceMotion = true

    var body: some View {
        NavigationSplitView {
            List {
                Menu("Work", systemImage: "house") { Button("Manage Profiles") {} }
                    .buttonStyle(.glass)
                Label("Keyboard", systemImage: "keyboard")
                Label("Settings", systemImage: "gearshape")
            }
        } detail: {
            VStack(alignment: .leading, spacing: 20) {
                Picker("Settings", selection: section) {
                    Text("General").tag(0)
                    Text("Permissions").tag(1)
                    Text("Input").tag(2)
                    Text("Language").tag(3)
                    Text("Advanced").tag(4)
                }.pickerStyle(.segmented)
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Toggle("Enable remapping", isOn: enabled)
                        LabeledContent("App language") {
                            Picker("App language", selection: language) {
                                Text("System Default").tag(0)
                                Text("English").tag(1)
                            }.pickerStyle(.menu)
                        }
                    }.padding(16).frame(maxWidth: .infinity, alignment: .leading)
                        .background {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(LinearGradient(
                                    colors: [Color(nsColor: .controlBackgroundColor), Color(nsColor: .controlBackgroundColor)],
                                    startPoint: .top, endPoint: .bottom))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .strokeBorder(.primary.opacity(contrast == .increased ? 0.5 : 0.10),
                                                      lineWidth: contrast == .increased ? 1 : 0.5)
                                }
                                .shadow(color: .black.opacity(scheme == .dark ? 0.20 : 0.07), radius: 5, y: 3)
                        }
                }
                GlassEffectContainer(spacing: 8) {
                    HStack(spacing: 16) {
                        Button("Add Binding") {}.buttonStyle(.glassProminent)
                        Button("Manage Profiles") {}.buttonStyle(.glass)
                        Text("Floating control API")
                            .padding(8)
                            .glassEffect(.regular, in: .capsule)
                    }
                }
                .animation(reduceMotion ? nil : .default, value: section.wrappedValue)
            }.padding(28)
        }
    }
}

func materialAccessibilityValues(_ environment: EnvironmentValues) -> Bool {
    environment.accessibilityReduceTransparency || environment.accessibilityReduceMotion || environment.colorSchemeContrast == .increased
}
