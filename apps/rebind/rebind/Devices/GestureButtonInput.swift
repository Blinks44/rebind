import Foundation
import Synchronization

/// Combines the same category-wide gesture trigger across active connections/receiver slots.
/// Changes and delivery share one short lock, so a release cannot overtake another press.
/// The delivery callback must stay bounded and must not reenter this tracker.
nonisolated final class GestureButtonInput: Sendable {
    private struct Route {
        let generation: UInt64
        let indices: Set<UInt8>
    }
    private struct State {
        var generation: UInt64 = 0
        var routes: [UUID: Route] = [:]
        var pressed: [UUID: Set<UInt8>] = [:]
        var isDown: Bool { pressed.values.contains { !$0.isEmpty } }
    }
    private let state = Mutex(State())

    func configure(connection: UUID, indices: Set<UInt8>, changed: (Bool) -> Void) -> UInt64 {
        state.withLock {
            let wasDown = $0.isDown
            $0.generation &+= 1
            $0.routes[connection] = Route(generation: $0.generation, indices: indices)
            $0.pressed[connection]?.formIntersection(indices)
            if wasDown != $0.isDown { changed($0.isDown) }
            return $0.generation
        }
    }

    func receive(connection: UUID, generation: UInt64, index: UInt8, down: Bool, changed: (Bool) -> Void) {
        state.withLock {
            guard let route = $0.routes[connection], route.generation == generation,
                  route.indices.contains(index) else { return }
            let wasDown = $0.isDown
            if down { $0.pressed[connection, default: []].insert(index) }
            else { $0.pressed[connection]?.remove(index) }
            if wasDown != $0.isDown { changed($0.isDown) }
        }
    }

    func remove(connection: UUID, changed: (Bool) -> Void) {
        state.withLock {
            let wasDown = $0.isDown
            $0.routes[connection] = nil
            $0.pressed[connection] = nil
            if wasDown != $0.isDown { changed($0.isDown) }
        }
    }

    func removeAll(changed: (Bool) -> Void) {
        state.withLock {
            let wasDown = $0.isDown
            $0.routes = [:]
            $0.pressed = [:]
            if wasDown { changed(false) }
        }
    }
}
