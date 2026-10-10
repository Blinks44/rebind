import Foundation
import Darwin
import Scribe
import Subsurface

@main @MainActor enum TrackpadProbe {
    static func main() async {
        let options: ProbeOptions
        do { options = try ProbeOptions(arguments: Array(CommandLine.arguments.dropFirst())) }
        catch { print("Use --check or an explicit capture mode. See --help; capture duration is 1–30 seconds."); exit(64) }

        // Apply the queue-owned configuration before touching the framework.
        LogManager.shared.configuration = LogConfiguration(enabledCategories: [])
        _ = LogManager.shared.configuration

        switch options {
        case .help:
            print("TrackpadProbe --check | --capture [--seconds 1–30] | --capture-default [--seconds 1–30]")
            print("Private-API feasibility tool. Passive capture reports only contact and button metadata; action testing is a separate explicit mode.")
            print("--capture-default also reads an unclassified default device; it does not establish trackpad support.")
            print("--capture-clicks-default [--seconds 1–30] adds passive mouse-button observation for click correlation.")
            print("--test-four-finger-close [--seconds 1–30] sends Command-W once after a qualified four-finger tap. Use a disposable browser tab.")
            print("--request-test-access requests the next missing action-test permission only. No capture or shortcut; waits up to 30 seconds for the grant.")
        case .requestTestAccess:
            let before = FourFingerCloseSender.access()
            printTestAccess(before)
            if let request = before.nextRequest {
                print("permission_requested=\(request.rawValue)")
                print("Allow the launcher shown by macOS (often Terminal) in System Settings > Privacy & Security > Accessibility. Rebind's permission is separate.")
                print("Waiting up to 30 seconds. If no prompt appears, open that pane manually; macOS may not repeat a denied request.")
                fflush(nil)
                FourFingerCloseSender.request(request)
                // AX prompting is asynchronous. Keep the CLI/run loop alive,
                // without creating a device or posting input. Do not treat the
                // request's return value as a completed grant.
                for _ in 0..<60 {
                    let current = FourFingerCloseSender.access()
                    let granted = request == .accessibility ? current.accessibility : current.posting
                    if granted { break }
                    do { try await Task.sleep(for: .milliseconds(500)) }
                    catch { break }
                }
            }
            let after = FourFingerCloseSender.access()
            printTestAccess(after)
            if after.allowed {
                print("Test access is available. Run --test-four-finger-close separately with a disposable browser tab.")
            } else {
                print("Access is still incomplete. After granting, quit and reopen the launcher, then rerun --request-test-access for the next missing permission.")
            }
            fflush(nil)
            if !after.allowed { exit(69) }
        case .check:
            // Availability only: no device creation, registration, start or stop.
            print("default_multitouch_available=\(SubsurfaceDevice.isAvailable)")
        case .capture(let seconds), .captureDefault(let seconds), .captureClicksDefault(let seconds), .testFourFingerClose(let seconds):
            guard ProbeSession.allowsCapture() else {
                print("Capture unavailable: unlock this Mac and close any password-entry field."); exit(69)
            }
            guard [26, 27].contains(ProcessInfo.processInfo.operatingSystemVersion.majorVersion) else {
                print("Capture unavailable: this probe supports macOS 26 and 27."); exit(69)
            }
            if options.postsTestShortcut {
                let access = FourFingerCloseSender.access()
                guard access.allowed else {
                    printTestAccess(access)
                    print("Test unavailable: run --request-test-access explicitly to request the missing permission. No permission request or capture was made.")
                    exit(69)
                }
            }
            guard let device = SubsurfaceDevice.defaultDevice else {
                print("Capture unavailable: macOS returned no default multitouch device."); exit(69)
            }
            guard device.kind == .trackpad || (device.kind == .other && options != .capture(seconds: seconds)) else {
                print("Capture unavailable: Subsurface classifies the default device as \(device.kind), not a trackpad.")
                if device.kind == .other { print("For raw default-device diagnostics, use --capture-default --seconds 20.") }
                exit(69)
            }
            if options.postsTestShortcut, !device.isBuiltIn {
                print("Test unavailable: this action check is limited to the built-in device."); exit(69)
            }
            print("source_kind=\(device.kind); built_in=\(device.isBuiltIn)")
            let stream = device.contactFrames()
            guard device.start() else {
                device.removeContactFrameCallback()
                print("Capture unavailable: macOS did not start the trackpad stream."); exit(69)
            }
            let observationClock = ProbeObservationClock(startedAt: clock_gettime_nsec_np(CLOCK_UPTIME_RAW))
            print("Capture started for \(seconds) seconds. Place and lift 3 and 4 fingers; ordinary system gestures remain active.")
            print("Short-contact candidates are diagnostic only: physical clicks can also appear as candidates.")
            let buttons: ButtonObservationBuffer? = options.observesButtons ? ButtonObservationBuffer(clock: observationClock) : nil
            if buttons != nil {
                print("Passive mouse observation requested. Use only the trackpad; nearbyContacts is timing, not source identity.")
                print("elapsedMilliseconds compares contact-consumer and button-callback receipt times. Wait for the final mouse report.")
            }
            if options.postsTestShortcut {
                print("ACTION TEST: Command-W will be sent at most once. Switch to a disposable browser tab, release all keys/buttons, then wait 3 seconds before a light four-finger tap.")
                print("A button event, new contact, changed foreground app or uncertain frame cancels pending output. System gestures remain active.")
            }
            // CLI orchestration commonly pipes stdout; show the capture cue now.
            fflush(nil)
            let capture = ProbeCapture(buttons: buttons, clock: observationClock,
                                       testStartedAt: options.postsTestShortcut ? clock_gettime_nsec_np(CLOCK_UPTIME_RAW) : nil)
            let reason = await withTaskGroup(of: String.self) { group in
                group.addTask { await capture.consume(stream) }
                if options.postsTestShortcut { group.addTask { await capture.pollTest() } }
                if let buttons { group.addTask { await PassiveButtonProbe.run(buffer: buttons, seconds: seconds) } }
                group.addTask {
                    for _ in 0..<(seconds * 10) {
                        do { try await Task.sleep(for: .milliseconds(100)) }
                        catch { return "cancelled" }
                        guard ProbeSession.allowsCapture() else { return "protected-session" }
                    }
                    return "time-limit"
                }
                let reason = await group.next() ?? "stream-ended"
                group.cancelAll()
                return reason
            }
            // Release the callback before producing the shareable report.
            device.stop()
            print("capture_ended=\(reason)")
            if let buttons {
                if reason == "protected-session" { buttons.state.withLock { $0.stop() } }
                let report = buttons.state.withLock { ($0.records, $0.observed, $0.omitted, $0.installed) }
                print("mouse_observer_installed=\(report.3)")
                for record in report.0 {
                    let encoder = JSONEncoder()
                    encoder.outputFormatting = .sortedKeys
                    if let data = try? encoder.encode(record), let text = String(data: data, encoding: .utf8) {
                        print("mouse_button_observation=\(text)")
                    }
                }
                print("mouse_button_events=\(report.1); mouse_button_events_omitted=\(report.2)")
                if reason == "mouse-observation-unavailable" {
                    print("macOS refused mouse observation. Check Input Monitoring for the launcher (such as Terminal) and restart it. No permission request was made.")
                }
            }
            print("short_contact_candidates_3=\(capture.threeFingerCandidates); short_contact_candidates_4=\(capture.fourFingerCandidates)")
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys]
            if let data = try? encoder.encode(capture.statistics), let report = String(data: data, encoding: .utf8) {
                print(report)
            }
            fflush(nil)
        }
    }

    private static func printTestAccess(_ access: ProbeTestAccess) {
        print("accessibility_trusted=\(access.accessibility); event_posting_allowed=\(access.posting)")
    }
}

