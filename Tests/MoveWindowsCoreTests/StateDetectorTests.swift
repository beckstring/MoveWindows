import CoreGraphics
import Testing
@testable import MoveWindowsCore

@Suite struct StateDetectorTests {
    let visible = CGRect(x: 0, y: 0, width: 1600, height: 1000)

    @Test(arguments: SnapLayout.allCases)
    func detectsExactLayouts(layout: SnapLayout) {
        let frame = LayoutEngine.frame(for: layout, in: visible)
        #expect(StateDetector.detectLayout(of: frame, in: visible) == layout)
    }

    @Test func matchesWithinTolerance() {
        // Terminal-style: height falls short of the ideal by a few points.
        var frame = LayoutEngine.frame(for: .leftHalf, in: visible)
        frame.size.height -= 9
        frame.size.width -= 6
        #expect(StateDetector.detectLayout(of: frame, in: visible) == .leftHalf)
    }

    @Test func rejectsBeyondTolerance() {
        var frame = LayoutEngine.frame(for: .leftHalf, in: visible)
        frame.size.width -= 40
        frame.size.height -= 40
        frame.origin.x += 40
        #expect(StateDetector.detectLayout(of: frame, in: visible) == nil)
    }

    @Test func clampedMinSizeWindowMatchesViaCornerFallback() {
        // App min size exceeds a quarter: position honored, size clamped larger.
        let ideal = LayoutEngine.frame(for: .topLeftQuarter, in: visible)
        let clamped = CGRect(x: ideal.minX, y: ideal.maxY - ideal.height * 1.2,
                             width: ideal.width * 1.15, height: ideal.height * 1.2)
        #expect(StateDetector.detectLayout(of: clamped, in: visible) == .topLeftQuarter)
    }

    @Test func floatingWindowReturnsNil() {
        let frame = CGRect(x: 300, y: 250, width: 700, height: 500)
        #expect(StateDetector.detectLayout(of: frame, in: visible) == nil)
    }

    @Test func maximizedTakesPrecedence() {
        // A frame matching the whole visibleFrame must be maximized, not a half.
        let frame = visible.insetBy(dx: 3, dy: 3)
        #expect(StateDetector.detectLayout(of: frame, in: visible) == .maximized)
    }

    @Test func worksOnNegativeOriginScreens() {
        let negVisible = CGRect(x: -1920, y: -200, width: 1920, height: 1055)
        let frame = LayoutEngine.frame(for: .bottomRightQuarter, in: negVisible)
        #expect(StateDetector.detectLayout(of: frame, in: negVisible) == .bottomRightQuarter)
    }
}
