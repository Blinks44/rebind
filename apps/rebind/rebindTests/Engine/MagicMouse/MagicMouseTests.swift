import CoreGraphics
import Dispatch
import Foundation
import Synchronization
import Testing
@testable import rebind

struct MagicMouseTests {
    private let lift: UInt64 = 4_000_000_000

    private struct Harness {
        let mailbox = EngineMailbox()
        let buffer: NativeTrackpadBuffer
        var runtime: MagicMouseRuntime
        var session: MagicMouseTapSession
        var nextID: Int32 = 0

        init(fingers: [Int] = [1, 2, 3], sides: [MagicMouseSide] = [], modifiers: ModifierSet = [],
             buttonsDown: Bool = false) throws {
            let bindings = fingers.map {
                rebind.Binding(scope: .magicMouse, trigger: .magicMouseTap(fingers: $0), modifiers: modifiers,
                               action: .shortcut(.init(keyCode: UInt16(12 + $0), modifiers: .command)))
            } + sides.map {
                rebind.Binding(scope: .magicMouse, trigger: .magicMouseSideTap($0), modifiers: modifiers,
                               action: .shortcut(.init(keyCode: $0 == .left ? 20 : 21, modifiers: .command)))
            }
            mailbox.configure(Configuration(isEnabled: true, bindings: bindings))
            mailbox.state.withLock { $0.status = .active; $0.foregroundPID = 100 }
            runtime = try #require(mailbox.magicMouseRuntime(modifiers: modifiers, buttonsDown: buttonsDown))
            buffer = NativeTrackpadBuffer(mailbox: mailbox, isMagicMouse: true)
            buffer.setAccepting(true)
            session = MagicMouseTapSession(runtime: runtime, foreground: 100, startedAt: 0)
        }

        mutating func contact(_ count: Int, at time: UInt64, shift: Float = 0) {
            var frame = NativeTrackpadFrame(receipt: time, revision: runtime.revision, activity: runtime.activity,
                frame: nextID, time: Double(time) / 1_000_000_000, count: count)
            nextID += 1
            if count > 0 { frame.first = .init(id: 0, x: 0.4 + shift, y: 0.5, pressure: 0) }
            if count > 1 { frame.second = .init(id: 1, x: 0.6, y: 0.5, pressure: 0) }
            if count > 2 { frame.third = .init(id: 2, x: 0.5, y: 0.7, pressure: 0) }
            if count > 3 { frame.fourth = .init(id: 3, x: 0.5, y: 0.3, pressure: 0) }
            session.consume(frame, at: time)
        }

        mutating func tap(_ fingers: Int, endingAt end: UInt64, shift: Float = 0) {
            contact(0, at: end - 80_000_000)
            contact(fingers, at: end - 60_000_000, shift: shift)
            contact(fingers, at: end - 40_000_000, shift: shift)
            contact(fingers, at: end - 20_000_000, shift: shift)
            contact(0, at: end)
        }

        mutating func ready(at time: UInt64) -> InputTrigger? { session.takeReady(from: buffer, at: time) }
    }

    @Test(arguments: [1, 2, 3])
    func qualifiedTapUsesTargetedWorkerOnce(_ fingers: Int) throws {
        var h = try Harness()
        h.tap(fingers, endingAt: lift)
        #expect(h.ready(at: lift + 59_999_999) == nil)
        let recognized = h.ready(at: lift + 60_000_000)
        let ready = try #require(recognized)
        #expect(ready == .magicMouseTap(fingers: fingers))
        #expect(h.ready(at: lift + 70_000_000) == nil)
        #expect(h.mailbox.submitMagicMouse(h.runtime, trigger: ready, pid: 100, at: lift + 60_000_000))
        let outputs = Mutex<[KeyboardShortcut]>([])
        let worker = ActionWorker(mailbox: h.mailbox, capabilities: { AudioOutputCapabilities() },
            sendTrackpadShortcut: { shortcut, target, canPerform in
                #expect(target.isMagicMouse && target.pid == 100 && canPerform())
                outputs.withLock { $0.append(shortcut) }
                return .performed
            }, sendShortcut: { _ in Issue.record("Mouse touch used global shortcut sender"); return false },
            secureInput: { false }, postingAllowed: { true })
        worker.service(at: lift + 70_000_000)
        worker.service(at: lift + 80_000_000)
        #expect(outputs.withLock { $0 } == [.init(keyCode: UInt16(12 + fingers), modifiers: .command)])
    }

