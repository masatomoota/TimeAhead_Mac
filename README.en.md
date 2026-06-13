# TimeAhead

[日本語](README.md) | **English**

A small menu bar app for macOS that shows a clock reading "current time + N minutes" — without changing your system clock.

![TimeAhead shown in the menu bar](assets/screenshot-menubar.png)

## Overview
- Runs as an `NSStatusBar` menu bar (agent) app
- Displayed time is `Date() + offsetMinutes * 60`
- The offset (in minutes) is adjustable from the menu UI
- Launches automatically at login (via a LaunchAgent)

## Requirements
- OS: macOS 13.0 or later
- CPU: Apple Silicon (`arm64`) and Intel (`x86_64`) — both supported
- The distributed binaries (the `*.zip` files on [Releases](https://github.com/masatomoota/TimeAhead_Mac/releases)) are **universal binaries** (`arm64` + `x86_64`)
- To build from source: Xcode Command Line Tools (`swiftc` must be available)
- As a menu bar agent app, it expects to run in a GUI session (Aqua)

## Project layout
- Source: `OffsetClock.swift`
- Legacy standalone binary: `offset-clock`
- `.app` build script: `scripts/build_app.sh`
- `.dmg` build script: `scripts/build_dmg.sh`
- App icon source image: `assets/TimeAheadIcon.png`
- macOS icon: `assets/TimeAhead.icns`
- Human-facing manual: `docs/TimeAhead_User_Manual.pdf`
- Developer handover notes: `HANDOVER.md`

## Usage
Click TimeAhead in the menu bar to change the offset.
- When you launch via `Applications/TimeAhead.app`, the offset input popup appears right after launch
- Opening `Applications/TimeAhead.app` again while it is already running also shows the offset input popup
- Left click: open the menu
- Right click: open the offset input popup directly
- Left double click: open the offset input popup directly

### Presets
- `0 min (real time)`
- `+5 min`
- `+10 min`
- `+15 min`
- `+30 min`
- `+60 min`

### Custom input
- Enter any number of minutes via `Custom...`
- Allowed range: `-1440` to `1440`

### Reset to default
- `Use Default (+10 min)`

## Build
```bash
# Quick build for the current architecture
swiftc "OffsetClock.swift" -o "offset-clock"
```

To build a universal binary (`arm64` + `x86_64`) manually:
```bash
swiftc OffsetClock.swift -target arm64-apple-macosx13.0  -o offset-clock-arm64
swiftc OffsetClock.swift -target x86_64-apple-macosx13.0 -o offset-clock-x86_64
lipo -create offset-clock-arm64 offset-clock-x86_64 -output offset-clock
```

## Build as a `.app`
```bash
./scripts/build_app.sh
```

- Output: `build/TimeAhead.app` (a **universal binary** `arm64` + `x86_64` by default)
- Icon: if `assets/TimeAhead.icns` exists, it is embedded as `Contents/Resources/TimeAhead.icns`.
- To build for a specific architecture only, set `ARCHS`:
```bash
ARCHS="arm64" ./scripts/build_app.sh
```
- To sign with a specific identity:
```bash
SIGN_IDENTITY="Developer ID Application: YOUR_NAME (TEAM_ID)" ./scripts/build_app.sh
```

## Build a `.dmg` for distribution
```bash
./scripts/build_dmg.sh
```

- Output: `build/TimeAhead.dmg`
- The DMG contains `TimeAhead.app` and a shortcut to `Applications`.

## Manual
A graphical, human-facing manual is available here:

- PDF: `docs/TimeAhead_User_Manual.pdf`
- LaTeX source: `docs/TimeAhead_User_Manual.tex`

To regenerate the PDF (using [Tectonic](https://tectonic-typesetting.github.io/)):
```bash
tectonic docs/TimeAhead_User_Manual.tex
```

## Download (prebuilt binaries)
Prebuilt universal binaries (`arm64` + `x86_64`) are available on the [Releases](https://github.com/masatomoota/TimeAhead_Mac/releases) page. They run on both Apple Silicon and Intel Macs.

- `TimeAhead-app-universal.zip` … the menu bar agent app (`TimeAhead.app`)
- `offset-clock-universal.zip` … the legacy standalone CLI binary

> **Note:** The distributed binaries are **not** signed with an Apple Developer ID or notarized (ad-hoc signed), so macOS will show a Gatekeeper warning on first launch. See "Bypassing the Gatekeeper warning" below.

## Installing on another Mac
1. Download `TimeAhead-app-universal.zip` from [Releases](https://github.com/masatomoota/TimeAhead_Mac/releases) and unzip it
2. Drag `TimeAhead.app` into `Applications`
3. Launch `Applications/TimeAhead.app`

### Bypassing the Gatekeeper warning
Because the app is unsigned, double-clicking it shows "cannot be opened because the developer cannot be verified." Allow it using one of the following.

**Option A: Open via right click (recommended, first time only)**
1. **Right click (Control+click) `Applications/TimeAhead.app` → "Open"**
2. Choose "Open" again in the confirmation dialog

**Option B: Allow from System Settings**
1. Double-click once and dismiss the warning
2. Open "System Settings → Privacy & Security"
3. Near the bottom, next to "\"TimeAhead\" was blocked because it is not from an identified developer…", click **"Open Anyway"**

**Option C: Remove the quarantine attribute from the terminal**
```bash
xattr -dr com.apple.quarantine /Applications/TimeAhead.app
```

## Start / restart
```bash
uid=$(id -u)
launchctl bootout gui/$uid/com.masatomoota.timeahead 2>/dev/null || true
launchctl bootstrap gui/$uid "$HOME/Library/LaunchAgents/com.masatomoota.timeahead.plist"
launchctl kickstart -kp gui/$uid/com.masatomoota.timeahead
```

## Check status
```bash
uid=$(id -u)
launchctl print gui/$uid/com.masatomoota.timeahead | rg "state =|pid =|program =|arguments ="
pgrep -fl "TimeAhead.app/Contents/MacOS/TimeAhead"
```

## Stop
```bash
uid=$(id -u)
launchctl bootout gui/$uid/com.masatomoota.timeahead
```

## Known limitations
- On macOS 26.2, hiding the standard top-right clock (the `ControlCenter` side) via `defaults` has been observed to revert and reappear.
- For that reason, TimeAhead currently operates as an **additional** offset clock display rather than a full replacement of the standard clock.

## Uninstall
```bash
uid=$(id -u)
launchctl bootout gui/$uid/com.masatomoota.timeahead 2>/dev/null || true
rm -f "$HOME/Library/LaunchAgents/com.masatomoota.timeahead.plist"
rm -rf "/Applications/TimeAhead.app"
rm -f "offset-clock"
```
