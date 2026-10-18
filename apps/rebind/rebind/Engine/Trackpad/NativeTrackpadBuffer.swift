import Dispatch
import Synchronization

// Mechanical ABI offsets compared with Subsurface (Apache-2.0), pinned revision
// 88eb16b0a6f7a44a898cecff9e283298aa413936; see ThirdPartyNotices.txt. No Swift
// struct-layout assumptions, escaped native pointers or allocations per contact.
nonisolated struct NativeTrackpadFrame: Sendable {
    var receipt: UInt64
    var revision: UInt64
    var activity: UInt64
    var frame: Int32?
    var time: Double?
    var count = 0
    var valid = true
    var first: ShortContactRecognizer.Contact?
    var second: ShortContactRecognizer.Contact?
    var third: ShortContactRecognizer.Contact?
    var fourth: ShortContactRecognizer.Contact?

    var contacts: [ShortContactRecognizer.Contact] { [first, second, third, fourth].compactMap { $0 } }

    // Native memory validity/ABI remains a private-framework hardware assumption.
    // Validate the count before reading anything, including a nil/zero data pointer.
    static func read(_ data: UnsafeRawPointer?, count: Int32, receipt: UInt64,
                     revision: UInt64, activity: UInt64,
                     callbackFrame: Int32? = nil, callbackTime: Double? = nil) -> Self {
        var result = Self(receipt: receipt, revision: revision, activity: activity)
        guard (0...16).contains(count), count == 0 || data != nil else { result.valid = false; return result }
        // The callback has timing even when its contact array is empty. Use one
        // native clock/frame sequence for both contact and zero-contact frames;
        // local receipt time still independently bounds consumer staleness.
        if callbackFrame != nil || callbackTime != nil {
            guard let callbackFrame, let callbackTime, callbackTime.isFinite,
                  callbackTime >= 0 else { result.valid = false; return result }
            result.frame = callbackFrame
            result.time = callbackTime
        }
        guard count > 0, let data else { return result }
        let frame = data.loadUnaligned(as: Int32.self)
        let time = data.loadUnaligned(fromByteOffset: 8, as: Double.self)
        if callbackFrame == nil { result.frame = frame; result.time = time }
        guard time.isFinite, time >= 0 else { result.valid = false; return result }
        for index in 0..<Int(count) {
            let pointer = data.advanced(by: index * 96)
            let state = pointer.loadUnaligned(fromByteOffset: 20, as: Int32.self)
            let id = pointer.loadUnaligned(fromByteOffset: 16, as: Int32.self)
            let x = pointer.loadUnaligned(fromByteOffset: 32, as: Float.self)
            let y = pointer.loadUnaligned(fromByteOffset: 36, as: Float.self)
            let pressure = pointer.loadUnaligned(fromByteOffset: 52, as: Float.self)
            guard pointer.loadUnaligned(as: Int32.self) == frame,
                  pointer.loadUnaligned(fromByteOffset: 8, as: Double.self) == time,
                  (0...7).contains(state), x.isFinite, y.isFinite, (0...1).contains(x), (0...1).contains(y),
                  pressure.isFinite, pressure >= 0 else { result.valid = false; return result }
            // Same making/touching filter as the verified standalone probe.
            guard state == 3 || state == 4 else { continue }
            guard result.count < 4,
                  result.first?.id != id, result.second?.id != id,
                  result.third?.id != id, result.fourth?.id != id else { result.valid = false; return result }
            let contact = ShortContactRecognizer.Contact(id: id, x: x, y: y, pressure: pressure)
            switch result.count {
            case 0: result.first = contact
            case 1: result.second = contact
            case 2: result.third = contact
            default: result.fourth = contact
            }
            result.count += 1
        }
        return result
    }
}

