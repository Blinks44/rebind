import Foundation
import Synchronization
import Testing
@testable import rebind

struct GestureButtonInputTests {
    @Test func concurrentConnectionReportsRemainBalancedThroughStop() {
        let input = GestureButtonInput()
        let changes = Mutex<[Bool]>([])
        let changed: @Sendable (Bool) -> Void = { value in changes.withLock { $0.append(value) } }
        DispatchQueue.concurrentPerform(iterations: 16) { _ in
            let connection = UUID()
            let generation = input.configure(connection: connection, indices: [1], changed: changed)
            for _ in 0..<20 {
                input.receive(connection: connection, generation: generation, index: 1, down: true, changed: changed)
                input.receive(connection: connection, generation: generation, index: 1, down: false, changed: changed)
            }
            input.remove(connection: connection, changed: changed)
        }
        input.removeAll(changed: changed)
        let delivered = changes.withLock { $0 }
        #expect(delivered.isEmpty == false && delivered.count.isMultiple(of: 2))
        #expect(delivered.enumerated().allSatisfy { $0.element == $0.offset.isMultiple(of: 2) })
    }

    @Test func receiverSlotsAndSeparateConnectionsHoldOneTriggerUntilTheLastRelease() {
        let input = GestureButtonInput()
        let receiver = UUID(), direct = UUID()
        var changes: [Bool] = []
        let changed = { changes.append($0) }
        let first = input.configure(connection: receiver, indices: [1, 2], changed: changed)
        let second = input.configure(connection: direct, indices: [255], changed: changed)
        input.receive(connection: receiver, generation: first, index: 1, down: true, changed: changed)
        input.receive(connection: receiver, generation: first, index: 2, down: true, changed: changed)
        input.receive(connection: direct, generation: second, index: 255, down: true, changed: changed)
        input.receive(connection: receiver, generation: first, index: 1, down: false, changed: changed)
        input.receive(connection: receiver, generation: first, index: 2, down: false, changed: changed)
        #expect(changes == [true])
        input.receive(connection: direct, generation: second, index: 255, down: false, changed: changed)
        #expect(changes == [true, false])
    }

    @Test func refreshPreservesAnActivePressButRejectsEventsFromTheReplacedHandler() {
        let input = GestureButtonInput(), connection = UUID()
        var changes: [Bool] = []
        let changed = { changes.append($0) }
        let old = input.configure(connection: connection, indices: [1], changed: changed)
        input.receive(connection: connection, generation: old, index: 1, down: true, changed: changed)
        let current = input.configure(connection: connection, indices: [1], changed: changed)
        input.receive(connection: connection, generation: old, index: 1, down: false, changed: changed)
        #expect(changes == [true])
        input.receive(connection: connection, generation: current, index: 1, down: false, changed: changed)
        input.receive(connection: connection, generation: old, index: 1, down: true, changed: changed)
        input.remove(connection: connection, changed: changed)
        input.receive(connection: connection, generation: current, index: 1, down: true, changed: changed)
        #expect(changes == [true, false])
    }

    @Test func reconfigurationDisconnectAndStopReleaseOnlyWhatTheyOwnAndRejectLateReports() {
        let input = GestureButtonInput()
        let first = UUID(), second = UUID()
        var changes: [Bool] = []
        let changed = { changes.append($0) }
        let a = input.configure(connection: first, indices: [1], changed: changed)
        let b = input.configure(connection: second, indices: [2], changed: changed)
        input.receive(connection: first, generation: a, index: 1, down: true, changed: changed)
        input.receive(connection: second, generation: b, index: 2, down: true, changed: changed)
        _ = input.configure(connection: first, indices: [], changed: changed)
        #expect(changes == [true])
        input.remove(connection: second, changed: changed)
        #expect(changes == [true, false])
        let c = input.configure(connection: first, indices: [1], changed: changed)
        input.receive(connection: first, generation: c, index: 1, down: true, changed: changed)
        input.removeAll(changed: changed)
        input.receive(connection: first, generation: c, index: 1, down: true, changed: changed)
        input.receive(connection: second, generation: b, index: 2, down: true, changed: changed)
        #expect(changes == [true, false, true, false])
    }
}
