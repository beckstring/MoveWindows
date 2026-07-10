import AppKit
import ApplicationServices

@MainActor
enum AXPermissions {
    static var isTrusted: Bool { AXIsProcessTrusted() }

    /// Prompts for the Accessibility permission if missing and polls until it is
    /// granted (there is no system notification for the grant), then calls
    /// `onGranted` once.
    static func ensurePermission(onGranted: @escaping @MainActor () -> Void) {
        if AXIsProcessTrusted() {
            onGranted()
            return
        }
        // Literal value of kAXTrustedCheckOptionPrompt, whose imported global
        // is not concurrency-safe under Swift 6.
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            guard AXIsProcessTrusted() else { return }
            timer.invalidate()
            // The timer fires on the main run loop.
            MainActor.assumeIsolated {
                onGranted()
            }
        }
    }
}
