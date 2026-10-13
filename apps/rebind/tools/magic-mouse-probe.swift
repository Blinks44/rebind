// Magic Mouse feasibility probe for SPEC §3.5 / PLAN Phase 6. Not part of Rebind.app.
//
//   DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun swift apps/rebind/tools/magic-mouse-probe.swift [seconds]
//
// Lists multitouch devices, then observes contact frames from every external one
// for the given time (default 30 s, 1–60). It only counts contacts: nothing is
// suppressed, posted or stored, and no permission is required. Private
// MultitouchSupport ABI offsets match apps/rebind/rebind/Engine/Trackpad/NativeTrackpadBuffer.swift.

import CoreGraphics
import Foundation

typealias Device = UnsafeMutableRawPointer
typealias Callback = @convention(c) (Device, UnsafeMutableRawPointer?, Int32, Double, Int32, UnsafeMutableRawPointer) -> Void

final class Observation {
    let lock = NSLock()
    var frames = 0
    var invalid = 0
    var histogram = [Int](repeating: 0, count: 17)
    var pressedHistogram = [Int](repeating: 0, count: 17)
    var minX = Float.infinity, maxX = -Float.infinity, minY = Float.infinity, maxY = -Float.infinity

    func receive(_ data: UnsafeRawPointer?, count: Int32) {
        lock.lock(); defer { lock.unlock() }
        frames += 1
        guard (0...16).contains(count), count == 0 || data != nil else { invalid += 1; return }
        var touching = 0
        for index in 0..<Int(count) {
            let contact = data!.advanced(by: index * 96)
            let state = contact.loadUnaligned(fromByteOffset: 20, as: Int32.self)
            let x = contact.loadUnaligned(fromByteOffset: 32, as: Float.self)
            let y = contact.loadUnaligned(fromByteOffset: 36, as: Float.self)
            guard (0...7).contains(state), x.isFinite, y.isFinite else { invalid += 1; return }
            guard state == 3 || state == 4 else { continue }
            touching += 1
            minX = min(minX, x); maxX = max(maxX, x); minY = min(minY, y); maxY = max(maxY, y)
        }
        histogram[touching] += 1
        if CGEventSource.buttonState(.combinedSessionState, button: .left)
            || CGEventSource.buttonState(.combinedSessionState, button: .right) { pressedHistogram[touching] += 1 }
    }
}

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
let register = symbol("MTRegisterContactFrameCallbackWithRefcon", as: (@convention(c) (Device, Callback?, UnsafeMutableRawPointer?) -> Bool).self)
let start = symbol("MTDeviceStart", as: (@convention(c) (Device, Int32) -> Int32).self)
let stop = symbol("MTDeviceStop", as: (@convention(c) (Device) -> Int32).self)

let version = ProcessInfo.processInfo.operatingSystemVersionString
print("macOS \(version)")
let devices = (createList()?.takeRetainedValue() as? [AnyObject] ?? []).map { Unmanaged.passUnretained($0).toOpaque() }
var observed: [(Int32, Device, Observation)] = []
for device in devices {
    var family: Int32 = 0, width: Int32 = 0, height: Int32 = 0
    _ = familyID(device, &family)
    _ = dimensions(device, &width, &height)
    let builtIn = isBuiltIn(device)
    print("device family=\(family) built_in=\(builtIn) surface=\(width)x\(height) (1/100 mm)")
    guard !builtIn else { continue }
    let observation = Observation()
    let context = Unmanaged.passRetained(observation).toOpaque()
    let registered = register(device, { _, data, count, _, _, context in
        Unmanaged<Observation>.fromOpaque(context).takeUnretainedValue().receive(data, count: count)
    }, context)
    guard registered, start(device, 0) == 0 else { print("  could not start this device"); continue }
    observed.append((family, device, observation))
}
guard !observed.isEmpty else {
    print("No external multitouch device is connected. Turn the Magic Mouse on and run again."); exit(2)
}
print("Observing \(observed.count) external device(s) for \(Int(seconds)) s…")
Thread.sleep(forTimeInterval: seconds)
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
