// Magic Mouse feasibility probe for SPEC §3.5 / PLAN Phase 6. Not part of Rebind.app.
//
//   DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun swift apps/rebind/tools/magic-mouse-probe.swift [seconds | --guided | --rest | --self-test]
//
// Lists multitouch devices, then observes contact frames from every external one
// for the given time (default 30 s, 1–60). It measures contacts: nothing is
// suppressed, posted or stored. OS access restrictions can still prevent capture. Private
// MultitouchSupport ABI offsets match apps/rebind/rebind/Engine/Trackpad/NativeTrackpadBuffer.swift.

import CoreGraphics
import Foundation

typealias Device = UnsafeMutableRawPointer
typealias Callback = @convention(c) (Device, UnsafeMutableRawPointer?, Int32, Double, Int32, UnsafeMutableRawPointer) -> Void

struct ContactSequence {
    var began: Double
    var ended: Double
    var peak: Int
    var clicked: Bool
    var originX: Float
    var originY: Float
    var lastCount: Int
    var movement: Float = 0
    var countBegan: Double = 0
    var peakDuration: Double = 0

    // Probe-only thresholds based on the named hardware samples in INPUT-012.
    // Centroid motion and sampled button state are not production safety proof.
    var verdict: String {
        let duration = ended - began
        guard began.isFinite, ended.isFinite, duration >= 0, movement.isFinite else { return "rejected: invalid timing/motion" }
        guard !clicked else { return "rejected: physical button observed" }
        guard duration >= 0.020 else { return "rejected: contact too short" }
        guard duration <= 0.200 else { return "rejected: contact too long" }
        guard (1...2).contains(peak) else { return "rejected: only 1/2-finger tap candidates enabled" }
        guard movement <= 0.025 else { return "rejected: movement" }
        guard peakDuration >= 0.020 else { return "rejected: finger count too brief" }
        return "candidate: \(peak)-finger tap"
    }
}

final class Observation {
    let lock = NSLock()
    var frames = 0
    var invalid = 0
    var histogram = [Int](repeating: 0, count: 17)
    var pressedHistogram = [Int](repeating: 0, count: 17)
    var minX = Float.infinity, maxX = -Float.infinity, minY = Float.infinity, maxY = -Float.infinity

    // Bounded sequence storage; callback performs no console/file I/O.
    var sequences: [ContactSequence] = []
    var current: ContactSequence?
    var dropped = 0
    var armed = false
    var lastTouching: Int?
    var skippedFrames = 0

    init() { sequences.reserveCapacity(256) }

    func sample(touching: Int, x: Float, y: Float, time: Double, pressed: Bool) {
        // Caller holds lock. Movement is centroid displacement within a segment
        // of unchanged contact count, in normalized sensor coordinates.
        lastTouching = touching
        if touching == 0 {
            if var sequence = current {
                sequence.ended = time
                if sequence.lastCount == sequence.peak {
                    sequence.peakDuration = max(sequence.peakDuration, time - sequence.countBegan)
                }
                sequence.clicked = sequence.clicked || pressed
                if sequences.count < 256 { sequences.append(sequence) } else { dropped += 1 }
            }
            current = nil
            armed = true
            return
        }
        guard armed else { skippedFrames += 1; return }
        if current == nil {
            current = ContactSequence(began: time, ended: time, peak: touching,
                                      clicked: pressed, originX: x, originY: y, lastCount: touching, countBegan: time)
        }
        guard var sequence = current else { return }
        if sequence.lastCount == sequence.peak {
            sequence.peakDuration = max(sequence.peakDuration, time - sequence.countBegan)
        }
        if touching > sequence.peak { sequence.peakDuration = 0 }
        if sequence.lastCount != touching {
            sequence.countBegan = time
            sequence.originX = x; sequence.originY = y
        }
        let dx = x - sequence.originX, dy = y - sequence.originY
        sequence.movement = max(sequence.movement, (dx * dx + dy * dy).squareRoot())
        sequence.ended = time
        sequence.peak = max(sequence.peak, touching)
        sequence.clicked = sequence.clicked || pressed
        sequence.lastCount = touching
        current = sequence
    }

