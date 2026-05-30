import SwiftUI
import AppKit
import UserNotifications

// MARK: - App entry point
// Menu-bar-only app (no Dock icon, no main window — see LSUIElement in Info.plist).

@main
struct NextMeetingApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = MeetingStore()

    var body: some Scene {
        MenuBarExtra {
            DropdownView()
                .environmentObject(store)
        } label: {
            MenuBarLabel(store: store)
        }
        .menuBarExtraStyle(.window) // custom SwiftUI view in the dropdown
    }
}

// MARK: - App delegate (notification handling)

final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        UNUserNotificationCenter.current().delegate = self
        Task { @MainActor in NotificationManager.shared.requestAuthorizationIfNeeded() }
    }

    // Show notifications even while the app is frontmost.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    // Tapping a notification opens the meeting's join link, if any.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if let urlString = response.notification.request.content.userInfo["joinURL"] as? String,
           let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
        completionHandler()
    }
}

// MARK: - Menu bar label (compact — hard constraint #1)

struct MenuBarLabel: View {
    @ObservedObject var store: MeetingStore
    @ObservedObject private var settings = AppSettings.shared

    var body: some View {
        if let m = store.nextMeeting, shouldReveal(m) {
            if m.isInProgress(at: store.now) {
                // During a meeting, just show time remaining — no title needed.
                Text("\(Format.countdown(to: m.start, end: m.end, now: store.now)) left")
            } else if settings.barShowTitle {
                Text("\(Format.countdown(to: m.start, end: m.end, now: store.now)) · \(Format.shortTitle(m.title, max: settings.barTitleMaxChars))")
            } else {
                // Title hidden — countdown only.
                Text(Format.countdown(to: m.start, end: m.end, now: store.now))
            }
        } else {
            // Minimal idle icon. Use a native SF Symbol so the menu bar renders
            // it at the exact system-standard size/weight — a resizable custom
            // image gets stretched to the full bar height and looks oversized.
            Image(systemName: "calendar")
        }
    }

    /// Compactness gate: reveal the countdown only when the meeting is close
    /// enough per the user's threshold. 0 = always reveal.
    private func shouldReveal(_ m: Meeting) -> Bool {
        if settings.barThresholdMinutes == 0 { return true }
        if m.isInProgress(at: store.now) { return true }
        let minutesUntil = m.start.timeIntervalSince(store.now) / 60
        return minutesUntil <= Double(settings.barThresholdMinutes)
    }
}

