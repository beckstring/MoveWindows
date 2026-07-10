import CoreGraphics
import Testing
@testable import MoveWindowsCore

@Suite struct LayoutEngineTests {
    // MacBook-with-notch shape and a secondary display with negative origin.
    static let screens: [CGRect] = [
        CGRect(x: 0, y: 0, width: 1512, height: 949),
        CGRect(x: -1920, y: -200, width: 1920, height: 1055),
    ]

    @Test(arguments: screens)
    func halvesTileTheVisibleFrame(visible: CGRect) {
        let left = LayoutEngine.frame(for: .leftHalf, in: visible)
        let right = LayoutEngine.frame(for: .rightHalf, in: visible)
        #expect(left.union(right) == visible)
        #expect(left.intersection(right).width == 0)
    }

    @Test(arguments: screens)
    func quartersTileTheVisibleFrame(visible: CGRect) {
        let quarters: [SnapLayout] = [.topLeftQuarter, .topRightQuarter, .bottomLeftQuarter, .bottomRightQuarter]
        let rects = quarters.map { LayoutEngine.frame(for: $0, in: visible) }
        let union = rects.dropFirst().reduce(rects[0]) { $0.union($1) }
        #expect(union == visible)
        #expect(rects.allSatisfy { $0.width == visible.width / 2 && $0.height == visible.height / 2 })
    }

    @Test func maximizedEqualsVisibleFrame() {
        let visible = Self.screens[0]
        #expect(LayoutEngine.frame(for: .maximized, in: visible) == visible)
    }

    @Test func topQuartersSitAboveBottomQuarters() {
        // "Top" in Cocoa coordinates means higher y.
        let visible = Self.screens[1]
        let topLeft = LayoutEngine.frame(for: .topLeftQuarter, in: visible)
        let bottomLeft = LayoutEngine.frame(for: .bottomLeftQuarter, in: visible)
        #expect(topLeft.minY == visible.midY)
        #expect(bottomLeft.minY == visible.minY)
        #expect(topLeft.maxY == visible.maxY)
    }
}
