import AppKit
import MoveWindowsCore

/// NSScreen helpers and the AX↔Cocoa coordinate flip.
/// Screens are re-read on every call — displays get plugged and unplugged.
@MainActor
enum ScreenCoordinates {
    /// The flip constant is ALWAYS the primary screen (screens[0], the one
    /// containing the global origin) — never NSScreen.main (keyboard focus)
    /// and never the current screen's height.
    static var primaryMaxY: CGFloat {
        NSScreen.screens.first?.frame.maxY ?? 0
    }

    /// Converts a rect between Cocoa (bottom-left origin) and AX (top-left
    /// origin) global coordinates. Involution: the same call converts back.
    static func flip(_ rect: CGRect) -> CGRect {
        CoordinateFlip.flip(rect, primaryMaxY: primaryMaxY)
    }

    /// The screen a window is on: largest intersection area with the window's
    /// (Cocoa-coords) frame. Center-point containment fails for windows
    /// straddling displays or dragged half off-screen; fall back to the
    /// screen nearest to the window's center.
    static func screen(containing cocoaRect: CGRect) -> NSScreen? {
        let screens = NSScreen.screens
        guard !screens.isEmpty else { return nil }

        let best = screens.max { a, b in
            intersectionArea(cocoaRect, a.frame) < intersectionArea(cocoaRect, b.frame)
        }
        if let best, intersectionArea(cocoaRect, best.frame) > 0 {
            return best
        }
        let center = CGPoint(x: cocoaRect.midX, y: cocoaRect.midY)
        return screens.min { a, b in
            distanceSquared(center, to: a.frame) < distanceSquared(center, to: b.frame)
        }
    }

    /// Screens in stable left-to-right order for next/prev cycling.
    static func orderedScreens() -> [NSScreen] {
        NSScreen.screens.sorted {
            ($0.frame.origin.x, $0.frame.origin.y) < ($1.frame.origin.x, $1.frame.origin.y)
        }
    }

    /// The next/previous screen in left-to-right order, wrapping at the ends.
    /// Returns nil when there is only one screen.
    static func nextScreen(after screen: NSScreen, forward: Bool) -> NSScreen? {
        let ordered = orderedScreens()
        guard ordered.count > 1,
              let index = ordered.firstIndex(where: { $0 === screen })
        else { return nil }
        let offset = forward ? 1 : ordered.count - 1
        return ordered[(index + offset) % ordered.count]
    }

    private static func intersectionArea(_ a: CGRect, _ b: CGRect) -> CGFloat {
        let intersection = a.intersection(b)
        guard !intersection.isNull else { return 0 }
        return intersection.width * intersection.height
    }

    private static func distanceSquared(_ point: CGPoint, to rect: CGRect) -> CGFloat {
        let dx = max(rect.minX - point.x, 0, point.x - rect.maxX)
        let dy = max(rect.minY - point.y, 0, point.y - rect.maxY)
        return dx * dx + dy * dy
    }
}
