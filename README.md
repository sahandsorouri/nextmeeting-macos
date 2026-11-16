<img src="https://raw.githubusercontent.com/sahandsorouri/sahandsorouri/main/assets/banner.svg" alt="Sahand Sorouri" width="100%">

# NextMeeting

A small macOS menu bar countdown to your next meeting, read from Apple Calendar, fully on your Mac.

No account, no server, no network calls.

## What it does

- **Next meeting at a glance:** a live countdown in the menu bar (`15m`, `1h 20m`, `Now`), with the title if you want it.
- **One-click join:** finds meeting links (Zoom, Google Meet, Teams, Webex, Whereby, Around, Discord, Slack, Jitsi) in the title, location, notes and URL.
- **Later list:** upcoming meetings, each with its own countdown and join button.
- **Alerts:** native notifications 1, 5 or 10 minutes before a meeting (off by default).
- **Join shortcut:** join the next call from anywhere (default `Cmd+Shift+J`), no Accessibility permission needed.
- **Settings:** pick calendars, lookahead (12 hours to 7 days), refresh interval, 12 or 24 hour time, title length, launch at login.

## Privacy

NextMeeting reads your calendar through Apple's EventKit and keeps everything on your Mac. No backend, no analytics, no network access.

## Install

1. Download the latest `NextMeeting-x.x.x.dmg` from [Releases](https://github.com/sahandsorouri/nextmeeting-macos/releases).
2. Open the DMG and drag NextMeeting to Applications.
3. Open NextMeeting. macOS blocks it the first time, because the app is not notarized by Apple. This is expected.
4. Approve it once:
   - **macOS 15 Sequoia:** open **System Settings > Privacy & Security**, scroll to "NextMeeting was blocked to protect your Mac", click **Open Anyway** and confirm.
   - **macOS 14 Sonoma:** right-click the app in Applications, choose **Open**, then **Open** again.
5. Allow calendar access when asked.

After that it opens normally. Needs macOS 14 or later. Universal app for Apple Silicon and Intel.

## Build from source

Only the Command Line Tools are needed, not full Xcode.

```bash
./build.sh            # fast native dev build
./build.sh run        # build and launch
./build.sh universal  # universal arm64 + x86_64 build
./package_dmg.sh      # build a universal app and package the DMG
```

## Tech

Swift, SwiftUI (MenuBarExtra), EventKit, SMAppService, macOS 14+.

---

Built by [Sahand Sorouri](https://sahand.sorouri.com) · platforms, bots and AI tools for businesses in Dubai.
