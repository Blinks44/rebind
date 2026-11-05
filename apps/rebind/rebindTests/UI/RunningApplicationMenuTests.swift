import AppKit
import Foundation
import SwiftUI
import Testing

@testable import rebind

@MainActor struct RunningApplicationMenuTests {
    private func choice(_ name: String, id: String, path: String = "/Applications/Test.app") -> RunningApplicationChoice {
        RunningApplicationChoice(target: ApplicationTarget(url: URL(filePath: path), bundleIdentifier: id), name: name)
    }

    @Test func generatedVMsOutsideApplicationsKeepTheirOwnIdentity() {
        let vm = choice("Ubuntu 24.04", id: "example.vm.ubuntu", path: "/tmp/Virtual Machines/Ubuntu.vm/VM.app")
        let manager = choice("VM Manager", id: "example.manager")
        let choices = RunningApplicationChoice.available([manager, vm], excluding: [manager.target.bundleIdentifier])
        #expect(choices.map(\.name) == ["Ubuntu 24.04"])
        #expect(choices.map(\.target) == [vm.target])
        var configuration = Configuration()
        configuration.excludedApplications = [ExcludedApplication(target: choices[0].target)]
        let mailbox = EngineMailbox()
        mailbox.configure(configuration)
        #expect(mailbox.state.withLock { $0.smoothScrollingExclusions } == [vm.target.bundleIdentifier])
    }

    @Test func choicesOmitDuplicatesExcludedAppsSelfAndInvalidTargetsAndSortByName() {
        let alpha = choice("Alpha", id: "example.alpha")
        let beta = choice("Beta", id: "example.beta")
        let choices = RunningApplicationChoice.available(
            [
                beta, alpha, beta, choice("Rebind", id: "blinks44.rebind"), choice("Invalid", id: ""),
                choice("File", id: "example.file", path: "/tmp/file.txt"), choice("Excluded", id: "example.excluded"),
            ],
            excluding: ["example.excluded"])
        #expect(choices.map(\.name) == ["Alpha", "Beta"])
        #expect(RunningApplicationChoice.available([], excluding: []).isEmpty)
    }

    @Test func generatedBundleNameRemainsUsefulAfterSavingWithoutRunningProcess() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let app = folder.appendingPathComponent("VM.app")
        let contents = app.appendingPathComponent("Contents")
        try FileManager.default.createDirectory(at: contents, withIntermediateDirectories: true)
        let info = ["CFBundleIdentifier": "example.vm.ubuntu", "CFBundleName": "Ubuntu 24.04", "CFBundlePackageType": "APPL"]
        try PropertyListEncoder().encode(info).write(to: contents.appendingPathComponent("Info.plist"))
        let target = try #require(ApplicationTarget(bundleURL: app))
        let saved = try JSONDecoder().decode(ApplicationTarget.self, from: JSONEncoder().encode(target))
        #expect(saved.exclusionDisplayName == "Ubuntu 24.04")
        #expect(choice("Missing", id: "example.missing", path: "/tmp/Missing.app").target.exclusionDisplayName == "Missing")
    }

    @Test func exclusionCardFitsNarrowWidthInAllLanguagesAndAppearances() async throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let store = ConfigurationStore(url: folder.appendingPathComponent("configuration.json"))
        var configuration = Configuration()
        configuration.excludedApplications = [
            ExcludedApplication(target: choice("Ubuntu 24.04", id: "example.vm.ubuntu", path: "/Applications/Ubuntu 24.04.app").target)
        ]
        try store.save(configuration)
        let model = AppModel(store: store, readPermissions: { InputPermissions(accessibility: true, posting: true) })
        for language in ["en", "ru", "de", "fr", "es", "zh-Hans"] {
            for dark in [false, true] {
                let controller = NSHostingController(
                    rootView: ExcludedApplicationsCard(model: model)
                        .padding(20).frame(width: 600).background(Theme.canvasTop)
                        .environment(\.locale, Locale(identifier: language)).preferredColorScheme(dark ? .dark : .light))
                let window = NSWindow(contentViewController: controller)
                window.isReleasedWhenClosed = false
                defer { window.close() }
                window.appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
                window.setContentSize(NSSize(width: 600, height: 260))
                controller.view.layoutSubtreeIfNeeded()
                try await Task.sleep(for: .milliseconds(50))
                controller.view.layoutSubtreeIfNeeded()
                #expect(controller.view.fittingSize.width <= 601)
                #expect(controller.view.fittingSize.height <= 260)
                let bitmap = try #require(controller.view.bitmapImageRepForCachingDisplay(in: controller.view.bounds))
                controller.view.cacheDisplay(in: controller.view.bounds, to: bitmap)
                let png = try #require(bitmap.representation(using: .png, properties: [:]))
                Attachment.record(png, named: "exclusions-\(language)-\(dark ? "dark" : "light").png")
            }
        }
    }

}