    func markButton(_ pressed: Bool, at time: Double = ProcessInfo.processInfo.systemUptime) {
        guard pressed else { return }
        lock.lock(); defer { lock.unlock() }
        current?.clicked = true
        // A physical button event can follow the last contact frame. Retrospective
        // diagnostics keep a 60 ms exclusion interval, matching the trackpad gate.
        if let last = sequences.indices.last, time >= sequences[last].ended,
           time - sequences[last].ended <= 0.060 { sequences[last].clicked = true }
    }

    func reset() {
        lock.lock(); defer { lock.unlock() }
        frames = 0; invalid = 0
        histogram = [Int](repeating: 0, count: 17)
        pressedHistogram = [Int](repeating: 0, count: 17)
        minX = .infinity; maxX = -.infinity; minY = .infinity; maxY = -.infinity
        sequences.removeAll(keepingCapacity: true); current = nil; dropped = 0; skippedFrames = 0
        // An idle device need not emit another empty frame after the phase starts.
        // Preserve the last observed neutral state instead of discarding it.
        armed = lastTouching == 0
    }

    func reportSequences() {
        lock.lock()
        let completed = sequences, unfinished = current, lost = dropped
        let frameCount = frames, invalidCount = invalid, counts = histogram
        let skipped = skippedFrames, lastCount = lastTouching
        lock.unlock()
        print("  frames=\(frameCount) invalid=\(invalidCount) contacts→frames " + counts.enumerated()
            .filter { $0.element > 0 }.map { "\($0.offset):\($0.element)" }.joined(separator: " "))
        print("  last_contacts=\(lastCount.map(String.init) ?? "unknown") boundary_skipped_frames=\(skipped)")
        for (index, sequence) in completed.enumerated() {
            print(String(format: "  sequence %d: peak=%d duration=%.0fms movement=%.3f button=%@",
                         index + 1, sequence.peak, (sequence.ended - sequence.began) * 1000,
                         sequence.movement, sequence.clicked ? "down" : "none observed"))
            print("    \(sequence.verdict)")
        }
        let candidates = completed.filter { $0.verdict.hasPrefix("candidate:") }.count
        print("  tap_candidates=\(candidates) rejected=\(completed.count - candidates)")
        if unfinished != nil { print("  Unfinished contact sequence at phase end (not a completed tap).") }
        if completed.isEmpty { print("  No completed contact sequences.") }
        if lost > 0 { print("  Sequence limit reached; omitted \(lost) sequences.") }
    }

    func receive(_ data: UnsafeRawPointer?, count: Int32) {
        lock.lock(); defer { lock.unlock() }
        frames += 1
        guard (0...16).contains(count), count == 0 || data != nil else { invalid += 1; current = nil; armed = false; lastTouching = nil; return }
        var touching = 0
        var sumX: Float = 0, sumY: Float = 0
        for index in 0..<Int(count) {
            let contact = data!.advanced(by: index * 96)
            let state = contact.loadUnaligned(fromByteOffset: 20, as: Int32.self)
            let x = contact.loadUnaligned(fromByteOffset: 32, as: Float.self)
            let y = contact.loadUnaligned(fromByteOffset: 36, as: Float.self)
            guard (0...7).contains(state), x.isFinite, y.isFinite else { invalid += 1; current = nil; armed = false; lastTouching = nil; return }
            guard state == 3 || state == 4 else { continue }
            touching += 1
            sumX += x; sumY += y
            minX = min(minX, x); maxX = max(maxX, x); minY = min(minY, y); maxY = max(maxY, y)
        }
        histogram[touching] += 1
        let pressed = buttonPressed()
        if pressed { pressedHistogram[touching] += 1 }
        sample(touching: touching, x: touching > 0 ? sumX / Float(touching) : 0,
               y: touching > 0 ? sumY / Float(touching) : 0,
               time: ProcessInfo.processInfo.systemUptime, pressed: pressed)
    }
}