@MainActor private final class ProbeCapture {
    private(set) var statistics = ProbeStatistics()
    private var printedTransitions = 0
    private var printedCandidates = 0
    private var printedActionDecisions = 0
    private var recognizer = ShortContactRecognizer()
    private(set) var threeFingerCandidates = 0
    private(set) var fourFingerCandidates = 0
    private let buttons: ButtonObservationBuffer?
    private let clock: ProbeObservationClock
    private var closeGate: FourFingerCloseGate?
    private var closeTarget: pid_t?
    private var lastTestNativeTime: Double?

    init(buttons: ButtonObservationBuffer?, clock: ProbeObservationClock, testStartedAt: UInt64?) {
        self.buttons = buttons
        self.clock = clock
        closeGate = testStartedAt.map { FourFingerCloseGate(startedAt: $0) }
    }

    func consume(_ stream: AsyncStream<[MTContact]>) async -> String {
        defer {
            recognizer.interrupt()
            cancelTest()
            buttons?.state.withLock { $0.updateContacts(nil, at: 0) }
        }
        for await contacts in stream {
            guard !Task.isCancelled else { return "cancelled" }
            guard ProbeSession.allowsCapture() else { return "protected-session" }
            guard contacts.count <= 16 else { return "incompatible-frame" }
            // Timestamp once, before aggregation/classification/printing.
            let receivedAt = clock_gettime_nsec_np(CLOCK_UPTIME_RAW)
            let active = contacts.count { $0.contactState == .making || $0.contactState == .touching }
            let states = Set(contacts.map { Int($0.contactState.rawValue) })
            let pressure = contacts.map(\.pressure).max() ?? 0
            let rejectedBefore = statistics.rejectedFrames
            let discontinuitiesBefore = statistics.nonconsecutiveFrameIDs
            let changed = statistics.observe(count: active, states: states, peakPressure: pressure,
                                             frame: contacts.first?.frame)
            if statistics.nonconsecutiveFrameIDs != discontinuitiesBefore { cancelTest(reason: .frameGap) }
            if statistics.rejectedFrames == rejectedBefore,
               contacts.allSatisfy({ $0.pressure.isFinite && $0.pressure >= 0 }) {
                if let buttons {
                    let snapshot = buttons.state.withLock { ($0.observed, $0.installed && !$0.disabled && !$0.stopRequested && $0.omitted == 0) }
                    closeGate?.contacts(active, at: receivedAt, buttons: snapshot.0, observerReady: snapshot.1)
                    reportCancellation(at: receivedAt)
                }
                buttons?.state.withLock { $0.updateContacts(active, at: receivedAt) }
                observeCandidate(contacts, receivedAt: receivedAt)
            } else {
                buttons?.state.withLock { $0.updateContacts(nil, at: 0) }
                recognizer.interrupt()
                cancelTest(reason: .invalidMetadata)
            }
            if changed, printedTransitions < (buttons == nil ? 64 : 128) {
                if buttons != nil {
                    let observation = ContactObservation(contacts: active, elapsedMilliseconds: clock.elapsedMilliseconds(at: receivedAt))
                    printObservation(observation, prefix: "contact_observation")
                } else {
                    print("contacts=\(active)")
                }
                printedTransitions += 1
            }
        }
        return "stream-ended"
    }

