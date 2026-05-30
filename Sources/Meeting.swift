import Foundation
import SwiftUI
import EventKit

// MARK: - Calendar model (for the include/exclude picker)

struct CalendarInfo: Identifiable, Equatable {
    let id: String
    let title: String
    let color: Color
}

// MARK: - Meeting model
// A lightweight value type. We never hold onto EKEvent objects in the UI.

struct Meeting: Identifiable {
    let id: String
    let title: String
    let start: Date
    let end: Date
    let calendarName: String
    let joinLink: DetectedLink?

    init(event: EKEvent) {
        self.id = event.eventIdentifier ?? UUID().uuidString
        self.title = (event.title?.isEmpty == false ? event.title! : "(No title)")
        self.start = event.startDate
        self.end = event.endDate
        self.calendarName = event.calendar?.title ?? ""
        self.joinLink = LinkDetector.detect(in: [
            event.url?.absoluteString,
            event.location,
            event.notes,
            event.title,
        ])
    }

    func isInProgress(at now: Date) -> Bool {
        start <= now && end > now
    }
}

// MARK: - Compact formatting (hard constraint #1)

enum Format {
    /// Compact duration: "15m", "1h 20m", "1d 3h". Days for anything ≥ 24h
    /// (the 7-day lookahead cap means we never reach weeks/months).
    static func duration(_ interval: TimeInterval) -> String {
        let mins = max(0, (Int(interval) + 59) / 60) // round up: 59s → "1m"
        if mins < 60 { return "\(mins)m" }
        let hours = mins / 60
        let m = mins % 60
        if hours < 24 {
            return m == 0 ? "\(hours)h" : "\(hours)h \(m)m"
        }
        let days = hours / 24
        let h = hours % 24
        return h == 0 ? "\(days)d" : "\(days)d \(h)h"
    }

    /// Countdown shown next to a meeting.
    /// - Before it starts: time until start.
    /// - While it's running: time left until it ends.
    static func countdown(to start: Date, end: Date, now: Date) -> String {
        if start <= now && end > now {
            return duration(end.timeIntervalSince(now)) // in progress → time remaining
        }
        return duration(start.timeIntervalSince(now))
    }

    /// Truncate a long title to keep the menu bar label compact.
    static func shortTitle(_ title: String, max: Int = 20) -> String {
        let cap = Swift.max(4, max)
        guard title.count > cap else { return title }
        let idx = title.index(title.startIndex, offsetBy: cap)
        return String(title[..<idx]).trimmingCharacters(in: .whitespaces) + "…"
    }

    /// Wall-clock time honoring the user's 12h/24h preference.
    static func time(_ date: Date, use24Hour: Bool) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = use24Hour ? "HH:mm" : "h:mm a"
        return f.string(from: date)
    }
}
