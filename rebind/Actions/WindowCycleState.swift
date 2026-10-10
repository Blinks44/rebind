// Owned only by the serial action worker. No titles, window IDs, global observers
// or persistent history. Preserve a bounded app-reported order across AX reordering.
nonisolated struct WindowCycleState<Element: Equatable> {
    static var maximumWindows: Int { 32 }
    private(set) var application: Element?
    private(set) var revision: UInt64?
    private(set) var windows: [Element] = []

    func order(application: Element, revision: UInt64, observed: [Element]) -> [Element]? {
        guard !observed.isEmpty, observed.count <= Self.maximumWindows,
              observed.indices.allSatisfy({ !observed[..<$0].contains(observed[$0]) }) else { return nil }
        guard self.application == application, self.revision == revision,
              windows.count == observed.count, windows.allSatisfy(observed.contains) else { return observed }
        // Use freshly enumerated handles, retaining only the previous ordering.
        return windows.compactMap { cached in observed.first { $0 == cached } }
    }

    static func target(_ action: WindowCycleAction, focused: Element, order: [Element]) -> Element? {
        guard let index = order.firstIndex(of: focused) else { return nil }
        let offset = action == .next ? 1 : order.count - 1
        return order[(index + offset) % order.count]
    }

    mutating func commit(application: Element, revision: UInt64, order: [Element]) {
        self.application = application
        self.revision = revision
        windows = order
    }

    mutating func invalidate(ifRevisionDiffersFrom current: UInt64) {
        if revision != current { self = Self() }
    }
}