func buttonPressed() -> Bool {
    CGEventSource.buttonState(.combinedSessionState, button: .left)
        || CGEventSource.buttonState(.combinedSessionState, button: .right)
}

func runSelfTests() {
    var checks = 0
    func check(_ condition: @autoclosure () -> Bool, _ name: String) {
        guard condition() else { fatalError("FAILED: \(name)") }
        checks += 1
    }
    func sequence(_ fingers: Int = 1, _ duration: Double = 0.100,
                  _ movement: Float = 0.005, clicked: Bool = false,
                  peakDuration: Double = 0.050) -> ContactSequence {
        ContactSequence(began: 0, ended: duration, peak: fingers, clicked: clicked,
                        originX: 0.5, originY: 0.5, lastCount: fingers,
                        movement: movement, peakDuration: peakDuration)
    }
    check(sequence().verdict == "candidate: 1-finger tap", "one-finger tap")
    check(sequence(2, 0.134).verdict == "candidate: 2-finger tap", "two-finger tap")
    check(sequence(1, 0.022).verdict.hasPrefix("candidate:"), "fast observed tap")
    check(sequence(1, 0.019).verdict.contains("too short"), "brief contact")
    check(sequence(1, 2.819).verdict.contains("too long"), "rest rejected")
    check(sequence(1, 0.101, 0.222).verdict.contains("movement"), "fast scroll rejected")
    check(sequence(1, 0.135, clicked: true).verdict.contains("button"), "fast physical click rejected")
    check(sequence(3).verdict.contains("only 1/2"), "unqualified finger count")
    check(sequence(2, peakDuration: 0.005).verdict.contains("too brief"), "transient extra finger")
    check(sequence(1, .nan).verdict.contains("invalid"), "invalid timing")

    // User-labelled INPUT-012 summaries are classification fixtures, not raw replay.
    for (duration, movement) in [(0.022, Float(0.003)), (0.043, 0.003), (0.078, 0.007), (0.078, 0.002), (0.101, 0.007)] {
        check(sequence(1, duration, movement).verdict.hasPrefix("candidate:"), "reported one-finger tap")
    }
    for (duration, movement) in [(0.112, Float(0.001)), (0.112, 0.004), (0.113, 0.005), (0.113, 0.004), (0.134, 0.003)] {
        check(sequence(2, duration, movement).verdict.hasPrefix("candidate:"), "reported two-finger tap")
    }
    for (duration, movement) in [(0.381, Float(0.082)), (0.124, 0.239), (0.157, 0.123), (0.169, 0.092), (0.799, 0.191), (0.382, 0.245), (0.101, 0.222), (0.134, 0.232), (0.191, 0.241)] {
        check(sequence(1, duration, movement).verdict.hasPrefix("rejected:"), "reported scroll")
    }
    for duration in [0.204, 0.258, 0.270, 0.180, 0.404, 0.326, 0.282, 0.270, 0.135, 0.156] {
        check(sequence(1, duration, clicked: true).verdict.contains("button"), "reported click/double click")
    }

    let observation = Observation()
    observation.sample(touching: 0, x: 0, y: 0, time: 0, pressed: false)
    observation.reset()
    observation.sample(touching: 2, x: 0.5, y: 0.5, time: 1, pressed: false)
    observation.sample(touching: 0, x: 0, y: 0, time: 1.1, pressed: false)
    check(observation.sequences.count == 1 && observation.skippedFrames == 0, "idle baseline across reset")
    check(observation.sequences[0].verdict.hasPrefix("candidate:"), "completed contact only")
    observation.markButton(true, at: 1.112)
    check(observation.sequences[0].verdict.contains("button"), "button 12 ms after release")
    observation.reset()
    observation.sample(touching: 2, x: 0.5, y: 0.5, time: 2, pressed: false)
    observation.reset()
    observation.sample(touching: 2, x: 0.5, y: 0.5, time: 2.1, pressed: false)
    observation.sample(touching: 0, x: 0, y: 0, time: 2.2, pressed: false)
    check(observation.sequences.isEmpty && observation.skippedFrames == 1, "active phase boundary excluded")
    observation.receive(nil, count: -1)
    check(observation.lastTouching == nil && !observation.armed, "invalid input cancels baseline")
    print("Passed \(checks) probe recognition checks. No device opened or input posted.")
}

