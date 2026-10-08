import Testing
@testable import rebind

@MainActor struct AppModelRecordingTests {
    @Test func losingFocusWithoutRecordingPreservesBackgroundHold() {
        let model = AppModel(loadConfiguration: false)
        let output = KeyboardShortcut(keyCode: 0, modifiers: .command)
        let binding = rebind.Binding(scope: .allMice, trigger: .mouseButton(4), modifiers: [],
                                    action: .shortcut(output), activation: .hold, holdDurationMilliseconds: 1000)
        model.mailbox.configure(Configuration(isEnabled: true, bindings: [binding]))
        #expect(model.mailbox.handle(InputEvent(trigger: .mouseButton(4), phase: .down), secureInput: false))
        model.cancelRecording() // The didResignActive notification's selector.
        model.mailbox.pollHold(at: 1_000_000_000, secureInput: false)
        #expect(model.mailbox.state.withLock { $0.pending } == [output])
        #expect(model.mailbox.handle(InputEvent(trigger: .mouseButton(4), phase: .up), secureInput: false))
    }

    @Test func losingFocusStillCancelsExplicitRecording() {
        let model = AppModel(loadConfiguration: false)
        let request = RecordingRequest(target: .mouseTrigger)
        model.recording = request
        model.mailbox.record(request)
        model.cancelRecording()
        #expect(model.recording == nil)
        #expect(model.mailbox.state.withLock { $0.recording == nil && $0.recorded == nil })
    }
}
