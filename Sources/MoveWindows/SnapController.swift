import AppKit
import MoveWindowsCore

/// Glue between a hotkey press and a window move:
/// read focused AX window → flip to Cocoa coords → detect layout →
/// run the transition table → compute the target rect → flip back → write.
@MainActor
final class SnapController {
    private let frameStore = WindowFrameStore()

    func handle(_ action: HotkeyAction) {
        guard AXPermissions.isTrusted else {
            NSSound.beep()
            return
        }
        guard let window = AXWindow.focused(),
              window.isStandardWindow,
              !window.isFullscreen,
              let axFrame = window.frame
        else {
            NSSound.beep()
            return
        }
        let cocoaFrame = ScreenCoordinates.flip(axFrame)
        guard let screen = ScreenCoordinates.screen(containing: cocoaFrame) else {
            NSSound.beep()
            return
        }
        let visible = screen.visibleFrame

        switch action {
        case .snapLeft: snap(.left, window: window, frame: cocoaFrame, visible: visible)
        case .snapRight: snap(.right, window: window, frame: cocoaFrame, visible: visible)
        case .snapUp: snap(.up, window: window, frame: cocoaFrame, visible: visible)
        case .snapDown: snap(.down, window: window, frame: cocoaFrame, visible: visible)
        case .displayNext: moveToDisplay(forward: true, window: window, frame: cocoaFrame, screen: screen)
        case .displayPrev: moveToDisplay(forward: false, window: window, frame: cocoaFrame, screen: screen)
        }
    }

    private func snap(_ direction: Direction, window: AXWindow, frame: CGRect, visible: CGRect) {
        let current = StateDetector.detectLayout(of: frame, in: visible)
        switch Transitions.transition(from: current, direction: direction) {
        case .apply(let layout):
            apply(LayoutEngine.frame(for: layout, in: visible), to: window)
        case .maximizeStoringCurrent:
            frameStore.store(frame, for: window)
            apply(visible, to: window)
        case .restorePrevious:
            if let previous = frameStore.retrieve(for: window) {
                apply(previous, to: window)
            } else {
                NSSound.beep()
            }
        case .none:
            break
        }
    }

    private func moveToDisplay(forward: Bool, window: AXWindow, frame: CGRect, screen: NSScreen) {
        guard let destination = ScreenCoordinates.nextScreen(after: screen, forward: forward) else {
            NSSound.beep() // only one display
            return
        }
        let sourceVisible = screen.visibleFrame
        let destVisible = destination.visibleFrame

        let target: CGRect
        if let layout = StateDetector.detectLayout(of: frame, in: sourceVisible) {
            // Snapped windows re-snap pixel-perfect on the destination.
            target = LayoutEngine.frame(for: layout, in: destVisible)
        } else {
            let scaled = DisplayTransfer.transferredFrame(window: frame, from: sourceVisible, to: destVisible)
            target = DisplayTransfer.clamped(scaled, into: destVisible)
        }
        apply(target, to: window)
    }

    private func apply(_ cocoaRect: CGRect, to window: AXWindow) {
        window.setFrame(ScreenCoordinates.flip(cocoaRect))
    }
}
