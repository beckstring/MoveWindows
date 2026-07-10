import CoreGraphics
import Testing
@testable import MoveWindowsCore

@Suite struct CoordinateFlipTests {
    let primaryMaxY: CGFloat = 982 // primary screen height

    @Test func flipIsAnInvolution() {
        let rects = [
            CGRect(x: 100, y: 200, width: 640, height: 480),
            CGRect(x: -1920, y: -200, width: 800, height: 600), // secondary display below-left
            CGRect(x: 1512, y: 500, width: 400, height: 300),   // secondary display to the right
        ]
        for rect in rects {
            let twice = CoordinateFlip.flip(CoordinateFlip.flip(rect, primaryMaxY: primaryMaxY), primaryMaxY: primaryMaxY)
            #expect(twice == rect)
        }
    }

    @Test func cocoaTopOfPrimaryMapsToAXZero() {
        // A window whose top edge touches the top of the primary screen (Cocoa maxY
        // == primaryMaxY) has AX origin y == 0.
        let rect = CGRect(x: 50, y: primaryMaxY - 500, width: 700, height: 500)
        let ax = CoordinateFlip.flip(rect, primaryMaxY: primaryMaxY)
        #expect(ax.origin.y == 0)
        #expect(ax.origin.x == 50)
        #expect(ax.size == rect.size)
    }

    @Test func negativeCocoaCoordinatesMapCorrectly() {
        // Secondary display arranged below the primary: Cocoa y is negative,
        // AX y is greater than the primary height.
        let rect = CGRect(x: 0, y: -300, width: 400, height: 200)
        let ax = CoordinateFlip.flip(rect, primaryMaxY: primaryMaxY)
        #expect(ax.origin.y == primaryMaxY + 100) // 982 - (-300 + 200)
    }
}
