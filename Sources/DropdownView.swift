import SwiftUI

// MARK: - Dropdown content

struct DropdownView: View {
    @EnvironmentObject var store: MeetingStore
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var login = LaunchAtLogin.shared
    @State private var showCalendars = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("NextMeeting")
                .font(.headline)

            // Meeting list lives in a constant-height area that scrolls
            // internally. The number of meetings can change with the lookahead,
            // but the total popover height stays fixed — so it never jumps or
            // clips, including in fullscreen.
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    switch store.access {
                    case .unknown:
                        Text("Requesting calendar access…")
                            .foregroundStyle(.secondary)
                    case .denied:
                        deniedView
                    case .granted:
                        grantedView
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing, 2)
            }
            .frame(height: listHeight)

            Divider()

            // Settings always visible inline — nothing expands/collapses.
            settingsSection

            Divider()

            HStack {
                Button("Refresh") { store.reload() }
                Button("About") { About.show() }
                Spacer()
                Button("Quit") { NSApplication.shared.terminate(nil) }
                    .keyboardShortcut("q")
            }
        }
        .padding(16)
        .frame(width: 300)
        .fixedSize(horizontal: false, vertical: true)
    }

    /// Constant height for the meeting list area. Sized to comfortably show the
    /// next-meeting card plus a couple of "Later" rows; more than that scrolls.
    private var listHeight: CGFloat { 200 }

    // MARK: Settings (inline)

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Two compact, aligned rows: label on the left, control on the right.
            settingRow("Look ahead") {
                Picker("", selection: $settings.lookaheadHours) {
                    Text("12 hours").tag(12)
                    Text("24 hours").tag(24)
                    Text("48 hours").tag(48)
                    Text("7 days").tag(168)
                }
                .labelsHidden()
                .fixedSize()
            }

            settingRow("Show in bar") {
                Picker("", selection: $settings.barThresholdMinutes) {
                    Text("Always").tag(0)
                    Text("Within 60 min").tag(60)
                    Text("Within 30 min").tag(30)
                    Text("Within 15 min").tag(15)
                }
                .labelsHidden()
                .fixedSize()
            }

            settingRow("Refresh") {
                Picker("", selection: $settings.refreshIntervalSeconds) {
                    Text("30s").tag(30)
                    Text("60s").tag(60)
                    Text("5 min").tag(300)
                }
                .labelsHidden()
                .fixedSize()
            }

            // Calendars: a single clickable row that opens the checkbox list in
            // a popover — out of sight until you need it.
            if !store.calendars.isEmpty {
                settingRow("Calendars") {
                    Button {
                        showCalendars.toggle()
                    } label: {
                        HStack(spacing: 4) {
                            Text(calendarSummary)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption2)
                        }
                    }
                    .popover(isPresented: $showCalendars, arrowEdge: .trailing) {
                        calendarPicker
                    }
                }
            }

            settingRow("Launch at login") {
                Toggle("", isOn: Binding(
                    get: { login.isEnabled },
                    set: { login.set($0) }
                ))
                .labelsHidden()
                .toggleStyle(.switch)
            }

            settingRow("Join shortcut") {
                ShortcutRecorderView()
            }

            // --- Menu bar format (2.4) ---
            settingRow("Title in bar") {
                Toggle("", isOn: $settings.barShowTitle)
                    .labelsHidden()
                    .toggleStyle(.switch)
            }

            if settings.barShowTitle {
                settingRow("Title length") {
                    Picker("", selection: $settings.barTitleMaxChars) {
                        Text("10").tag(10)
                        Text("15").tag(15)
                        Text("20").tag(20)
                        Text("30").tag(30)
                    }
                    .labelsHidden()
                    .fixedSize()
                }
            }

            settingRow("Time format") {
                Picker("", selection: $settings.use24HourTime) {
                    Text("12-hour").tag(false)
                    Text("24-hour").tag(true)
                }
                .labelsHidden()
                .fixedSize()
            }

            // --- Pre-meeting notifications (3.2) ---
            settingRow("Notify before") {
                Toggle("", isOn: $settings.notificationsEnabled)
                    .labelsHidden()
                    .toggleStyle(.switch)
            }

            if settings.notificationsEnabled {
                settingRow("Alert at") {
                    HStack(spacing: 10) {
                        ForEach([1, 5, 10], id: \.self) { mins in
                            leadToggle(mins)
                        }
                    }
                }
            }
        }
        .font(.subheadline)
        .pickerStyle(.menu)
        .controlSize(.small)
        .onChange(of: settings.notificationsEnabled) {
            NotificationManager.shared.requestAuthorizationIfNeeded()
            store.reload() // re-schedule with the new preference
        }
        .onChange(of: settings.notifyLeadMinutes) {
            store.reload()
        }
    }

    /// A small checkbox for a "minutes before" notification lead time.
    private func leadToggle(_ mins: Int) -> some View {
        Toggle(isOn: Binding(
            get: { settings.notifyLeadMinutes.contains(mins) },
            set: { on in
                if on { settings.notifyLeadMinutes.insert(mins) }
                else { settings.notifyLeadMinutes.remove(mins) }
            }
        )) {
            Text("\(mins)m")
        }
        .toggleStyle(.checkbox)
    }

    private var calendarSummary: String {
        let total = store.calendars.count
        let excluded = store.calendars.filter { settings.excludedCalendarIDs.contains($0.id) }.count
        return excluded == 0 ? "All" : "\(total - excluded) of \(total)"
    }

    // The pop-out checkbox list (with color dots).
    private var calendarPicker: some View {
        let checks = VStack(alignment: .leading, spacing: 6) {
            ForEach(store.calendars) { cal in
                Toggle(isOn: calendarBinding(cal.id)) {
                    HStack(spacing: 6) {
                        Circle().fill(cal.color).frame(width: 8, height: 8)
                        Text(cal.title).lineLimit(1)
                    }
                }
                .toggleStyle(.checkbox)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)

        return VStack(alignment: .leading, spacing: 8) {
            Text("Show calendars")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            if store.calendars.count > 8 {
                ScrollView { checks }.frame(height: 220)
            } else {
                checks
            }
        }
        .padding(14)
        .frame(width: 240)
    }

    /// A tidy label-left / control-right settings row.
    private func settingRow<Control: View>(
        _ label: String,
        @ViewBuilder control: () -> Control
    ) -> some View {
        HStack {
            Text(label)
            Spacer()
            control()
        }
    }

    private func calendarBinding(_ id: String) -> Binding<Bool> {
        Binding(
            get: { !settings.excludedCalendarIDs.contains(id) },
            set: { isOn in
                if isOn { settings.excludedCalendarIDs.remove(id) }
                else { settings.excludedCalendarIDs.insert(id) }
            }
        )
    }

    // MARK: Granted

    @ViewBuilder private var grantedView: some View {
        if let next = store.nextMeeting {
            nextCard(next)

            let later = Array(store.upcoming.dropFirst())
            if !later.isEmpty {
                Divider()
                Text("Later")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(later) { laterRow($0) }
                }
            }
        } else {
            Text("No meetings in the next \(settings.lookaheadLabel)")
                .foregroundStyle(.secondary)
        }
    }

    // The prominent next-meeting card.
    private func nextCard(_ m: Meeting) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(m.title)
                .font(.headline)
                .lineLimit(2)

            Text(m.start, format: .dateTime.weekday(.wide).month().day())
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 6) {
                Text(Format.time(m.start, use24Hour: settings.use24HourTime))
                Text("–")
                Text(Format.time(m.end, use24Hour: settings.use24HourTime))
                Spacer()
                let inProgress = m.isInProgress(at: store.now)
                Text(inProgress
                     ? "\(Format.countdown(to: m.start, end: m.end, now: store.now)) left"
                     : Format.countdown(to: m.start, end: m.end, now: store.now))
                    .fontWeight(.semibold)
                    .foregroundStyle(inProgress ? .green : .primary)
            }
            .font(.subheadline)

            HStack {
                if !m.calendarName.isEmpty {
                    Text(m.calendarName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if let link = m.joinLink {
                    Button {
                        NSWorkspace.shared.open(link.url)
                    } label: {
                        Label("Join \(link.provider)", systemImage: "video.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
            .padding(.top, 2)
        }
    }

    // A compact row in the "Later" list.
    private func laterRow(_ m: Meeting) -> some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 1) {
                Text(m.title)
                    .font(.subheadline)
                    .lineLimit(1)
                (Text(m.start, format: .dateTime.weekday(.abbreviated)) + Text(" ")
                    + Text(Format.time(m.start, use24Hour: settings.use24HourTime)))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(Format.countdown(to: m.start, end: m.end, now: store.now))
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            if let link = m.joinLink {
                Button {
                    NSWorkspace.shared.open(link.url)
                } label: {
                    Image(systemName: "video.fill")
                }
                .buttonStyle(.borderless)
                .help("Join \(link.provider)")
            }
        }
    }

    // MARK: Denied

    private var deniedView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Calendar access denied")
                .foregroundStyle(.secondary)
            Text("Enable it in System Settings → Privacy & Security → Calendars, then Refresh.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Button("Open Privacy Settings") {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }
}
