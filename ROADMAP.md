# NextMeeting — Roadmap

Build order. Each step is built **only after explicit approval**, then verified before
moving on. Tier 0 → 3.

---

## Tier 0 — Project scaffold ✅
**Goal:** an empty app that launches and puts a static icon in the menu bar.
- [x] 0.1 Command-line build setup (no full Xcode installed — only Command Line Tools).
      Build via `swiftc` + `build.sh`; SwiftUI App lifecycle, macOS 14 target.
- [x] 0.2 `MenuBarExtra` with a static calendar icon + placeholder dropdown ("No meetings").
- [x] 0.3 App runs as a menu-bar-only agent (`LSUIElement` — no Dock icon, no main window).
- [x] 0.4 Builds and launches on my Mac.
**Done when:** icon appears in the menu bar, dropdown opens. ✅

### Build notes
- No full Xcode — we build from CLI: `./build.sh` (or `./build.sh run` to launch).
- Project dir is iCloud-synced, so the script strips `com.apple.FinderInfo` before
  ad-hoc signing (`codesign -s -`), otherwise signing fails.
- **No Apple Developer account** — distribution will be ad-hoc signed. Others open the
  .dmg via right-click → Open the first time (Gatekeeper warning is expected, not a bug).

---

## Tier 1 — MVP (the thing I actually need daily)
**Goal:** see my real next meeting, compact, and join it.
- [ ] 1.1 EventKit permission flow (`NSCalendarsUsageDescription`, request access, handle denial).
- [ ] 1.2 Fetch events from Calendar within a capped lookahead (default 12h).
- [ ] 1.3 Determine "next meeting" (next upcoming or currently in-progress).
- [ ] 1.4 Compact menu bar label: `15m`, `1h 20m`, `Now`, truncated title, minimal when idle.
- [ ] 1.5 Live refresh (timer) so the countdown updates.
- [ ] 1.6 Meeting-link detection (Zoom, Meet, Teams, WebEx, Whereby, Discord, Slack, Jitsi).
- [ ] 1.7 Dropdown: next meeting title, time, date, join link → one-click open.
- [ ] 1.8 Calendar picker (include/exclude) — minimal version.
- [ ] 1.9 Launch at login (`SMAppService`).
**Done when:** my real next meeting shows compactly and I can click to join.

### Done so far in Tier 1
- [x] 1.1 EventKit permission flow (request + denied state + Open Settings button).
- [x] 1.2 Fetch events within a configurable lookahead.
- [x] 1.3 Next-meeting / in-progress detection.
- [x] 1.4 Compact menu bar label (truncated title, `15m` / `1h 20m` / `Now`).
- [x] 1.5 Live 1s countdown + 60s reload + instant reload on calendar change.
- [x] 1.7 Dropdown: title, day, time range, countdown, calendar name.
- [x] Settings (pulled forward from Tier 2): **Look ahead** (12h/24h/48h/7d) and
      **Show in bar** threshold (Always / 60 / 30 / 15 min) — decouples lookahead
      from menu bar compactness. Default lookahead = 24h.
- [x] 1.6 Meeting-link detection (Zoom/Meet/Teams/Webex/Whereby/Around/Discord/
      Slack/Jitsi) across title, location, notes, url fields + one-click Join button.
- [x] 2.1 (pulled forward) "Later" list of other meetings within lookahead, each with
      a compact countdown and its own Join control.
- [x] 1.8 Calendar picker — click "Calendars" row → popover with checkbox list +
      per-calendar color dots (stores exclusions; new calendars included by default).
- [x] Polish: in-progress meetings show time remaining ("12m left", bar shows only the
      remaining time without title); countdowns ≥24h show days ("1d 3h").
- [x] 1.9 Launch at login (SMAppService toggle).

## Tier 2 — progress
- [x] 2.1 "Later" list (done earlier).
- [x] 2.2 In-progress indicator with time remaining.
- [x] 2.3 Lookahead + "show in bar" threshold + **refresh interval (30s/60s/5m)**
      settings. The reload timer reconfigures live when the interval changes.
- [x] 2.6 Global shortcut to join via Carbon RegisterEventHotKey.
      No Accessibility permission needed.
- [x] 2.4 Menu bar format options — show/hide title in bar, title length
      (10/15/20/30 chars), and 12h/24h time format (applied to dropdown times).
- [ ] 2.5 All-day handling: currently all-day events are excluded (sensible). No-link
      events already show without a Join button. Revisit if needed.
- [x] 2.7 Customizable shortcut binding.

### UI/layout notes (resolved with the user)
- Settings live inline in the popover (no separate window, no expand/collapse).
- Popover is a **constant size**: the meeting list is a fixed-height (200pt) scroll
  area so changing lookahead/calendars never resizes or clips the popover — this was
  important in fullscreen. The calendar picker is a Menu (overlay) for the same reason.

---

## Tier 2 — v1.1 (quality of life)
**Goal:** the polished daily driver.
- [ ] 2.1 "Meetings" submenu: full upcoming list within lookahead.
- [ ] 2.2 In-progress indicator with time remaining.
- [ ] 2.3 Settings window: lookahead (12h/24h), refresh interval, "show within X min" threshold.
- [ ] 2.4 Menu bar format options: show/hide title, truncation length, 12h/24h time.
- [ ] 2.5 All-day / no-link event handling + empty state.
- [x] 2.6 Global keyboard shortcut to join.
- [x] 2.7 Customizable shortcut binding.
**Done when:** all settings work and the bar behaves exactly how I want.

---

## Tier 3 — Distribution (share the .dmg)
**Goal:** others can install it cleanly.
- [x] 3.1 App icon + menu bar icon. App icon = custom calendar+play glyph
      (`Scripts/generate_icons.swift` → `Resources/NextMeeting.icns`, shown in
      Finder + About panel). Menu bar **idle** icon = native SF Symbol `calendar`
      so the system renders it at the exact standard size/weight (a custom
      resizable image got stretched to full bar height and looked oversized —
      calibrated via `Scripts/calibrate.swift`: SF glyph fills ~94% of its box).
- [x] 3.2 Pre-meeting alerts — native local notifications (`NotificationManager`),
      fired 1/5/10 min before start (user-selectable). Tapping a notification opens
      the join link. Rescheduled on every reload to stay in sync with the calendar.
      All on-device (`UNUserNotificationCenter`), no network.
- [x] 3.3 About / version window — native standard About panel (`About.show()`),
      shows the app icon + version from Info.plist. "About" button in the popover.
- [x] 3.4 Universal build (arm64 + x86_64) via `./build.sh universal` (compiles
      each slice, merges with `lipo`). Verified: binary reports `x86_64 arm64`.
- [ ] 3.5 Code signing + notarization (Developer ID) — **N/A for now**: no Apple
      Developer account. App is ad-hoc signed; DMG is not notarized.
- [x] 3.6 DMG packaging (drag-to-Applications) via `./package_dmg.sh` — builds a
      universal app, stages it with an `/Applications` symlink, makes a compressed
      UDZO `.dmg` named by version (e.g. `build/NextMeeting-0.0.1.dmg`, ~816K).
- [ ] 3.7 (Optional) Sparkle auto-update.
**Done when:** the .dmg installs (first launch: right-click → Open, since it's
not notarized — Gatekeeper warning is expected, not a bug).

---

## Open questions to resolve before/while building
- App name: **NextMeeting** (placeholder — change anytime).
- Apple Developer account: **No** — ad-hoc signed .dmg only (decided).
- Global shortcut is customizable; default remains Cmd+Shift+J unless changed in settings.
