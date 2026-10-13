import Testing
@testable import rebind

struct WindowCycleStateTests {
    @Test func stableOrderUsesAllWindowsDespiteFrontToBackReordering() throws {
        var state = WindowCycleState<Int>()
        let initial = try #require(state.order(application: 1, revision: 4, observed: [10, 20, 30]))
        state.commit(application: 1, revision: 4, order: initial)
        let reordered = try #require(state.order(application: 1, revision: 4, observed: [20, 10, 30]))
        #expect(reordered == [10, 20, 30])
        #expect(WindowCycleState.target(.next, focused: 20, order: reordered) == 30)
        #expect(WindowCycleState.target(.next, focused: 30, order: reordered) == 10)
        #expect(WindowCycleState.target(.previous, focused: 10, order: reordered) == 30)
    }

    @Test(arguments: 0...3) func membershipAppAndGenerationChangesStartFreshOrder(_ change: Int) throws {
        var state = WindowCycleState<Int>()
        state.commit(application: 1, revision: 4, order: [10, 20, 30])
        let observed = change == 0 ? [30, 10] : (change == 1 ? [30, 10, 20, 40] : [30, 10, 20])
        #expect(try #require(state.order(application: change == 2 ? 2 : 1,
            revision: change == 3 ? 5 : 4, observed: observed)) == observed)
    }

    @Test func malformedAndExcessiveListsAreRejectedAndOneWindowIsNoOp() {
        let state = WindowCycleState<Int>()
        #expect(state.order(application: 1, revision: 0, observed: []) == nil)
        #expect(state.order(application: 1, revision: 0, observed: [10, 10]) == nil)
        #expect(state.order(application: 1, revision: 0, observed: Array(0...32)) == nil)
        #expect(state.order(application: 1, revision: 0, observed: Array(0..<32))?.count == 32)
        #expect(WindowCycleState.target(.next, focused: 10, order: [10]) == 10)
        #expect(WindowCycleState.target(.previous, focused: 10, order: [10]) == 10)
        #expect(WindowCycleState.target(.next, focused: 99, order: [10, 20]) == nil)
        #expect(WindowCycleState<Int>.target(.next, focused: 10, order: []) == nil)
    }

    @Test func invalidationReleasesCachedElementsOnlyForChangedGeneration() {
        var state = WindowCycleState<Int>()
        state.commit(application: 1, revision: 4, order: [10, 20])
        state.invalidate(ifRevisionDiffersFrom: 4)
        #expect(state.windows == [10, 20])
        state.invalidate(ifRevisionDiffersFrom: 5)
        #expect(state.windows.isEmpty && state.application == nil && state.revision == nil)
    }
}
