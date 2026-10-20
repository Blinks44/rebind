#if DEBUG
import Foundation
import SwiftUI

/// The production window/editor/settings hierarchy with disposable storage and no input engine.
struct ApplicationUIFixture: View {
    @State private var model: AppModel?

    init() {
        let directory = FileManager.default.temporaryDirectory.appending(path: "RebindUIFixture-\(UUID())")
        let store = ConfigurationStore(url: directory.appending(path: "configuration.json"))
        var configuration = Configuration(bindings: [
            Binding(scope: .allKeyboards, trigger: .key(0), modifiers: .control, action: .doNothing),
            Binding(scope: .allMice, trigger: .mouseButton(3), modifiers: [], action: .doNothing),
            Binding(scope: .builtInTrackpad, trigger: .threeFingerTap, modifiers: [], action: .doNothing),
            Binding(scope: .magicTrackpad, trigger: .threeFingerTap, modifiers: [], action: .doNothing),
            Binding(scope: .magicMouse, trigger: .magicMouseClick(fingers: 3), modifiers: [], action: .doNothing)
        ])
        configuration.hasCompletedSetup = true
        do {
            try store.save(configuration)
            _model = State(initialValue: AppModel(store: store,
                readPermissions: { InputPermissions(accessibility: true, posting: true) }))
        } catch {
            _model = State(initialValue: nil)
        }
    }

    var body: some View {
        if let model {
            ContentView(model: model, initialDestination: .input(.allKeyboards), persistsWindowSelection: false)
                .environment(\.locale, model.activeLanguage.locale)
        } else {
            Text("Could not create disposable UI fixture storage.")
        }
    }
}
#endif
