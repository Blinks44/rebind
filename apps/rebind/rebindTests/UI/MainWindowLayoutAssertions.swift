import AppKit
import XCTest
@testable import rebind

/// Verifies the native sidebar sizing anchor and actual scrolling content inside the window.
@MainActor enum MainWindowLayoutAssertions {
    static func verifyRegions(in view: NSView, context: String,
                              file: StaticString = #filePath, line: UInt = #line) throws {
        let views = descendants(of: view)
        let sidebar = try XCTUnwrap(views.first { $0 is MainWindowSizingView }, context, file: file, line: line)
        let viewport = view.bounds
        let sidebarBounds = sidebar.convert(sidebar.bounds, to: view)
        XCTAssertEqual(sidebarBounds.minX, viewport.minX, accuracy: 1, context, file: file, line: line)
        XCTAssertEqual(sidebarBounds.width, 240, accuracy: 1, context, file: file, line: line)
        XCTAssertEqual(sidebarBounds.height, viewport.height, accuracy: 1, context, file: file, line: line)
        XCTAssertEqual(sidebarBounds.minY, viewport.minY, accuracy: 1, context, file: file, line: line)
        let content = views.filter { $0 is NSScrollView }
        XCTAssertFalse(content.isEmpty, context, file: file, line: line)
        for child in content {
            let bounds = child.convert(child.bounds, to: view)
            XCTAssertGreaterThan(bounds.height, 0, context, file: file, line: line)
            XCTAssertGreaterThanOrEqual(bounds.minX, sidebarBounds.maxX - 1, context, file: file, line: line)
            XCTAssertGreaterThanOrEqual(bounds.minY, viewport.minY - 1, context, file: file, line: line)
            XCTAssertLessThanOrEqual(bounds.maxX, viewport.maxX + 1, context, file: file, line: line)
            XCTAssertLessThanOrEqual(bounds.maxY, viewport.maxY + 1, context, file: file, line: line)
        }
    }

    private static func descendants(of view: NSView) -> [NSView] {
        view.subviews.flatMap { [$0] + descendants(of: $0) }
    }
}
