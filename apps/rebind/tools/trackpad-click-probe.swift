// Trackpad click-source probe for INPUT-006. Not part of Rebind.app.
//
//   DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun swift apps/rebind/tools/trackpad-click-probe.swift [seconds]
//
// Prints one line per primary/secondary button event and per Force Touch pressure
// event, next to what the trackpads report at that moment: how many fingers touch,
// for how long, and the two per-contact force-like values. It answers one question:
// which signal tells a physical press from a button event that macOS makes itself
// (three-finger drag from resting fingers, Tap to click). Listen-only: nothing is
// suppressed, posted or stored; no coordinates are printed. The terminal app needs
// Input Monitoring for the button events. Private MultitouchSupport ABI offsets match
// apps/rebind/rebind/Engine/Trackpad/NativeTrackpadBuffer.swift.

import AppKit
import CoreGraphics
import Foundation

typealias Device = UnsafeMutableRawPointer
typealias Callback = @convention(c) (Device, UnsafeMutableRawPointer?, Int32, Double, Int32, UnsafeMutableRawPointer) -> Void

/// The latest frame of one surface; written on the framework's thread, read on the main thread.
final class Surface: @unchecked Sendable {
    let name: String
    let lock = NSLock()
    var count = 0
    var touchedSince: Double?
    var force: Float = 0
    var peak: Float = 0
    var density: Float = 0
    var states = ""
    init(name: String) { self.name = name }

    func update(_ data: UnsafeRawPointer?, count: Int32) {
        var force: Float = 0, density: Float = 0, touching = 0, states = ""
        if let data, (1...16).contains(count) {
            for index in 0..<Int(count) {
                let contact = data.advanced(by: index * 96)
                let state = contact.loadUnaligned(fromByteOffset: 20, as: Int32.self)
                states += String(state)
                guard state == 3 || state == 4 else { continue }
                touching += 1
                // MTFinger.pressure follows size; it carries force only on Force Touch trackpads.
                force = max(force, contact.loadUnaligned(fromByteOffset: 52, as: Float.self))
                density = max(density, contact.loadUnaligned(fromByteOffset: 92, as: Float.self))
            }
        }
        lock.withLock {
            if touching > 0, self.count == 0 { touchedSince = ProcessInfo.processInfo.systemUptime; peak = 0 }
            if touching == 0 { touchedSince = nil }
            self.count = touching; self.force = force; self.density = density; self.states = states
            peak = max(peak, force)
        }
    }

    var summary: String {
        lock.withLock {
            guard count > 0 else { return "\(name)=0" }
            let held = touchedSince.map { Int((ProcessInfo.processInfo.systemUptime - $0) * 1000) } ?? -1
            return "\(name)=\(count) held=\(held)ms force=\(String(format: "%.1f", force)) peak=\(String(format: "%.1f", peak))"
                + " density=\(String(format: "%.2f", density)) states=\(states)"
        }
    }
}

guard let handle = dlopen("/System/Library/PrivateFrameworks/MultitouchSupport.framework/MultitouchSupport", RTLD_LAZY) else {
    print("MultitouchSupport unavailable"); exit(1)
}
func symbol<T>(_ name: String) -> T { unsafeBitCast(dlsym(handle, name)!, to: T.self) }
let createList: @convention(c) () -> Unmanaged<CFArray>? = symbol("MTDeviceCreateList")
let isBuiltIn: @convention(c) (Device) -> Bool = symbol("MTDeviceIsBuiltIn")
let dimensions: @convention(c) (Device, UnsafeMutablePointer<Int32>, UnsafeMutablePointer<Int32>) -> Int32
    = symbol("MTDeviceGetSensorSurfaceDimensions")
let register: @convention(c) (Device, Callback?, UnsafeMutableRawPointer?) -> Bool = symbol("MTRegisterContactFrameCallbackWithRefcon")
let start: @convention(c) (Device, Int32) -> Int32 = symbol("MTDeviceStart")
let supportsForce: @convention(c) (Device) -> Bool = symbol("MTDeviceSupportsForce")

