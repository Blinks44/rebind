import AppKit
import SwiftUI
import XCTest
@testable import rebind

/// Native fixtures use stub login state and never start the input engine.
@MainActor final class GeneralSettingsLayoutTests: XCTestCase {
    private enum Fixture: String, CaseIterable {
        case active, paused, approval, enableFailed, removalFailed, approvalRemovalFailed
        case unavailable, missingAccess, engineError, secureInput, busy, storageLocked, saveFailed
    }

    func testGeneralStatesFitSettingsViewportInAllLanguagesAndAppearances() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: "RebindGeneralLayout-\(UUID())")
        defer { try? FileManager.default.removeItem(at: directory) }
        for fixture in Fixture.allCases {
            let store = ConfigurationStore(url: directory.appending(path: "\(fixture.rawValue)/configuration.json"))
            let service = LoginItemServiceStub(status: fixture == .removalFailed || fixture == .busy ? .enabled : .off)
            let login = LoginItemModel(service: service)
            switch fixture {
            case .approval: service.status = .requiresApproval; login.refresh()
            case .unavailable: service.status = .unavailable; login.refresh()
            case .enableFailed:
                service.registrationResult = .off; service.rejectsRegistration = true
                await login.setEnabled(true)
            case .removalFailed, .approvalRemovalFailed:
                service.status = .enabled
                service.removalResult = fixture == .removalFailed ? .enabled : .requiresApproval
                service.rejectsRemoval = true
                await login.setEnabled(false)
            default: break
            }
            try store.save(Configuration(isEnabled: fixture != .paused))
            if fixture == .storageLocked {
                try Data("protected configuration fixture".utf8).write(to: store.url)
            }
            let grants = InputPermissions(accessibility: fixture != .missingAccess, posting: fixture != .missingAccess)
            let model = AppModel(store: store, sessionAllowsInput: { true }, readPermissions: { grants }, loginItem: login)
            model.mailbox.configure(model.configuration)
            model.mailbox.state.withLock {
                $0.status = fixture == .engineError ? .tapFailed : fixture == .secureInput ? .secureInput : .active
            }
            model.refresh()
            if fixture == .saveFailed { model.error = .storageWriteFailed }
            if fixture == .busy {
                service.onRemoval = {
                    do { try await self.verifyLayout(model, fixture: fixture) }
                    catch { XCTFail("Busy fixture failed: \(error)") }
                }
                await login.setEnabled(false)
            } else {
                try await verifyLayout(model, fixture: fixture)
            }
        }
    }

    private func verifyLayout(_ model: AppModel, fixture: Fixture) async throws {
        let sizes = [NSSize(width: 600, height: 480), NSSize(width: 648, height: 600), NSSize(width: 808, height: 640)]
        for language in AppLanguage.allCases.map(\.rawValue) {
            for appearance in [ColorScheme.light, .dark] {
                let controller = NSHostingController(rootView: SettingsView(model: model, selection: .constant(.general))
                    .environment(\.locale, Locale(identifier: language))
                    .preferredColorScheme(appearance))
                let window = NSWindow(contentViewController: controller)
                window.appearance = NSAppearance(named: appearance == .dark ? .darkAqua : .aqua)
                window.isReleasedWhenClosed = false
                defer { window.close() }
                for size in sizes {
                    window.setContentSize(size)
                    controller.view.layoutSubtreeIfNeeded()
                    try await Task.sleep(for: .milliseconds(50))
                    controller.view.layoutSubtreeIfNeeded()
                    window.displayIfNeeded()
                    let context = "\(fixture), \(language), \(appearance), \(size)"
                    XCTAssertEqual(controller.view.bounds.width, size.width, accuracy: 1, context)
                    XCTAssertEqual(controller.view.bounds.height, size.height, accuracy: 1, context)
                    let scroll = try XCTUnwrap(firstScrollView(in: controller.view), context)
                    let bounds = scroll.convert(scroll.bounds, to: controller.view)
                    XCTAssertGreaterThan(bounds.height, 0, context)
                    XCTAssertLessThanOrEqual(scroll.documentView?.frame.width ?? 0, scroll.contentView.bounds.width + 1, context)
                    XCTAssertGreaterThanOrEqual(bounds.minX, -1, context)
                    XCTAssertGreaterThanOrEqual(bounds.minY, -1, context)
                    XCTAssertLessThanOrEqual(bounds.maxX, size.width + 1, context)
                    XCTAssertLessThanOrEqual(bounds.maxY, size.height + 1, context)
                    if size.width == 808 || size.width == 600 && language == "ru" {
                        let bitmap = try XCTUnwrap(controller.view.bitmapImageRepForCachingDisplay(in: controller.view.bounds))
                        controller.view.cacheDisplay(in: controller.view.bounds, to: bitmap)
                        let png = try XCTUnwrap(bitmap.representation(using: .png, properties: [:]))
                        let attachment = XCTAttachment(data: png, uniformTypeIdentifier: "public.png")
                        attachment.name = "general-\(fixture.rawValue)-\(language)-\(appearance)-\(Int(size.width))"
                        attachment.lifetime = .keepAlways
                        add(attachment)
                    }
                }
            }
        }
    }

    private func firstScrollView(in view: NSView) -> NSScrollView? {
        if let scroll = view as? NSScrollView { return scroll }
        for child in view.subviews {
            if let scroll = firstScrollView(in: child) { return scroll }
        }
        return nil
    }
}