    @Test(arguments: [1, 2, 3], 0...7)
    func otherInputOrContextCancelsPendingOutput(_ fingers: Int, _ cause: Int) throws {
        var h = try Harness()
        h.tap(fingers, endingAt: lift)
        switch cause {
        case 0: _ = h.mailbox.handle(.init(trigger: .mouseButton(0), phase: .down, isTouchClick: true), secureInput: false)
        case 1: _ = h.mailbox.handle(.init(trigger: .mouseButton(0), phase: .up), secureInput: false)
        case 2: _ = h.mailbox.handle(.init(trigger: .key(0), phase: .down), secureInput: false)
        case 3: h.mailbox.handleUnsupportedScroll(modifiers: [], at: lift + 1, secureInput: false)
        case 4: _ = h.mailbox.handlePointerMotion(.init(deltaX: 1, deltaY: 0), modifiers: [], receivedAt: lift + 1, secureInput: false)
        case 5: h.mailbox.updateTrackpadForeground(101); h.mailbox.updateTrackpadForeground(100)
        case 6: h.buffer.state.withLock { $0.overflow = true }
        default: h.buffer.setAccepting(false)
        }
        h.runtime = try #require(h.mailbox.magicMouseRuntime())
        h.session.update(runtime: h.runtime, foreground: 100)
        #expect(h.ready(at: lift + 60_000_000) == nil)
        #expect(h.ready(at: lift + 500_000_000) == nil)
        h.buffer.setAccepting(true)
        h.tap(fingers, endingAt: lift + 1_000_000_000)
        #expect(h.ready(at: lift + 1_060_000_000) == .magicMouseTap(fingers: fingers))
    }

    @Test func sideBoundariesLeaveTheMiddleToTheOrdinaryTap() {
        #expect(MagicMouseSide.containing(x: 0) == .left && MagicMouseSide.containing(x: 0.4) == .left)
        #expect(MagicMouseSide.containing(x: 0.41) == nil && MagicMouseSide.containing(x: 0.59) == nil)
        #expect(MagicMouseSide.containing(x: 0.6) == .right && MagicMouseSide.containing(x: 1) == .right)
        #expect(MagicMouseSide.containing(x: -0.1) == nil && MagicMouseSide.containing(x: .nan) == nil)
    }

    // The harness places one finger at x = 0.4 + shift.
    @Test(arguments: [
        (Float(-0.2), [MagicMouseSide.left, .right], InputTrigger.magicMouseSideTap(.left)),
        (0.4, [.left, .right], .magicMouseSideTap(.right)),
        (0.1, [.left, .right], .magicMouseTap(fingers: 1)),
        (0.4, [.left], .magicMouseTap(fingers: 1)),
    ])
    func sideRuleWinsOnItsHalfOtherwiseOneFingerTapApplies(_ shift: Float, _ sides: [MagicMouseSide],
                                                          _ expected: InputTrigger) throws {
        var h = try Harness(sides: sides)
        h.tap(1, endingAt: lift, shift: shift)
        let recognized = h.ready(at: lift + 60_000_000)
        let ready = try #require(recognized)
        #expect(ready == expected)
        #expect(h.mailbox.submitMagicMouse(h.runtime, trigger: ready, pid: 100, at: lift + 60_000_000))
        let dispatch = try #require(h.mailbox.nextAction())
        #expect(dispatch.action == h.runtime.actions[expected])
    }

    @Test func sideRulesAloneIgnoreMiddleAndMultiFingerTaps() throws {
        var h = try Harness(fingers: [], sides: [.left, .right])
        h.tap(1, endingAt: lift, shift: 0.1)
        #expect(h.ready(at: lift + 60_000_000) == nil)
        h.tap(2, endingAt: lift + 1_000_000_000, shift: -0.2)
        #expect(h.ready(at: lift + 1_060_000_000) == nil)
        h.tap(1, endingAt: lift + 2_000_000_000, shift: -0.2)
        #expect(h.ready(at: lift + 2_060_000_000) == .magicMouseSideTap(.left))
    }

