import CoreGraphics

/// Conversion between Cocoa global coordinates (bottom-left origin, +y up)
/// and Accessibility-API global coordinates (top-left origin, +y down).
/// The flip constant is always the PRIMARY screen's frame.maxY, regardless of
/// which display the rect is on. The transform is an involution: applying it
/// twice returns the original rect.
public enum CoordinateFlip {
    public static func flip(_ rect: CGRect, primaryMaxY: CGFloat) -> CGRect {
        CGRect(
            x: rect.minX,
            y: primaryMaxY - rect.maxY,
            width: rect.width,
            height: rect.height
        )
    }
}