if CommandLine.arguments.contains("--self-test") {
    runSelfTests()
    exit(0)
}

let restOnly = CommandLine.arguments.contains("--rest")
let guided = restOnly || CommandLine.arguments.contains("--guided")
let seconds = min(max(CommandLine.arguments.dropFirst().first.flatMap(Double.init) ?? 30, 1), 60)
guard let handle = dlopen("/System/Library/PrivateFrameworks/MultitouchSupport.framework/MultitouchSupport", RTLD_LAZY) else {
    print("MultitouchSupport is unavailable"); exit(1)
}
func symbol<T>(_ name: String, as type: T.Type) -> T {
    guard let address = dlsym(handle, name) else { print("Missing symbol \(name)"); exit(1) }
    return unsafeBitCast(address, to: type)
}
let createList = symbol("MTDeviceCreateList", as: (@convention(c) () -> Unmanaged<CFArray>?).self)
let isBuiltIn = symbol("MTDeviceIsBuiltIn", as: (@convention(c) (Device) -> Bool).self)
let familyID = symbol("MTDeviceGetFamilyID", as: (@convention(c) (Device, UnsafeMutablePointer<Int32>) -> Int32).self)
let dimensions = symbol("MTDeviceGetSensorSurfaceDimensions",
                        as: (@convention(c) (Device, UnsafeMutablePointer<Int32>, UnsafeMutablePointer<Int32>) -> Int32).self)
// Registration has no documented Boolean success result; do not gate start on it.
let register = symbol("MTRegisterContactFrameCallbackWithRefcon", as: (@convention(c) (Device, Callback?, UnsafeMutableRawPointer?) -> Void).self)
let start = symbol("MTDeviceStart", as: (@convention(c) (Device, Int32) -> Int32).self)
let stop = symbol("MTDeviceStop", as: (@convention(c) (Device) -> Int32).self)

let version = ProcessInfo.processInfo.operatingSystemVersionString
print("macOS \(version)")
// Keep the owning objects alive while callbacks use the raw device pointers.
let deviceObjects = createList()?.takeRetainedValue() as? [AnyObject] ?? []
let devices = deviceObjects.map { Unmanaged.passUnretained($0).toOpaque() }
var observed: [(Int32, Device, Observation)] = []
var externalCount = 0
for device in devices {
    var family: Int32 = 0, width: Int32 = 0, height: Int32 = 0
    _ = familyID(device, &family)
    _ = dimensions(device, &width, &height)
    let builtIn = isBuiltIn(device)
    print("device family=\(family) built_in=\(builtIn) surface=\(width)x\(height) (1/100 mm)")
    guard !builtIn else { continue }
    externalCount += 1
    let observation = Observation()
    let context = Unmanaged.passRetained(observation).toOpaque()
    register(device, { _, data, count, _, _, context in
        Unmanaged<Observation>.fromOpaque(context).takeUnretainedValue().receive(data, count: count)
    }, context)
    let status = start(device, 0)
    guard status == 0 else {
        print(String(format: "  MTDeviceStart failed: %d (0x%08X)", status, UInt32(bitPattern: status)))
        continue
    }
    observed.append((family, device, observation))
}
guard !observed.isEmpty else {
    if externalCount == 0 {
        print("No external multitouch device was found. Turn the Magic Mouse on and run again.")
    } else {
        print("Found \(externalCount) external multitouch device(s), but none started. See MTDeviceStart status above.")
    }
    exit(2)
}
print(guided ? "Observing \(observed.count) external device(s) in guided mode…"
      : "Observing \(observed.count) external device(s) for \(Int(seconds)) s…")