    @Test(arguments: 0...6)
    func unqualifiedContactsNeverBecomeActions(_ defect: Int) throws {
        var h = try Harness(buttonsDown: defect == 0)
        h.contact(0, at: lift - 80_000_000)
        h.contact(defect == 1 ? 4 : 2, at: lift - 60_000_000)
        if defect == 2 { h.nextID += 1 }
        if defect != 3 {
            h.contact(defect == 1 ? 4 : 2, at: lift - 40_000_000, shift: defect == 4 ? 0.03 : 0)
        }
        h.contact(0, at: defect == 5 ? lift + 200_000_000 : lift)
        if defect == 6 { h.session.interrupt() }
        #expect(h.ready(at: lift + (defect == 5 ? 260_000_000 : 60_000_000)) == nil)
    }

    @Test func idleFrameGapsPreserveFreshTapsButQueuedContactsBlockOldOutput() throws {
        var h = try Harness()
        h.tap(1, endingAt: lift)
        #expect(h.ready(at: lift + 60_000_000) == .magicMouseTap(fingers: 1))
        h.nextID += 500
        h.tap(2, endingAt: lift + 1_000_000_000)
        h.buffer.state.withLock {
            $0.append(.init(receipt: lift + 1_010_000_000, revision: h.runtime.revision,
                           activity: h.runtime.activity, frame: h.nextID, time: 5.01, count: 1), generation: $0.generation)
        }
        #expect(h.ready(at: lift + 1_060_000_000) == nil)
        h.session.consumeBufferedFrames(from: h.buffer, clock: { lift + 1_060_000_000 })
        #expect(h.ready(at: lift + 1_070_000_000) == nil)
    }

    @Test func nativeMouseBufferUsesItsOwnActivityAndNeverFeedsTrackpadClickFilters() throws {
        let mailbox = EngineMailbox()
        mailbox.state.withLock { $0.status = .active; $0.enabled = true; $0.inputActivity = 4; $0.magicMouseActivity = 9 }
        let buffer = NativeTrackpadBuffer(mailbox: mailbox, isMagicMouse: true)
        buffer.setAccepting(true)
        let raw = UnsafeMutableRawPointer.allocate(byteCount: 96, alignment: 8)
        defer { raw.deallocate() }
        raw.initializeMemory(as: UInt8.self, repeating: 0, count: 96)
        raw.storeBytes(of: Int32(1), as: Int32.self)
        raw.storeBytes(of: Double(1), toByteOffset: 8, as: Double.self)
        raw.storeBytes(of: Int32(1), toByteOffset: 16, as: Int32.self)
        raw.storeBytes(of: Int32(4), toByteOffset: 20, as: Int32.self)
        raw.storeBytes(of: Float(0.5), toByteOffset: 32, as: Float.self)
        raw.storeBytes(of: Float(0.5), toByteOffset: 36, as: Float.self)
        buffer.receive(raw, count: 1, callbackFrame: 1, callbackTime: 1)
        let frame = try #require(buffer.pop())
        #expect(frame.activity == 9 && frame.valid)
        #expect(mailbox.state.withLock { $0.trackpadClicks.isTouching(at: frame.receipt) } == false)
        #expect(mailbox.state.withLock { $0.magicTrackpadClicks.isTouching(at: frame.receipt) } == false)
    }

