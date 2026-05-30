import Foundation
import UserNotifications

// MARK: - Pre-meeting notifications (3.2)
// Schedules native macOS notifications a few minutes before each meeting starts.
// 100% local — UNUserNotificationCenter delivers on-device, no network.

@MainActor
final class NotificationManager {
    static let shared = NotificationManager()
    private let center = UNUserNotificationCenter.current()
    private var authorized = false

    private init() {}

    /// Ask for permission once (no-op if notifications are disabled in settings).
    func requestAuthorizationIfNeeded() {
        guard AppSettings.shared.notificationsEnabled else { return }
        center.requestAuthorization(options: [.alert, .sound]) { [weak self] granted, _ in
            Task { @MainActor in self?.authorized = granted }
        }
    }

    /// Replace all pending pre-meeting notifications with fresh ones for the
    /// given upcoming meetings. Call this on every reload so they stay in sync
    /// with the calendar (cancelled/moved meetings get re-scheduled correctly).
    func reschedule(for meetings: [Meeting]) {
        let settings = AppSettings.shared

        // Always clear our previously scheduled requests first.
        center.removeAllPendingNotificationRequests()
        guard settings.notificationsEnabled, !settings.notifyLeadMinutes.isEmpty else { return }

        // Lazily ensure we have permission.
        center.getNotificationSettings { [weak self] s in
            guard let self else { return }
            if s.authorizationStatus == .notDetermined {
                Task { @MainActor in self.requestAuthorizationIfNeeded() }
            }
        }

        let now = Date()
        for meeting in meetings {
            for lead in settings.notifyLeadMinutes {
                let fireDate = meeting.start.addingTimeInterval(-Double(lead) * 60)
                guard fireDate > now else { continue } // skip past times

                let content = UNMutableNotificationContent()
                content.title = lead == 0 ? "Meeting starting" : "Meeting in \(lead) min"
                content.subtitle = meeting.title
                if let link = meeting.joinLink {
                    content.body = "Tap to join (\(link.provider))."
                    content.userInfo = ["joinURL": link.url.absoluteString]
                }
                content.sound = .default

                let interval = max(1, fireDate.timeIntervalSince(now))
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
                let id = "\(meeting.id)#\(lead)"
                center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
            }
        }
    }
}