    private func observeCandidate(_ contacts: [MTContact], receivedAt: UInt64) {
        guard let first = contacts.first else {
            recognizer.interrupt(isNeutral: true)
            // It cannot complete an active stroke. Preserve a previously
            // qualified release while the observer checks delayed clicks.
            lastTestNativeTime = nil
            if let buttons {
                let snapshot = buttons.state.withLock { ($0.observed, $0.installed && !$0.disabled && !$0.stopRequested && $0.omitted == 0) }
                closeGate?.emptyFrame(at: receivedAt, buttons: snapshot.0, observerReady: snapshot.1)
                reportCancellation(at: receivedAt)
            }
            return
        }
        guard contacts.allSatisfy({ $0.frame == first.frame && $0.timestamp == first.timestamp }) else {
            recognizer.interrupt()
            cancelTest(reason: .invalidMetadata)
            return
        }
        let active = contacts.filter { $0.contactState == .making || $0.contactState == .touching }
        let values = active.map {
            ShortContactRecognizer.Contact(id: $0.id, x: $0.normalizedVector.position.x,
                                           y: $0.normalizedVector.position.y, pressure: $0.pressure)
        }
        guard first.timestamp.isFinite, first.timestamp >= 0,
              Set(values.map(\.id)).count == values.count,
              values.allSatisfy({ $0.x.isFinite && $0.y.isFinite && (0...1).contains($0.x) && (0...1).contains($0.y) }) else {
            recognizer.interrupt()
            cancelTest(reason: .invalidMetadata)
            return
        }
        if closeGate != nil {
            if let lastTestNativeTime, first.timestamp <= lastTestNativeTime { cancelTest(reason: .nativeTime) }
            lastTestNativeTime = first.timestamp
        }
        guard let candidate = recognizer.consume(frame: first.frame, time: first.timestamp, contacts: values) else { return }
        if let buttons {
            let snapshot = buttons.state.withLock { ($0.observed, $0.installed && !$0.disabled && !$0.stopRequested && $0.omitted == 0) }
            if closeGate?.candidate(fingers: candidate.fingers, at: receivedAt,
                                    buttons: snapshot.0, observerReady: snapshot.1) == true {
                closeTarget = FourFingerCloseSender.target()
                printActionDecision(.waiting, reason: nil, at: receivedAt)
                if closeTarget == nil { cancelTest(reason: .targetUnavailable) }
            } else if closeGate != nil {
                printActionDecision(.rejected, reason: closeGate?.rejection, at: receivedAt)
            }
        }
        if candidate.fingers == 3 { threeFingerCandidates += 1 } else { fourFingerCandidates += 1 }
        guard printedCandidates < 64 else { return }
        printedCandidates += 1
        if buttons != nil {
            let observation = CandidateObservation(candidate, elapsedMilliseconds: clock.elapsedMilliseconds(at: receivedAt))
            printObservation(observation, prefix: "short_contact_candidate")
        } else {
            printObservation(candidate, prefix: "short_contact_candidate")
        }
        fflush(nil)
    }