var surfaces: [Surface] = []
let devices = (createList()?.takeRetainedValue() as? [AnyObject]) ?? []
for object in devices {
    let device = Unmanaged.passUnretained(object).toOpaque()
    var width: Int32 = 0, height: Int32 = 0
    // Trackpads only: a Magic Mouse surface is taller than wide.
    guard dimensions(device, &width, &height) == 0, width > height else { continue }
    let surface = Surface(name: isBuiltIn(device) ? "builtin" : "external")
    print("\(surface.name): force touch \(supportsForce(device) ? "yes" : "no")")
    surfaces.append(surface)
    _ = register(device, { _, data, count, _, _, context in
        Unmanaged<Surface>.fromOpaque(context).takeUnretainedValue().update(data, count: count)
    }, Unmanaged.passRetained(surface).toOpaque())
    _ = start(device, 0)
}
print("trackpads: \(surfaces.map(\.name).joined(separator: ", "))")

let began = ProcessInfo.processInfo.systemUptime
func line(_ text: String) {
    let time = String(format: "%7.3f", ProcessInfo.processInfo.systemUptime - began)
    print("\(time) \(text) | \(surfaces.map(\.summary).joined(separator: " "))")
}

let pressureType: UInt64 = 34 // NSEvent.EventType.pressure
let types: [CGEventType] = [.leftMouseDown, .leftMouseUp, .rightMouseDown, .rightMouseUp]
let mask = types.reduce(CGEventMask(1) << pressureType) { $0 | CGEventMask(1) << $1.rawValue }
guard let tap = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .tailAppendEventTap, options: .listenOnly,
                                  eventsOfInterest: mask, callback: { _, type, event, _ in
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput { return Unmanaged.passUnretained(event) }
    let ns = NSEvent(cgEvent: event)
    if UInt64(type.rawValue) == pressureType {
        line("pressure stage=\(ns?.stage ?? -1) value=\(String(format: "%.2f", ns?.pressure ?? -1))")
    } else {
        let name = switch type {
        case .leftMouseDown: "left-down"
        case .leftMouseUp: "left-up"
        case .rightMouseDown: "right-down"
        default: "right-up"
        }
        let fields = [
            "pressure=\(String(format: "%.2f", event.getDoubleValueField(.mouseEventPressure)))",
            "subtype=\(event.getIntegerValueField(.mouseEventSubtype))",
            "clicks=\(event.getIntegerValueField(.mouseEventClickState))",
            // NSEvent.stage throws for button events; only pressure events carry it.
            "nssubtype=\(ns.map { String($0.subtype.rawValue) } ?? "-")",
            "source=\(event.getIntegerValueField(.eventSourceStateID))",
            "pid=\(event.getIntegerValueField(.eventSourceUnixProcessID))"
        ]
        line("\(name) \(fields.joined(separator: " "))")
    }
    return Unmanaged.passUnretained(event)
}, userInfo: nil) else {
    print("Cannot observe button events: give the terminal app Input Monitoring access and run again."); exit(1)
}
let source = CFMachPortCreateRunLoopSource(nil, tap, 0)
CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
CGEvent.tapEnable(tap: tap, enable: true)

let seconds = CommandLine.arguments.dropFirst().first.flatMap(Double.init).map { min(max($0, 5), 120) } ?? 60
print("""
observing for \(Int(seconds)) s. Do each with a pause in between:
  1. rest three fingers still for two seconds, lift without pressing
  2. press (physical click) with three fingers
  3. rest four fingers still for two seconds, lift without pressing
  4. press with four fingers
  5. tap lightly with two fingers, then with three fingers
Repeat on the other trackpad if both are connected.
""")
DispatchQueue.main.asyncAfter(deadline: .now() + seconds) { print("done"); exit(0) }
RunLoop.main.run()
