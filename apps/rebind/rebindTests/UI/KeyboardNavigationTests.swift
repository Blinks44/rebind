import AppKit
import SwiftUI
import XCTest
@testable import rebind

/// Native focus routing only: no input capture or real configuration.
@MainActor final class KeyboardNavigationTests: XCTestCase {
    func testFocusDecorationPreservesOwnedFocusAndKeyHandling() async throws {
        let probe = Probe()
        let controller = NSHostingController(rootView: FocusFixture(probe: probe))
        let window = NSWindow(contentViewController: controller)
        window.isReleasedWhenClosed = false
        defer { window.close() }
        let previousPolicy = NSApp.activationPolicy()
        NSApp.setActivationPolicy(.regular)
        defer { NSApp.setActivationPolicy(previousPolicy) }
        window.styleMask.insert(.titled)
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
        try await Task.sleep(for: .milliseconds(100))
        probe.requestFocus = true
        try await Task.sleep(for: .milliseconds(100))
        XCTAssertTrue(probe.focused)
        let event = try XCTUnwrap(NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: [],
            timestamp: ProcessInfo.processInfo.systemUptime, windowNumber: window.windowNumber,
            context: nil, characters: "\u{F703}",
            charactersIgnoringModifiers: "\u{F703}", isARepeat: false, keyCode: 124))
        window.sendEvent(event)
        XCTAssertTrue(probe.receivedArrow)
        probe.requestFocus = false
        try await Task.sleep(for: .milliseconds(50))
        XCTAssertFalse(probe.focused)
    }

    func testCategoryShortcutsWorkWithoutPointerActivation() async throws {
        let probe = Probe()
        let sidebar = MainSidebar(selection: .init(get: { probe.destination }, set: { probe.destination = $0 }), showAbout: {})
        let controller = NSHostingController(rootView: sidebar.frame(width: 240, height: 700))
        let window = NSWindow(contentViewController: controller)
        window.isReleasedWhenClosed = false
        defer { window.close() }
        let previousPolicy = NSApp.activationPolicy()
        NSApp.setActivationPolicy(.regular)
        defer { NSApp.setActivationPolicy(previousPolicy) }
        window.styleMask.insert(.titled)
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
        try await Task.sleep(for: .milliseconds(100))
        for (key, code, destination) in [("2", UInt16(19), MainDestination.input(.allMice)),
                                          ("5", UInt16(23), MainDestination.input(.magicMouse)),
                                          ("6", UInt16(22), MainDestination.devices)] {
            let event = try XCTUnwrap(NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: .command,
                timestamp: ProcessInfo.processInfo.systemUptime, windowNumber: window.windowNumber,
                context: nil, characters: key, charactersIgnoringModifiers: key, isARepeat: false, keyCode: code))
            XCTAssertTrue(window.performKeyEquivalent(with: event))
            XCTAssertEqual(probe.destination, destination)
        }
    }

    func testTabAndSpaceReachActualSidebarWithoutProgrammaticFocus() async throws {
        let probe = Probe()
        probe.destination = .input(.magicMouse)
        let controller = NSHostingController(rootView: MainSidebar(
            selection: .init(get: { probe.destination }, set: { probe.destination = $0 }), showAbout: {})
            .frame(width: 240, height: 700))
        let window = NSWindow(contentViewController: controller)
        window.isReleasedWhenClosed = false
        defer { window.close() }
        let previousPolicy = NSApp.activationPolicy()
        NSApp.setActivationPolicy(.regular)
        defer { NSApp.setActivationPolicy(previousPolicy) }
        window.styleMask.insert(.titled)
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
        try await Task.sleep(for: .milliseconds(100))
        guard NSApp.isActive, window.isKeyWindow else {
            throw XCTSkip("Physical Tab traversal requires an active app and key window; use the Debug keyboard fixture for live acceptance.")
        }
        sendKey("\t", code: 48, to: window)
        try await Task.sleep(for: .milliseconds(40))
        sendKey(" ", code: 49, to: window)
        try await Task.sleep(for: .milliseconds(50))
        XCTAssertEqual(probe.destination, .input(.allKeyboards))
        sendKey("\u{F701}", code: 125, to: window)
        try await Task.sleep(for: .milliseconds(50))
        sendKey(" ", code: 49, to: window)
        try await Task.sleep(for: .milliseconds(50))
        XCTAssertEqual(probe.destination, .input(.allMice))
    }

    func testTabAndArrowsReachActualSettingsPicker() async throws {
        let probe = Probe()
        let controller = NSHostingController(rootView: SettingsSectionPicker(
            selection: .init(get: { probe.section }, set: { probe.section = $0 })).frame(width: 900).padding())
        let window = NSWindow(contentViewController: controller)
        window.isReleasedWhenClosed = false
        defer { window.close() }
        let previousPolicy = NSApp.activationPolicy()
        NSApp.setActivationPolicy(.regular)
        defer { NSApp.setActivationPolicy(previousPolicy) }
        window.styleMask.insert(.titled)
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
        try await Task.sleep(for: .milliseconds(100))
        guard NSApp.isActive, window.isKeyWindow else {
            throw XCTSkip("Physical Tab traversal requires an active app and key window; use the Debug keyboard fixture for live acceptance.")
        }
        sendKey("\t", code: 48, to: window)
        try await Task.sleep(for: .milliseconds(40))
        sendKey("\u{F703}", code: 124, to: window)
        XCTAssertNotEqual(probe.section, .general)
    }

    private func sendKey(_ characters: String, code: UInt16, to window: NSWindow) {
        guard let event = NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: [],
            timestamp: ProcessInfo.processInfo.systemUptime, windowNumber: window.windowNumber,
            context: nil, characters: characters, charactersIgnoringModifiers: characters, isARepeat: false, keyCode: code) else {
            XCTFail("Could not construct a fixture key event")
            return
        }
        NSApp.sendEvent(event)
        if let up = NSEvent.keyEvent(with: .keyUp, location: .zero, modifierFlags: [],
            timestamp: ProcessInfo.processInfo.systemUptime, windowNumber: window.windowNumber,
            context: nil, characters: characters, charactersIgnoringModifiers: characters, isARepeat: false, keyCode: code) {
            NSApp.sendEvent(up)
        }
    }

    @Observable final class Probe {
        var destination: MainDestination = .input(.allKeyboards)
        var section: SettingsSection = .general
        var requestFocus = false
        var focused = false
        var receivedArrow = false
    }

    struct FocusFixture: View {
        let probe: Probe
        @FocusState private var focused: Bool
        var body: some View {
            Button("Focus fixture") { }
                .focusable(interactions: .edit)
                .focused($focused)
                .keyboardFocusRing(isFocused: focused)
                .onKeyPress(.rightArrow) { probe.receivedArrow = true; return .handled }
                .onChange(of: probe.requestFocus) { focused = probe.requestFocus }
                .onChange(of: focused) { probe.focused = focused }
                .padding(20)
        }
    }
}
