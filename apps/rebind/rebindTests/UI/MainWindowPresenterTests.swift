import AppKit
import Testing
@testable import rebind

@MainActor @Suite(.serialized) struct MainWindowPresenterTests {
    @Test func repeatedCloseAndOpenNeverDependsOnActivationNotification() async throws {
        var activations = 0
        var sceneRequests = 0
        let window = NSWindow(contentRect: NSRect(x: 100, y: 100, width: 400, height: 300),
                              styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
        let presenter = MainWindowPresenter(activate: {
            #expect(window.isVisible == false)
            activations += 1
        })
        window.isReleasedWhenClosed = false
        defer { window.close() }
        presenter.register(window)
        presenter.installSceneOpener { sceneRequests += 1 }
        for _ in 0..<12 {
            window.close()
            presenter.show()
            try await Task.sleep(for: .milliseconds(40))
            #expect(window.isVisible)
        }
        #expect(sceneRequests == 0)
        #expect(activations == 12)
    }

    @Test func openingBeforeSceneHostOrWindowExistsRetainsTheRequest() async throws {
        let presenter = MainWindowPresenter(activate: {})
        presenter.show()
        try await Task.sleep(for: .milliseconds(40))
        var requests = 0
        presenter.installSceneOpener { requests += 1 }
        #expect(requests == 1)
        let window = NSWindow(contentRect: NSRect(x: 100, y: 100, width: 400, height: 300),
                              styleMask: [.titled, .closable], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        defer { window.close() }
        presenter.register(window)
        try await Task.sleep(for: .milliseconds(40))
        #expect(window.isVisible)
        // Closing the window does not queue another presentation.
        window.close()
        #expect(window.isVisible == false)
    }
}
