import SwiftUI
import EventKit
import Combine

// MARK: - MeetingStore
// Owns calendar access, reads events locally via EventKit, and keeps the
// "next meeting" + upcoming list fresh. No networking anywhere.

@MainActor
final class MeetingStore: ObservableObject {
    enum Access {
        case unknown   // haven't asked / waiting for the prompt
        case granted
        case denied
    }

    @Published var access: Access = .unknown
    @Published var nextMeeting: Meeting?
    @Published var upcoming: [Meeting] = []
    @Published var now: Date = Date()
    @Published var calendars: [CalendarInfo] = []

    // Lookahead is user-configurable (AppSettings). The menu bar stays compact
    // via a separate "show within X minutes" threshold — the two are decoupled.
    private var lookahead: TimeInterval { AppSettings.shared.lookahead }

    private let store = EKEventStore()
    private var tickTimer: Timer?
    private var refreshTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    init() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(storeChanged),
            name: .EKEventStoreChanged, object: store
        )
        // Reload automatically when the lookahead window or the set of included
        // calendars changes in Settings.
        AppSettings.shared.$lookaheadHours
            .dropFirst()
            .sink { [weak self] _ in
                Task { @MainActor in self?.reload() }
            }
            .store(in: &cancellables)

        AppSettings.shared.$excludedCalendarIDs
            .dropFirst()
            .sink { [weak self] _ in
                Task { @MainActor in self?.reload() }
            }
            .store(in: &cancellables)

        // Rebuild the reload timer when the refresh interval changes.
        AppSettings.shared.$refreshIntervalSeconds
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] _ in
                Task { @MainActor in self?.configureRefreshTimer() }
            }
            .store(in: &cancellables)

        // Global hotkey → join. Re-register whenever the shortcut changes.
        HotkeyManager.shared.onTrigger = { [weak self] in
            Task { @MainActor in self?.joinCurrent() }
        }
        registerHotkey()
        AppSettings.shared.$hotkeyKeyCode
            .combineLatest(AppSettings.shared.$hotkeyModifiers)
            .dropFirst()
            .sink { [weak self] _ in
                Task { @MainActor in self?.registerHotkey() }
            }
            .store(in: &cancellables)

        startTimers()
        requestAccess()
    }

    private func registerHotkey() {
        let s = AppSettings.shared
        HotkeyManager.shared.update(
            keyCode: s.hotkeyKeyCode,
            modifiers: NSEvent.ModifierFlags(rawValue: UInt(s.hotkeyModifiers))
        )
    }

    /// Open the join link for the current/next meeting (used by the global hotkey
    /// and could be reused elsewhere). The only network action, user-initiated.
    func joinCurrent() {
        guard let link = (nextMeeting ?? upcoming.first)?.joinLink else { return }
        NSWorkspace.shared.open(link.url)
    }

    // MARK: Permission

    func requestAccess() {
        store.requestFullAccessToEvents { [weak self] granted, _ in
            Task { @MainActor in
                guard let self else { return }
                self.access = granted ? .granted : .denied
                if granted { self.reload() }
            }
        }
    }

    // MARK: Loading

    func reload() {
        guard access == .granted else { return }

        // Refresh the available-calendars list (for the picker UI).
        let allCalendars = store.calendars(for: .event)
        self.calendars = allCalendars
            .map { CalendarInfo(id: $0.calendarIdentifier, title: $0.title, color: Color(cgColor: $0.cgColor)) }
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }

        let nowDate = Date()
        // Start a little before "now" so meetings already in progress are caught.
        let windowStart = nowDate.addingTimeInterval(-3600)
        let windowEnd = nowDate.addingTimeInterval(lookahead)

        // Only read from calendars the user hasn't switched off.
        let excluded = AppSettings.shared.excludedCalendarIDs
        let included = allCalendars.filter { !excluded.contains($0.calendarIdentifier) }

        guard !included.isEmpty else {
            self.now = nowDate
            self.upcoming = []
            self.nextMeeting = nil
            return
        }

        let predicate = store.predicateForEvents(
            withStart: windowStart, end: windowEnd, calendars: included
        )

        let meetings = store.events(matching: predicate)
            .filter { !$0.isAllDay }                       // all-day handled separately later
            .map(Meeting.init)
            .filter { $0.end > nowDate && $0.start <= windowEnd } // still relevant + within cap
            .sorted { $0.start < $1.start }

        self.now = nowDate
        self.upcoming = meetings
        self.nextMeeting = meetings.first

        // Keep pre-meeting notifications in sync with the calendar.
        NotificationManager.shared.reschedule(for: meetings)
    }

    @objc private func storeChanged() {
        Task { @MainActor in self.reload() }
    }

    // MARK: Timers

    private func startTimers() {
        // Tick every second so the countdown stays live even while the
        // dropdown popover is open (.common mode survives event tracking).
        let tick = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.now = Date()
                // A meeting just ended → advance to the next one.
                if let m = self.nextMeeting, m.end <= self.now {
                    self.reload()
                }
            }
        }
        RunLoop.main.add(tick, forMode: .common)
        tickTimer = tick

        // Re-read the calendar periodically; interval is user-configurable.
        configureRefreshTimer()
    }

    /// (Re)create the periodic reload timer from the current refresh-interval
    /// setting. Called on launch and whenever the setting changes.
    private func configureRefreshTimer() {
        refreshTimer?.invalidate()
        let secs = max(5, AppSettings.shared.refreshIntervalSeconds)
        let refresh = Timer(timeInterval: TimeInterval(secs), repeats: true) { [weak self] _ in
            Task { @MainActor in self?.reload() }
        }
        RunLoop.main.add(refresh, forMode: .common)
        refreshTimer = refresh
    }
}
