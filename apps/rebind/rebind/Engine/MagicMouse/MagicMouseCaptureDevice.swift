import Foundation

/// The main-actor observer boundary; controller tests use an in-memory surface.
@MainActor protocol MagicMouseCaptureDevice: AnyObject {
    var buffer: NativeTrackpadBuffer { get }
    func start() -> Bool
    func stop()
}

extension NativeTrackpadDevice: MagicMouseCaptureDevice {}
