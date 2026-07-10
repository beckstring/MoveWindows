import CoreGraphics

/// Pure frame math. All rects are in Cocoa coordinates (bottom-left origin, +y up),
/// relative to the global desktop space. `visible` is a screen's visibleFrame.
public enum LayoutEngine {
    public static func frame(for layout: SnapLayout, in visible: CGRect) -> CGRect {
        let halfW = visible.width / 2
        let halfH = visible.height / 2
        switch layout {
        case .maximized:
            return visible
        case .leftHalf:
            return CGRect(x: visible.minX, y: visible.minY, width: halfW, height: visible.height)
        case .rightHalf:
            return CGRect(x: visible.midX, y: visible.minY, width: halfW, height: visible.height)
        case .topLeftQuarter:
            return CGRect(x: visible.minX, y: visible.midY, width: halfW, height: halfH)
        case .topRightQuarter:
            return CGRect(x: visible.midX, y: visible.midY, width: halfW, height: halfH)
        case .bottomLeftQuarter:
            return CGRect(x: visible.minX, y: visible.minY, width: halfW, height: halfH)
        case .bottomRightQuarter:
            return CGRect(x: visible.midX, y: visible.minY, width: halfW, height: halfH)
        }
    }
}