    @Test func exactModifiersAndProfileRevisionAreRecheckedAtDispatch() throws {
        let h = try Harness(modifiers: .shift)
        #expect(h.mailbox.magicMouseRuntime()?.actions.isEmpty == true)
        #expect(h.mailbox.submitMagicMouse(h.runtime, trigger: .magicMouseTap(fingers: 1), pid: 101, at: lift) == false)
        var forged = h.runtime
        forged.actions[.magicMouseTap(fingers: 1)] = .lockScreen
        #expect(h.mailbox.submitMagicMouse(forged, trigger: .magicMouseTap(fingers: 1), pid: 100, at: lift) == false)
        #expect(h.mailbox.submitMagicMouse(h.runtime, trigger: .magicMouseTap(fingers: 1), pid: 100, at: lift))
        let dispatch = try #require(h.mailbox.nextAction())
        h.mailbox.updateTrackpadForeground(nil)
        h.mailbox.updateTrackpadForeground(100)
        #expect(h.mailbox.dispatchIsCurrent(dispatch) == false)
        #expect(h.mailbox.handle(.init(trigger: .magicMouseTap(fingers: 1), phase: .down), secureInput: false) == false)
    }
    @Test(arguments: 0...6)
    func pausedOrInvalidatedContextsRejectAlreadyQualifiedOutput(_ cause: Int) throws {
        let h = try Harness()
        #expect(h.mailbox.submitMagicMouse(h.runtime, trigger: .magicMouseTap(fingers: 1), pid: 100, at: lift))
        switch cause {
        case 0: h.mailbox.setEditing(true)
        case 1: h.mailbox.record(.init(target: .output))
        case 2: h.mailbox.suspend(true)
        case 3: h.mailbox.stop()
        case 4: h.mailbox.captureLost(status: .secureInput)
        case 5: h.mailbox.configure(Configuration(isEnabled: false))
        default: h.mailbox.configure(Configuration(isEnabled: true))
        }
        #expect(h.mailbox.nextAction() == nil)
        #expect(h.mailbox.submitMagicMouse(h.runtime, trigger: .magicMouseTap(fingers: 1), pid: 100, at: lift + 1) == false)
    }

    @Test(arguments: [1, 2, 3]) func sustainedContactsAndCompressedNativeTimeCannotBecomeQuickTaps(_ fingers: Int) throws {
        var held = try Harness()
        held.contact(0, at: lift - 20_000_000)
        for index in 0..<12 { held.contact(fingers, at: lift + UInt64(index) * 20_000_000) }
        held.contact(0, at: lift + 240_000_000)
        #expect(held.ready(at: lift + 300_000_000) == nil)

        var skewed = try Harness()
        for index in 0...5 {
            let receipt = lift + UInt64(index) * 80_000_000
            var frame = NativeTrackpadFrame(receipt: receipt, revision: skewed.runtime.revision,
                activity: skewed.runtime.activity, frame: Int32(index), time: 4 + Double(index) * 0.02,
                count: index == 0 || index == 5 ? 0 : 1)
            if frame.count == 1 { frame.first = .init(id: 0, x: 0.5, y: 0.5, pressure: 0) }
            skewed.session.consume(frame, at: receipt)
        }
        #expect(skewed.ready(at: lift + 460_000_000) == nil)
    }

    @Test func waitingPastTheBoundedSettlingWindowDropsOutput() throws {
        var h = try Harness()
        h.tap(1, endingAt: lift)
        #expect(h.ready(at: lift + 160_000_001) == nil)
        #expect(h.ready(at: lift + 170_000_000) == nil)
        h.tap(2, endingAt: lift + 1_000_000_000)
        #expect(h.ready(at: lift + 1_060_000_000) == .magicMouseTap(fingers: 2))
    }

    @Test func mouseTapRulesEnableRealPointerEventsWithoutAButtonGesture() throws {
        let h = try Harness()
        let needsMotion = h.mailbox.state.withLock { $0.needsPointerMotion }
        #expect(h.mailbox.state.withLock { $0.hasPointerGestureRules } == false)
        #expect(needsMotion)
        let mask = EventTapWorker.eventMask(capturePointerMotion: needsMotion)
        #expect(mask & (CGEventMask(1) << CGEventType.mouseMoved.rawValue) != 0)
        h.mailbox.configure(Configuration(isEnabled: false, bindings: [
            rebind.Binding(scope: .magicMouse, trigger: .magicMouseTap(fingers: 1), modifiers: [], action: .doNothing)
        ]))
        #expect(h.mailbox.state.withLock { $0.needsPointerMotion } == false)
        h.mailbox.configure(Configuration(isEnabled: true))
        #expect(h.mailbox.state.withLock { $0.hasMagicMouseRules || $0.needsPointerMotion } == false)
    }

}
