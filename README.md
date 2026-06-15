# NextMeeting

A compact macOS menu bar countdown to your next meeting. Reads your Apple Calendar, runs fully on-device, and never sends your data anywhere.

100% local and private. No account, no server, no network calls.

## Why I built it

I used to rely on a menu bar meeting app, but it did not give me the flexibility I wanted, and I was never sure my calendar data stayed on my machine. So I built my own: it connects straight to Apple Calendar, keeps everything local, and adds the features I actually use every day.

## Features

- **Next meeting at a glance.** Compact menu bar label with a live countdown (`15m`, `1h 20m`, `Now`) and optional title.
- **One-click join.** Detects meeting links (Zoom, Google Meet, Teams, Webex, Whereby, Around, Discord, Slack, Jitsi) across title, location, notes, and URL fields.
- **Later list.** Upcoming meetings within your lookahead, each with its own countdown and join button.
- **Pre-meeting alerts.** Native notifications 1, 5, or 10 minutes before a meeting. Off by default, fully on-device.
- **Global join shortcut.** Join the next call from anywhere (default `Cmd+Shift+J`, customizable). No Accessibility permission required.
- **Calendar picker.** Include or exclude any calendar.
- **Flexible settings.** Lookahead (12h to 7d), show-in-bar threshold, refresh interval, 12h/24h time, title length, launch at login.
- **Universal binary.** Native on both Apple Silicon and Intel.

## Privacy

NextMeeting reads your calendar through Apple's EventKit and keeps everything on your Mac. There is no backend, no analytics, and no network access. Your schedule never leaves your laptop.

## Install

1. Download the latest `NextMeeting-x.x.x.dmg` from [Releases](https://github.com/sahandsorouri/nextmeeting-macos/releases).
2. Open the DMG and drag NextMeeting to Applications.
3. First launch: right-click the app and choose **Open** (the app is ad-hoc signed, not notarized, so Gatekeeper shows a warning the first time only).
4. Grant calendar access when prompted.

Requires macOS 14 or later.

## Stack

`Swift` `SwiftUI (MenuBarExtra)` `EventKit` `SMAppService` `macOS 14+`

## Build from source

No full Xcode needed, just the Command Line Tools.

```bash
./build.sh            # fast native dev build
./build.sh run        # build and launch
./build.sh universal  # universal arm64 + x86_64 build
./package_dmg.sh      # build a universal app and package the DMG
```

## About

Built by [Sahand Sorouri](https://github.com/sahandsorouri). Personal project, shared as-is.