if guided {
    print("Guided observation: use only the Magic Mouse; lift all fingers between attempts.")
    print("Button state is session-wide and sampled, so very short clicks can be missed.")
    print("Tap candidates: 1/2 fingers, 20–200 ms, centroid movement at most 0.025, no observed button.")
    print("No actions are performed. Native gestures remain active; candidates are provisional.")
    let phases = restOnly ? [
        "REST: hold 3 fingers still for 4 seconds, then lift your entire hand and wait."
    ] : [
        "ONE-FINGER TAP: lift all fingers first, then make 5 light taps without clicking, lifting completely each time.",
        "TWO-FINGER TAP: make 5 simultaneous two-finger taps without clicking; lift fully.",
        "REST: rest fingers on the surface for 5 seconds, then lift completely.",
        "PHYSICAL CLICK: make 5 ordinary clicks, lifting fingers between attempts.",
        "DOUBLE CLICK: make 3 ordinary double clicks, lifting between pairs.",
        "SCROLL: scroll up/down normally, then lift completely.",
        "THREE/FOUR CONTACTS: place 3 fingers, lift; then 4 fingers, lift. Do not click."
    ]
    print("Preparation: briefly touch the mouse, then lift ALL fingers to establish an empty surface. You have 5 seconds.")
    Thread.sleep(forTimeInterval: 5)
    let window: Double = restOnly ? 12 : 8
    for (index, prompt) in phases.enumerated() {
        print("\nPhase \(index + 1)/\(phases.count), starts in 3 seconds: \(prompt)")
        Thread.sleep(forTimeInterval: 3)
        for (_, _, observation) in observed { observation.reset() }
        print("GO — \(Int(window)) seconds")
        let deadline = ProcessInfo.processInfo.systemUptime + window
        while ProcessInfo.processInfo.systemUptime < deadline {
            let pressed = buttonPressed()
            for (_, _, observation) in observed { observation.markButton(pressed) }
            Thread.sleep(forTimeInterval: 0.01)
        }
        let settleUntil = ProcessInfo.processInfo.systemUptime + 0.060
        while ProcessInfo.processInfo.systemUptime < settleUntil {
            let pressed = buttonPressed()
            for (_, _, observation) in observed { observation.markButton(pressed) }
            Thread.sleep(forTimeInterval: 0.005)
        }
        for (family, _, observation) in observed {
            print("family=\(family)")
            observation.reportSequences()
        }
    }
    print("\nFinal histogram below covers the last phase only. Tap candidates are diagnostic, not supported app gestures.")
} else {
    let deadline = ProcessInfo.processInfo.systemUptime + seconds
    while ProcessInfo.processInfo.systemUptime < deadline {
        let pressed = buttonPressed()
        for (_, _, observation) in observed { observation.markButton(pressed) }
        Thread.sleep(forTimeInterval: 0.01)
    }
    for (family, _, observation) in observed {
        print("family=\(family)")
        observation.reportSequences()
    }
}
for (family, device, observation) in observed {
    _ = stop(device)
    observation.lock.lock()
    let counts = observation.histogram.enumerated().filter { $0.element > 0 }.map { "\($0.offset):\($0.element)" }
    let pressed = observation.pressedHistogram.enumerated().filter { $0.element > 0 }.map { "\($0.offset):\($0.element)" }
    print("family=\(family) frames=\(observation.frames) invalid=\(observation.invalid)")
    print("  contacts→frames \(counts.joined(separator: " "))")
    print("  contacts→frames while a button is down \(pressed.joined(separator: " "))")
    if observation.minX.isFinite {
        print(String(format: "  x %.2f…%.2f  y %.2f…%.2f", observation.minX, observation.maxX, observation.minY, observation.maxY))
    }
    observation.lock.unlock()
}
withExtendedLifetime(deviceObjects) {}
