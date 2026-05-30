import SwiftUI
import ServiceManagement

// MARK: - Launch at login
// Thin wrapper over SMAppService so the app can start itself when you log in.

@MainActor
final class LaunchAtLogin: ObservableObject {
    static let shared = LaunchAtLogin()

    @Published private(set) var isEnabled = false

    private init() { refresh() }

    func refresh() {
        isEnabled = SMAppService.mainApp.status == .enabled
    }

    func set(_ on: Bool) {
        do {
            if on {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            // Non-fatal: leave the toggle reflecting the real status.
        }
        refresh()
    }
}
