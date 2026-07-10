import CoreGraphics

/// Detects which SnapLayout (if any) a live window frame currently occupies,
/// so the transition state machine needs no persistent per-window state.
public enum StateDetector {
    /// Order matters: maximized shadows halves, halves shadow quarters.
    private static let ordered: [SnapLayout] = [
        .maximized,
        .leftHalf, .rightHalf,
        .topLeftQuarter, .topRightQuarter, .bottomLeftQuarter, .bottomRightQuarter,
    ]

    public static func detectLayout(
        of windowFrame: CGRect,
        in visible: CGRect,
        tolerance: CGFloat = 10
    ) -> SnapLayout? {
        // Exact pass: all four edges within tolerance. Covers apps that quantize
        // size slightly (Terminal's cell grid, 1 px rounding).
        for layout in ordered {
            let ideal = LayoutEngine.frame(for: layout, in: visible)
            if edgesMatch(windowFrame, ideal, tolerance: tolerance) {
                return layout
            }
        }
        // Fallback for windows whose minimum size exceeds the layout's size:
        // the app honors position but clamps size, so edges won't all match.
        // Accept when the top-left corner sits right and the overlap is dominant.
        for layout in ordered {
            let ideal = LayoutEngine.frame(for: layout, in: visible)
            if topLeftMatches(windowFrame, ideal, tolerance: tolerance),
               intersectionOverUnion(windowFrame, ideal) >= 0.7 {
                return layout
            }
        }
        return nil
    }

    private static func edgesMatch(_ a: CGRect, _ b: CGRect, tolerance: CGFloat) -> Bool {
        abs(a.minX - b.minX) <= tolerance
            && abs(a.minY - b.minY) <= tolerance
            && abs(a.maxX - b.maxX) <= tolerance
            && abs(a.maxY - b.maxY) <= tolerance
    }

    private static func topLeftMatches(_ a: CGRect, _ b: CGRect, tolerance: CGFloat) -> Bool {
        // Top-left in Cocoa coordinates is (minX, maxY).
        abs(a.minX - b.minX) <= tolerance && abs(a.maxY - b.maxY) <= tolerance
    }

    private static func intersectionOverUnion(_ a: CGRect, _ b: CGRect) -> CGFloat {
        let intersection = a.intersection(b)
        guard !intersection.isNull, !intersection.isEmpty else { return 0 }
        let intersectionArea = intersection.width * intersection.height
        let unionArea = a.width * a.height + b.width * b.height - intersectionArea
        guard unionArea > 0 else { return 0 }
        return intersectionArea / unionArea
    }
}
