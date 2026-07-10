import Foundation
import ServiceManagement

@MainActor
enum LaunchAtLogin {
    /// SMAppService only works for a bundled .app; `swift run` builds a bare
    /// executable where registration would fail confusingly.
    static var isAvailable: Bool {
        Bundle.main.bundleURL.pathExtension == "app"
    }

    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static func toggle() {
        do {
            if isEnabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            NSLog("MoveWindows: launch-at-login toggle failed: \(error)")
        }
    }
}
