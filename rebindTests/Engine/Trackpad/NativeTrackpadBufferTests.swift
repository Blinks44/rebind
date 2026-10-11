import Foundation
import Synchronization
import Testing
@testable import rebind

struct NativeTrackpadBufferTests {
    private func records(_ count: Int, state: Int32 = 4) -> UnsafeMutableRawPointer {
        let pointer = UnsafeMutableRawPointer.allocate(byteCount: max(1, count) * 96, alignment: 8)
        pointer.initializeMemory(as: UInt8.self, repeating: 0, count: max(1, count) * 96)
        for index in 0..<count {
            let record = pointer.advanced(by: index * 96)
            record.storeBytes(of: Int32(10), as: Int32.self)
            record.storeBytes(of: Double(1), toByteOffset: 8, as: Double.self)
            record.storeBytes(of: Int32(index), toByteOffset: 16, as: Int32.self)
            record.storeBytes(of: state, toByteOffset: 20, as: Int32.self)
            record.storeBytes(of: Float(0.2), toByteOffset: 32, as: Float.self)
            record.storeBytes(of: Float(0.5), toByteOffset: 36, as: Float.self)
            record.storeBytes(of: Float(45), toByteOffset: 52, as: Float.self)
        }
        return pointer
    }

    @Test(arguments: [-1, 17, Int32.max]) func invalidCountDoesNotReadMemory(_ count: Int32) {
        let frame = NativeTrackpadFrame.read(nil, count: count, receipt: 0, revision: 0, activity: 0)
        #expect(!frame.valid)
    }

    @Test func nilDataIsValidOnlyForAnEmptyFrame() {
        let empty = NativeTrackpadFrame.read(nil, count: 0, receipt: 0, revision: 0, activity: 0)
        let invalid = NativeTrackpadFrame.read(nil, count: 1, receipt: 0, revision: 0, activity: 0)
        #expect(empty.valid && empty.count == 0 && empty.frame == nil && !invalid.valid)
    }

    @Test func callbackTimingSurvivesAnEmptyContactArray() {
        let empty = NativeTrackpadFrame.read(nil, count: 0, receipt: 20, revision: 2, activity: 5,
                                            callbackFrame: 11, callbackTime: 1.02)
        #expect(empty.valid && empty.count == 0 && empty.frame == 11 && empty.time == 1.02)
        #expect(empty.receipt == 20 && empty.revision == 2 && empty.activity == 5)
    }

    @Test func callbackClockIsUsedConsistentlyWithAndWithoutContacts() {
        let pointer = records(4)
        defer { pointer.deallocate() }
        let touching = NativeTrackpadFrame.read(pointer, count: 4, receipt: 0, revision: 0, activity: 0,
                                               callbackFrame: 100, callbackTime: 2)
        let released = NativeTrackpadFrame.read(nil, count: 0, receipt: 1, revision: 0, activity: 0,
                                               callbackFrame: 101, callbackTime: 2.02)
        #expect(touching.valid && touching.count == 4 && touching.frame == 100 && touching.time == 2)
        #expect(released.valid && released.frame == 101 && released.time == 2.02)
    }

    @Test(arguments: [Double.nan, .infinity, -1]) func invalidCallbackTimeRejectsEvenAnEmptyArray(_ time: Double) {
        let result = NativeTrackpadFrame.read(nil, count: 0, receipt: 0, revision: 0, activity: 0,
                                             callbackFrame: 1, callbackTime: time)
        #expect(!result.valid)
    }

    @Test func partialCallbackTimingIsRejected() {
        let missingTime = NativeTrackpadFrame.read(nil, count: 0, receipt: 0, revision: 0, activity: 0, callbackFrame: 1)
        let missingFrame = NativeTrackpadFrame.read(nil, count: 0, receipt: 0, revision: 0, activity: 0, callbackTime: 1)
        #expect(!missingTime.valid && !missingFrame.valid)
    }

    @Test(arguments: 0...7) func onlyMakingAndTouchingStatesCount(_ state: Int32) {
        let pointer = records(4, state: state)
        defer { pointer.deallocate() }
        let frame = NativeTrackpadFrame.read(pointer, count: 4, receipt: 20, revision: 2, activity: 5)
        #expect(frame.valid && frame.frame == 10 && frame.time == 1)
        #expect(frame.count == ([3, 4].contains(state) ? 4 : 0))
        #expect(frame.revision == 2 && frame.activity == 5 && frame.receipt == 20)
    }

    @Test(arguments: 0...6) func uncertainABIRecordsRejectTheWholeFrame(_ scenario: Int) {
        let pointer = records(scenario == 0 ? 5 : 4)
        defer { pointer.deallocate() }
        let record = pointer.advanced(by: 96)
        switch scenario {
        case 0: break // fifth active contact
        case 1: record.storeBytes(of: Int32(0), toByteOffset: 16, as: Int32.self)
        case 2: record.storeBytes(of: Float.nan, toByteOffset: 32, as: Float.self)
        case 3: record.storeBytes(of: Int32(11), as: Int32.self)
        case 4: record.storeBytes(of: Double(2), toByteOffset: 8, as: Double.self)
        case 5: record.storeBytes(of: Int32(8), toByteOffset: 20, as: Int32.self)
        default: record.storeBytes(of: Float(-1), toByteOffset: 52, as: Float.self)
        }
        let frame = NativeTrackpadFrame.read(pointer, count: scenario == 0 ? 5 : 4, receipt: 0, revision: 0, activity: 0)
        #expect(!frame.valid)
    }

    @Test func bufferClosesOnPauseAndNeverRetainsNativePointers() throws {
        let mailbox = EngineMailbox()
        mailbox.state.withLock { $0.status = .active; $0.enabled = true }
        let buffer = NativeTrackpadBuffer(mailbox: mailbox)
        let pointer = records(4)
        defer { pointer.deallocate() }
        buffer.receive(pointer, count: 4)
        #expect(buffer.pop() == nil)
        buffer.setAccepting(true)
        buffer.receive(pointer, count: 4)
        pointer.storeBytes(of: Float(0.9), toByteOffset: 32, as: Float.self)
        let frame = try #require(buffer.pop())
        #expect(frame.first?.x == 0.2)
        for _ in 0..<65 { buffer.receive(nil, count: 0) }
        #expect(buffer.takeOverflow())
        #expect(buffer.pop() == nil)
        buffer.receive(nil, count: 0)
        buffer.setAccepting(false)
        #expect(buffer.pop() == nil && !buffer.takeOverflow())
        buffer.setAccepting(true)
        mailbox.suspend(true)
        buffer.receive(pointer, count: 4)
        #expect(buffer.pop() == nil)
    }

    @Test func overflowQuarantinesFramesUntilAcknowledged() throws {
        let mailbox = EngineMailbox()
        mailbox.state.withLock { $0.status = .active; $0.enabled = true }
        let buffer = NativeTrackpadBuffer(mailbox: mailbox)
        buffer.setAccepting(true)
        for _ in 0..<65 { buffer.receive(nil, count: 0) }
        for id in 0..<100 {
            buffer.receive(nil, count: 0, callbackFrame: Int32(id), callbackTime: Double(id))
        }
        #expect(buffer.pop() == nil)
        #expect(buffer.takeOverflow())
        #expect(buffer.takeOverflow() == false)
        buffer.receive(nil, count: 0, callbackFrame: 200, callbackTime: 200)
        let recovered = try #require(buffer.pop())
        #expect(recovered.frame == 200)
        #expect(buffer.pop() == nil)
    }
}