nonisolated final class NativeTrackpadBuffer: Sendable {
    struct State: Sendable {
        var accepting = false
        // Admission is separate from publication; reset/loss invalidates copies
        // still in flight without holding a lock while reading native memory.
        var generation: UInt64 = 0
        var frames = [NativeTrackpadFrame?](repeating: nil, count: 64)
        var head = 0
        var count = 0
        var overflow = false
        /// When the last frame arrived; the consumer slows down once the surface has been quiet.
        var lastReceipt: UInt64 = 0
        /// The consumer polls slowly; the next frame calls `wake` once.
        var sleeping = false
        var wake: (@Sendable () -> Void)?
        mutating func clear() {
            generation &+= 1
            for index in frames.indices { frames[index] = nil }
            head = 0; count = 0; overflow = false
        }

        /// Publishes a copied frame only into the queue generation that admitted its callback.
        mutating func append(_ frame: NativeTrackpadFrame, generation: UInt64) {
            guard accepting, self.generation == generation else { return }
            // Quarantine this discontinuous stream until the consumer has
            // acknowledged the loss and cancelled its recognition state.
            guard !overflow else { return }
            guard count < frames.count else { clear(); overflow = true; return }
            frames[(head + count) % frames.count] = frame
            count += 1
        }
    }
    let state = Mutex(State())
    let mailbox: EngineMailbox
    /// Frames of an external Magic Trackpad feed its own click filter.
    let isMagicTrackpad: Bool
    /// Whether contact pressure carries finger force (Force Touch surfaces).
    let reportsForce: Bool
    init(mailbox: EngineMailbox, isMagicTrackpad: Bool = false, reportsForce: Bool = false) {
        self.mailbox = mailbox
        self.isMagicTrackpad = isMagicTrackpad
        self.reportsForce = reportsForce
    }

    func receive(_ data: UnsafeRawPointer?, count: Int32,
                 callbackFrame: Int32? = nil, callbackTime: Double? = nil) {
        let receipt = DispatchTime.now().uptimeNanoseconds
        guard let (generation, wake) = state.withLock({ state -> (UInt64, (@Sendable () -> Void)?)? in
            guard state.accepting else { return nil }
            state.lastReceipt = receipt
            defer { state.sleeping = false }
            return (state.generation, state.sleeping ? state.wake : nil)
        }) else { return }
        // Only the first frame after a quiet period; it schedules a poll, nothing more.
        wake?()
        let snapshot = mailbox.state.withLock { state -> (UInt64, UInt64)? in
            guard state.canDispatch else { return nil }
            return (state.actionRevision, state.inputActivity)
        }
        guard let snapshot else { return }
        let frame = NativeTrackpadFrame.read(data, count: count, receipt: receipt,
                                            revision: snapshot.0, activity: snapshot.1,
                                            callbackFrame: callbackFrame, callbackTime: callbackTime)
        let magic = isMagicTrackpad, force = reportsForce
        mailbox.state.withLock {
            magic ? $0.magicTrackpadClicks.observe(frame, reportsForce: force)
                : $0.trackpadClicks.observe(frame, reportsForce: force)
        }
        state.withLock { $0.append(frame, generation: generation) }
    }

    func setAccepting(_ accepting: Bool) { state.withLock { $0.clear(); $0.accepting = accepting } }
    func setWake(_ wake: @escaping @Sendable () -> Void) { state.withLock { $0.wake = wake } }

    /// Marks the buffer sleeping when nothing is waiting and no frame arrived since `cutoff`;
    /// the next frame then calls the wake handler.
    func sleepIfQuiet(since cutoff: UInt64) -> Bool {
        state.withLock {
            guard $0.accepting, $0.count == 0, !$0.overflow, $0.lastReceipt < cutoff else { return false }
            $0.sleeping = true
            return true
        }
    }
    func takeOverflow() -> Bool { state.withLock { let result = $0.overflow; $0.overflow = false; return result } }
    func pop() -> NativeTrackpadFrame? {
        state.withLock {
            guard $0.count > 0 else { return nil }
            let result = $0.frames[$0.head]
            $0.frames[$0.head] = nil
            $0.head = ($0.head + 1) % $0.frames.count
            $0.count -= 1
            return result
        }
    }
}
