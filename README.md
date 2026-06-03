# NextMeeting

> A macOS menu bar app that shows your next calendar meeting with a live countdown and one-click join.

A personal macOS app I built for myself. It lives in the menu bar, reads the native Calendar through EventKit, and shows a compact countdown to your next meeting. It can launch at login. It runs locally on my Mac as a menu-bar-only agent, no Dock icon.

## Stack

`Swift` `SwiftUI (MenuBarExtra)` `EventKit` `SMAppService` `macOS 14+`

## Build

Built with the Swift command-line tools, no full Xcode needed:

```bash
./build.sh
```

Package a `.dmg` with `./package_dmg.sh`.

## About

Built by [Sahand Sorouri](https://github.com/sahandsorouri).
