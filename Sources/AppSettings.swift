import SwiftUI
import AppKit

// MARK: - AppSettings
// Persisted user preferences (local, via UserDefaults). Shared singleton so both
// the MeetingStore and the views read the same values.

@MainActor
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    /// How far ahead to look for meetings (feeds the dropdown + next meeting).
    @Published var lookaheadHours: Int {
        didSet { UserDefaults.standard.set(lookaheadHours, forKey: Keys.lookaheadHours) }
    }

    /// Compactness control: only reveal the countdown in the menu bar when the
    /// meeting starts within this many minutes. 0 = always show.
    /// A meeting days away stays a minimal icon until it's close.
    @Published var barThresholdMinutes: Int {
        didSet { UserDefaults.standard.set(barThresholdMinutes, forKey: Keys.barThresholdMinutes) }
    }

    /// How often to re-fetch events from Calendar, in seconds (default 60).
    /// The 1s countdown tick is separate and always runs.
    @Published var refreshIntervalSeconds: Int {
        didSet { UserDefaults.standard.set(refreshIntervalSeconds, forKey: Keys.refreshIntervalSeconds) }
    }

    /// Calendars the user has switched OFF. Empty = all calendars included.
    /// (Storing exclusions means new calendars are included by default.)
    @Published var excludedCalendarIDs: Set<String> {
        didSet { UserDefaults.standard.set(Array(excludedCalendarIDs), forKey: Keys.excludedCalendarIDs) }
    }

    // --- Pre-meeting notifications (3.2) ---
    /// Master switch for native notifications before a meeting starts.
    @Published var notificationsEnabled: Bool {
        didSet { UserDefaults.standard.set(notificationsEnabled, forKey: Keys.notificationsEnabled) }
    }
    /// Minutes-before-start to fire a notification (0 = at start). Multiple allowed.
    @Published var notifyLeadMinutes: Set<Int> {
        didSet { UserDefaults.standard.set(Array(notifyLeadMinutes), forKey: Keys.notifyLeadMinutes) }
    }

    // --- Menu bar format options (2.4) ---
    /// Show the meeting title next to the countdown in the bar.
    @Published var barShowTitle: Bool {
        didSet { UserDefaults.standard.set(barShowTitle, forKey: Keys.barShowTitle) }
    }
    /// Max characters of the title shown in the bar before truncation.
    @Published var barTitleMaxChars: Int {
        didSet { UserDefaults.standard.set(barTitleMaxChars, forKey: Keys.barTitleMaxChars) }
    }
    /// Use 24-hour time in the dropdown (false = 12-hour).
    @Published var use24HourTime: Bool {
        didSet { UserDefaults.standard.set(use24HourTime, forKey: Keys.use24HourTime) }
    }

    // Global "join" shortcut — fully customizable.
    @Published var hotkeyKeyCode: Int {
        didSet { UserDefaults.standard.set(hotkeyKeyCode, forKey: Keys.hotkeyKeyCode) }
    }
    @Published var hotkeyModifiers: Int {
        didSet { UserDefaults.standard.set(hotkeyModifiers, forKey: Keys.hotkeyModifiers) }
    }
    @Published var hotkeyDisplay: String {
        didSet { UserDefaults.standard.set(hotkeyDisplay, forKey: Keys.hotkeyDisplay) }
    }

    private enum Keys {
        static let lookaheadHours = "lookaheadHours"
        static let barThresholdMinutes = "barThresholdMinutes"
        static let refreshIntervalSeconds = "refreshIntervalSeconds"
        static let excludedCalendarIDs = "excludedCalendarIDs"
        static let notificationsEnabled = "notificationsEnabled"
        static let notifyLeadMinutes = "notifyLeadMinutes"
        static let barShowTitle = "barShowTitle"
        static let barTitleMaxChars = "barTitleMaxChars"
        static let use24HourTime = "use24HourTime"
        static let hotkeyKeyCode = "hotkeyKeyCode"
        static let hotkeyModifiers = "hotkeyModifiers"
        static let hotkeyDisplay = "hotkeyDisplay"
    }

    private init() {
        let d = UserDefaults.standard
        lookaheadHours = d.object(forKey: Keys.lookaheadHours) as? Int ?? 24
        barThresholdMinutes = d.object(forKey: Keys.barThresholdMinutes) as? Int ?? 0
        refreshIntervalSeconds = d.object(forKey: Keys.refreshIntervalSeconds) as? Int ?? 60
        excludedCalendarIDs = Set(d.stringArray(forKey: Keys.excludedCalendarIDs) ?? [])

        notificationsEnabled = d.object(forKey: Keys.notificationsEnabled) as? Bool ?? false
        let leads = (d.array(forKey: Keys.notifyLeadMinutes) as? [Int]) ?? [5, 1]
        notifyLeadMinutes = Set(leads)

        barShowTitle = d.object(forKey: Keys.barShowTitle) as? Bool ?? true
        barTitleMaxChars = d.object(forKey: Keys.barTitleMaxChars) as? Int ?? 20
        use24HourTime = d.object(forKey: Keys.use24HourTime) as? Bool ?? false

        // Default: ⌘⇧J (keyCode 38). Stored so the user can change it.
        let defaultMods = Int(NSEvent.ModifierFlags([.command, .shift]).rawValue)
        hotkeyKeyCode = d.object(forKey: Keys.hotkeyKeyCode) as? Int ?? 38
        hotkeyModifiers = d.object(forKey: Keys.hotkeyModifiers) as? Int ?? defaultMods
        hotkeyDisplay = d.object(forKey: Keys.hotkeyDisplay) as? String ?? "⌘⇧J"
    }

    func setHotkey(keyCode: Int, modifiers: NSEvent.ModifierFlags, display: String) {
        hotkeyKeyCode = keyCode
        hotkeyModifiers = Int(modifiers.rawValue)
        hotkeyDisplay = display
    }

    var lookahead: TimeInterval { TimeInterval(lookaheadHours) * 3600 }

    /// Human-readable window, e.g. "24 hours" or "7 days".
    var lookaheadLabel: String {
        lookaheadHours % 24 == 0
            ? "\(lookaheadHours / 24) day\(lookaheadHours / 24 == 1 ? "" : "s")"
            : "\(lookaheadHours) hours"
    }
}
