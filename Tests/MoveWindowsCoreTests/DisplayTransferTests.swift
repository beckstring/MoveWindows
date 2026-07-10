import CoreGraphics
import Testing
@testable import MoveWindowsCore

@Suite struct DisplayTransferTests {
    let src = CGRect(x: 0, y: 0, width: 1512, height: 949)
    let dst = CGRect(x: 1512, y: -100, width: 2560, height: 1415)

    @Test func preservesFractions() {
        // A window occupying the exact center half of the source stays centered.
        let window = CGRect(x: src.width / 4, y: src.height / 4,
                            width: src.width / 2, height: src.height / 2)
        let moved = DisplayTransfer.transferredFrame(window: window, from: src, to: dst)
        #expect(abs(moved.midX - dst.midX) < 0.001)
        #expect(abs(moved.midY - dst.midY) < 0.001)
        #expect(abs(moved.width - dst.width / 2) < 0.001)
        #expect(abs(moved.height - dst.height / 2) < 0.001)
    }

    @Test func roundTripsWithinEpsilon() {
        let window = CGRect(x: 137, y: 251, width: 803, height: 411)
        let there = DisplayTransfer.transferredFrame(window: window, from: src, to: dst)
        let back = DisplayTransfer.transferredFrame(window: there, from: dst, to: src)
        #expect(abs(back.minX - window.minX) < 0.001)
        #expect(abs(back.minY - window.minY) < 0.001)
        #expect(abs(back.width - window.width) < 0.001)
        #expect(abs(back.height - window.height) < 0.001)
    }

    @Test func handlesNegativeOriginDestination() {
        let negDst = CGRect(x: -1920, y: -200, width: 1920, height: 1055)
        let window = CGRect(x: 0, y: 0, width: 756, height: 949) // left half of src
        let moved = DisplayTransfer.transferredFrame(window: window, from: src, to: negDst)
        #expect(abs(moved.minX - negDst.minX) < 0.001)
        #expect(abs(moved.minY - negDst.minY) < 0.001)
        #expect(abs(moved.width - negDst.width / 2) < 0.001)
    }

    @Test func degenerateSourceFallsBackToDestination() {
        let window = CGRect(x: 5, y: 5, width: 10, height: 10)
        let zeroSrc = CGRect(x: 0, y: 0, width: 0, height: 0)
        #expect(DisplayTransfer.transferredFrame(window: window, from: zeroSrc, to: dst) == dst)
    }

    @Test func clampShrinksAndShifts() {
        let bounds = CGRect(x: 0, y: 0, width: 1000, height: 800)
        let oversized = CGRect(x: -50, y: 700, width: 1200, height: 300)
        let clamped = DisplayTransfer.clamped(oversized, into: bounds)
        #expect(bounds.contains(clamped))
        #expect(clamped.width == bounds.width)
        #expect(clamped.height == 300)
    }
}
