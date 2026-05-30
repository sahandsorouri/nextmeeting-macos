# NextMeeting

## What is this project?
A personal macOS menu bar app that shows my next calendar meeting with a compact live
countdown and one-click join. Built for myself first; may later be packaged as a signed
`.dmg` to share with others.

## Stack
- **Language:** Swift
- **UI:** SwiftUI (`MenuBarExtra` for the menu bar item)
- **Calendar access:** EventKit (reads the native macOS Calendar.app)
- **Launch at login:** `SMAppService`
- **No database, no backend, no third-party dependencies** (Sparkle is the only optional
  dependency, added later only if auto-update is wanted)

## Target / requirements
- macOS 14.0+ (Sonoma) — chosen so we can use the modern `MenuBarExtra` SwiftUI API
- Apple Silicon + Intel (universal build for distribution)
- Xcode project, SwiftUI App lifecycle

## Where does it deploy?
- Local: runs on my own Mac.
- Distribution (later): code-signed + notarized, packaged as a drag-to-Applications `.dmg`.
- Not a server app. No remote deployment to the SSH server.

## Hard constraints (these are the whole point of building my own)
1. **The menu bar label MUST stay compact.**
   - Capped lookahead — never show meetings far in the future (no "1 mth 2 wks").
   - Truncate long titles (max ~20 chars + "…").
   - Compact countdown only: `15m`, `1h 20m`, `Now`. Never weeks/months in the bar.
   - When no meeting is imminent, show a minimal icon (or nothing) — not a fat label.
2. **Source of truth = macOS Calendar via EventKit.** All existing accounts (iCloud,
   Google, Exchange, CalDAV) flow in automatically. Per-calendar include/exclude.
3. **100% local & private.** No analytics, no telemetry, no network — except when the
   user explicitly opens a meeting link.

## Privacy
All processing is local. Only network activity is opening a meeting URL the user clicked.
`NSCalendarsUsageDescription` is the only sensitive permission at MVP; Accessibility is
added later for the global hotkey.

## Conventions / preferences
- Respond in English.
- Keep all files inside this project directory.
- Build one feature at a time, each only after my explicit approval (see ROADMAP.md).
- No third-party dependencies unless I approve them.

---

## Full feature list

### Core
- Menu bar item with live, compact countdown to the next meeting.
- Reads local macOS Calendar via EventKit (all accounts).
- Dropdown showing next meeting: title, time, date, detected join link.
- One-click join (open the meeting link).
- Global keyboard shortcut to join the current/next meeting from any app.
- Meeting-link detection from event title, notes, location, and URL fields.
  Providers: Zoom, Google Meet, Microsoft Teams, WebEx, Whereby, Around, Discord,
  Slack Huddles, Jitsi.

### Display & list
- "Meetings" submenu: list of upcoming meetings (within the lookahead window).
- Configurable lookahead window (12h / 24h).
- In-progress indicator (meeting happening now, with time remaining).
- Sensible handling of all-day / no-link events.
- Friendly empty state when nothing is upcoming.

### Compactness (hard constraint #1)
- Hard lookahead cap in the menu bar.
- Truncated, fixed-max-width label.
- Minimal/hidden label when no imminent meeting.
- "Only show within X minutes" threshold setting.

### Settings
- Calendar picker (include/exclude calendars).
- Refresh interval (30s / 60s / 5m).
- Launch at login (`SMAppService`).
- Menu bar format: show/hide title, truncation length, 12h/24h time.
- Customizable global shortcut.

### Alerts (optional, later)
- Full-screen or notification alert before a meeting (at start / 1 min / 5 min before).
- Native macOS notifications as a lighter alternative.

### Distribution & polish (later)
- App icon + template menu bar icon (adapts to light/dark).
- Code signing + notarization.
- DMG packaging (drag to Applications).
- Sparkle auto-update (optional).
- About / version window.