    private func printObservation(_ observation: some Encodable, prefix: String) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        if let data = try? encoder.encode(observation), let report = String(data: data, encoding: .utf8) {
            print("\(prefix)=\(report)")
        }
    }

    private func cancelTest(reason: FourFingerCloseGate.Reason = .sessionEnded) {
        closeGate?.cancel(reason: reason)
        closeTarget = nil
        reportCancellation(at: clock_gettime_nsec_np(CLOCK_UPTIME_RAW))
    }

    private func reportCancellation(at time: UInt64) {
        if let reason = closeGate?.takeCancellation() {
            closeTarget = nil
            printActionDecision(.cancelled, reason: reason, at: time)
        }
    }

    private func printActionDecision(_ phase: ActionTestObservation.Phase,
                                     reason: FourFingerCloseGate.Reason?, at time: UInt64) {
        guard printedActionDecisions < 64 else { return }
        printedActionDecisions += 1
        printObservation(ActionTestObservation(phase: phase, reason: reason,
                                              elapsedMilliseconds: clock.elapsedMilliseconds(at: time)),
                         prefix: "four_finger_action")
        fflush(nil)
    }

    func pollTest() async -> String {
        defer { cancelTest() }
        while !Task.isCancelled {
            do { try await Task.sleep(for: .milliseconds(10)) }
            catch { return "cancelled" }
            guard !Task.isCancelled, ProbeSession.allowsCapture() else { return "protected-session" }
            guard let buttons else { return "mouse-observation-unavailable" }
            if let expected = closeTarget, FourFingerCloseSender.target() != expected { cancelTest(reason: .foregroundChanged) }
            let snapshot = buttons.state.withLock { ($0.observed, $0.installed && !$0.disabled && !$0.stopRequested && $0.omitted == 0) }
            let now = clock_gettime_nsec_np(CLOCK_UPTIME_RAW)
            if closeGate?.takeReady(at: now, buttons: snapshot.0, observerReady: snapshot.1) == true {
                guard let target = closeTarget else { return "shortcut-test-cancelled" }
                let outcome = FourFingerCloseSender.send(to: target)
                let posted = outcome == .posted
                print("four_finger_shortcut_result=\(outcome.rawValue)")
                print("four_finger_shortcut_posted=\(posted); delivery_requires_manual_check=true")
                fflush(nil)
                return posted ? "shortcut-posted" : "shortcut-test-unavailable"
            }
            if closeGate?.hasPending == false { closeTarget = nil }
            reportCancellation(at: now)
        }
        return "cancelled"
    }
}
