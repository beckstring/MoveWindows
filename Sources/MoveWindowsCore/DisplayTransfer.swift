import CoreGraphics

/// Math for throwing a window from one display to another.
public enum DisplayTransfer {
    /// Maps `window` from its position/size relative to `src` onto `dst`,
    /// preserving the fractional position and size within the visible frame.
    public static func transferredFrame(window: CGRect, from src: CGRect, to dst: CGRect) -> CGRect {
        guard src.width > 0, src.height > 0 else { return dst }
        let fx = (window.minX - src.minX) / src.width
        let fy = (window.minY - src.minY) / src.height
        let fw = window.width / src.width
        let fh = window.height / src.height
        return CGRect(
            x: dst.minX + fx * dst.width,
            y: dst.minY + fy * dst.height,
            width: fw * dst.width,
            height: fh * dst.height
        )
    }

    /// Shrinks (if needed) and shifts `frame` so it lies within `bounds`.
    public static func clamped(_ frame: CGRect, into bounds: CGRect) -> CGRect {
        var result = frame
        result.size.width = min(result.width, bounds.width)
        result.size.height = min(result.height, bounds.height)
        result.origin.x = min(max(result.minX, bounds.minX), bounds.maxX - result.width)
        result.origin.y = min(max(result.minY, bounds.minY), bounds.maxY - result.height)
        return result
    }
}
