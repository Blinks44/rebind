import AppKit
import Dispatch

// Coordinates are AX desktop points: origin at the primary display's top left.
nonisolated struct WindowDisplay: Equatable, Sendable {
    var frame: CGRect
    var visibleFrame: CGRect

    static func fromCocoa(frame: CGRect, visibleFrame: CGRect, primaryTop: CGFloat) -> Self {
        func flipped(_ rect: CGRect) -> CGRect {
            CGRect(x: rect.minX, y: primaryTop - rect.maxY, width: rect.width, height: rect.height)
        }
        return Self(frame: flipped(frame), visibleFrame: flipped(visibleFrame))
    }
}

nonisolated struct WindowDisplaySnapshot: Equatable, Sendable {
    var displays: [WindowDisplay] = []
    var capturedAt: UInt64 = 0

    func isFresh(at now: UInt64) -> Bool {
        !displays.isEmpty && now >= capturedAt && now - capturedAt <= 2_000_000_000
    }

    @MainActor static func current() -> Self {
        let screens = NSScreen.screens
        guard let primary = screens.first else { return Self() }
        return Self(displays: screens.map {
            WindowDisplay.fromCocoa(frame: $0.frame, visibleFrame: $0.visibleFrame, primaryTop: primary.frame.maxY)
        }, capturedAt: DispatchTime.now().uptimeNanoseconds)
    }
}

nonisolated enum WindowLayoutGeometry {
    static func valid(_ rect: CGRect) -> Bool {
        [rect.origin.x, rect.origin.y, rect.width, rect.height, rect.maxX, rect.maxY].allSatisfy(\.isFinite)
            && rect.width > 0 && rect.height > 0
    }

    static func approximatelyEqual(_ lhs: CGRect, _ rhs: CGRect) -> Bool {
        valid(lhs) && valid(rhs) && abs(lhs.minX - rhs.minX) <= 1 && abs(lhs.minY - rhs.minY) <= 1
            && abs(lhs.width - rhs.width) <= 1 && abs(lhs.height - rhs.height) <= 1
    }

    static func target(_ action: WindowLayoutAction, window: CGRect, displays: [WindowDisplay]) -> CGRect? {
        guard valid(window) else { return nil }
        var selected: Int?
        var largestArea: CGFloat = 0
        for (index, display) in displays.enumerated() {
            guard valid(display.frame), valid(display.visibleFrame), display.frame.contains(display.visibleFrame) else { return nil }
            let intersection = display.frame.intersection(window)
            let area = intersection.isNull ? 0 : intersection.width * intersection.height
            if area > largestArea { largestArea = area; selected = index }
        }
        guard let selected else { return nil }
        let display = displays[selected]
        // Conservatively exclude windows covering a whole display. Public AX
        // has no standard full-screen attribute; this can also exclude an
        // ordinary oversized window, rather than mutating a full-screen Space.
        if window.insetBy(dx: -1, dy: -1).contains(display.frame) { return nil }
        let usable = display.visibleFrame
        switch action {
        case .fill: return usable
        case .fillWithStageManager:
            // Keep the stored case name compatible with existing bindings. This layout is now
            // unconditional: Stage Manager may hide its strip or be switched off entirely.
            let inset = max(0, display.frame.minX + 220 - usable.minX)
            guard inset < usable.width / 2 else { return nil }
            return CGRect(x: usable.minX + inset, y: usable.minY, width: usable.width - inset, height: usable.height)
        case .leftHalf:
            return CGRect(x: usable.minX, y: usable.minY, width: floor(usable.width / 2), height: usable.height)
        case .rightHalf:
            let leftWidth = floor(usable.width / 2)
            return CGRect(x: usable.minX + leftWidth, y: usable.minY, width: usable.width - leftWidth, height: usable.height)
        case .center:
            guard window.width <= usable.width, window.height <= usable.height else { return nil }
            return CGRect(x: usable.midX - window.width / 2, y: usable.midY - window.height / 2,
                          width: window.width, height: window.height)
        case .topHalf, .bottomHalf, .topLeft, .topRight, .bottomLeft, .bottomRight:
            let leftWidth = floor(usable.width / 2)
            let topHeight = floor(usable.height / 2)
            let isTop = [.topHalf, .topLeft, .topRight].contains(action)
            let isFullWidth = action == .topHalf || action == .bottomHalf
            let isLeft = action == .topLeft || action == .bottomLeft
            return CGRect(x: isFullWidth || isLeft ? usable.minX : usable.minX + leftWidth,
                          y: isTop ? usable.minY : usable.minY + topHeight,
                          width: isFullWidth ? usable.width : (isLeft ? leftWidth : usable.width - leftWidth),
                          height: isTop ? topHeight : usable.height - topHeight)
        case .nextDisplay:
            guard displays.count > 1 else { return nil }
            let next = displays[(selected + 1) % displays.count].visibleFrame
            let size = CGSize(width: min(window.width, next.width), height: min(window.height, next.height))
            // Keep the window's relative place: a window on the left edge stays on the left edge.
            func place(_ origin: CGFloat, _ length: CGFloat, from: (CGFloat, CGFloat), to: (CGFloat, CGFloat), _ newLength: CGFloat) -> CGFloat {
                let room = from.1 - length
                let fraction = room > 0 ? min(max((origin - from.0) / room, 0), 1) : 0
                return to.0 + fraction * (to.1 - newLength)
            }
            return CGRect(x: place(window.minX, window.width, from: (usable.minX, usable.width), to: (next.minX, next.width), size.width),
                          y: place(window.minY, window.height, from: (usable.minY, usable.height), to: (next.minY, next.height), size.height),
                          width: size.width, height: size.height)
        }
    }
}
