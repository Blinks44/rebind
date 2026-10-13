import Testing
@testable import rebind

struct TrackpadCornerTests {
    @Test(arguments: [
        (Float(0.1), Float(0.9), TrackpadCorner.topLeft),
        (0.9, 0.9, .topRight), (0.1, 0.1, .bottomLeft), (0.9, 0.1, .bottomRight),
        (0, 1, .topLeft), (1, 0, .bottomRight),
        (0.22, 1 - 0.22, .topLeft), (1 - 0.22, 0.22, .bottomRight),
    ])
    func nativeYAxisAndAllFourRegions(_ sample: (Float, Float, TrackpadCorner)) {
        #expect(TrackpadCorner.containing(x: sample.0, y: sample.1) == sample.2)
    }

    @Test(arguments: [
        (Float(0.5), Float(0.5)), (0.5, 1), (0, 0.5), (0.221, 0.8),
        (-0.1, 0.9), (0.1, 1.1), (.nan, 1), (0, .infinity),
    ])
    func edgesCenterAndMalformedCoordinatesAreNotCorners(_ sample: (Float, Float)) {
        #expect(TrackpadCorner.containing(x: sample.0, y: sample.1) == nil)
    }
}
