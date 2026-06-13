# TimeAhead Mac Development Handoff

This handoff is written so another developer (or LLM) can resume TimeAhead
development without reading the originating chat. Treat this repository as the
source of truth.

## Repository

- Git remote: `https://github.com/masatomoota/TimeAhead_Mac.git`
- App name: `TimeAhead`
- Bundle identifier: `com.masatomoota.timeahead`
- Minimum macOS version in bundle metadata: `13.0`
- App version in build script: `1.0.0`

## Product Goal

TimeAhead is a small macOS menu bar utility. It displays the current time shifted
by a user-controlled minute offset without changing the system clock.

The intended user-facing behavior is:

- run as an `NSStatusBar` / `LSUIElement` menu bar app;
- show `Date() + offsetMinutes * 60` in the menu bar;
- update the visible time every second;
- persist the chosen offset in `UserDefaults` under `offsetMinutes`;
- provide preset offsets and custom offset entry from the menu;
- optionally prompt for an offset when launched as a `.app` bundle.

## Important Files

- `OffsetClock.swift`
  - Single Swift source file for the menu bar app.
  - Uses AppKit and Foundation directly.
  - No SwiftPM package or Xcode project is currently present.
- `scripts/build_app.sh`
  - Builds `build/TimeAhead.app` from `OffsetClock.swift`.
  - Produces a universal (`arm64` + `x86_64`) binary by default; override with
    `ARCHS` (e.g. `ARCHS="arm64"`).
  - Copies `assets/TimeAhead.icns` into `Contents/Resources/TimeAhead.icns`
    when the icon file exists.
  - Writes `Contents/Info.plist` including `CFBundleIconFile=TimeAhead`.
  - Performs ad-hoc code signing by default through `codesign --sign -`.
  - Optional environment variables: `APP_NAME`, `BUNDLE_ID`, `VERSION`,
    `ICON_FILE`, `SIGN_IDENTITY`, `ARCHS`, `DEPLOYMENT_TARGET`.
- `scripts/build_dmg.sh`
  - Builds `build/TimeAhead.dmg` after ensuring `build/TimeAhead.app` exists.
- `assets/TimeAheadIcon.png`
  - Pop-style source image for the application icon.
- `assets/TimeAhead.icns`
  - macOS icon built from `assets/TimeAheadIcon.png`, consumed by
    `scripts/build_app.sh`.
- `build/TimeAhead.app`
  - Generated app bundle. `build/` is ignored by Git; rebuild from source.
- `docs/TimeAhead_User_Manual.tex` / `docs/TimeAhead_User_Manual.pdf`
  - Human-facing graphical LaTeX manual and its built PDF.

The login-startup LaunchAgent is installed per user at
`$HOME/Library/LaunchAgents/com.masatomoota.timeahead.plist`. It runs the
installed `/Applications/TimeAhead.app` with `--no-prompt-on-launch`
(`RunAtLoad=true`, `KeepAlive=false`, `LimitLoadToSessionType=Aqua`).

## Current Code Behavior

`OffsetClock.swift` defines `OffsetClockApp: NSObject, NSApplicationDelegate`.
The main runtime path is:

1. `NSApplication.shared` is configured as an accessory app.
2. `readDefaultOffsetMinutes(from:)` reads `--offset-minutes`; default is `10`.
3. `readPromptOnLaunch(from:)` reads prompt flags:
   - `--prompt-on-launch` forces the offset prompt.
   - `--no-prompt-on-launch` disables it.
   - if neither flag is set, launching as an app bundle (`CFBundlePackageType`
     equals `APPL`) prompts by default.
4. `OffsetClockApp.applicationDidFinishLaunching` creates the status item,
   builds the menu, updates the clock, and starts a one-second timer.
5. Left click opens the menu after the double-click interval.
6. Right click or left double click opens the custom offset prompt directly.
7. Reopening the app while it is already running opens the custom offset prompt.

Offset rules:

- Stored key: `UserDefaults.standard["offsetMinutes"]`
- Allowed range: `-1440...1440`
- Presets: `0`, `5`, `10`, `15`, `30`, `60`
- Default offset: `+10` unless overridden by `--offset-minutes`

## Build Commands

From repository root:

```bash
./scripts/build_app.sh           # universal build -> build/TimeAhead.app
ARCHS="arm64" ./scripts/build_app.sh   # thin build for a single arch
./scripts/build_dmg.sh           # build/TimeAhead.dmg
```

To use a Developer ID identity instead of ad-hoc signing:

```bash
SIGN_IDENTITY="Developer ID Application: YOUR_NAME (TEAM_ID)" ./scripts/build_app.sh
```

## Verification Commands

Run these from repository root after changing app code, build scripts, icons, or
manual artifacts.

```bash
./scripts/build_app.sh
plutil -p build/TimeAhead.app/Contents/Info.plist
codesign --verify --deep --strict --verbose=2 build/TimeAhead.app
lipo -archs build/TimeAhead.app/Contents/MacOS/TimeAhead   # expect: x86_64 arm64
file build/TimeAhead.app/Contents/MacOS/TimeAhead assets/TimeAhead.icns
shasum -a 256 assets/TimeAhead.icns build/TimeAhead.app/Contents/Resources/TimeAhead.icns
```

Launch verification (start, confirm alive, stop):

```bash
if pgrep -x TimeAhead >/dev/null 2>&1; then
  echo "preexisting TimeAhead process detected; stop it or skip launch verification"
  exit 2
fi
open -n "$PWD/build/TimeAhead.app" --args --no-prompt-on-launch
pid=""
for _ in {1..30}; do
  pid="$(pgrep -x TimeAhead || true)"
  [[ -n "$pid" ]] && break
  sleep 0.2
done
test -n "$pid"
sleep 1
ps -p "$pid" -o pid=,comm=
pkill -x TimeAhead
```

## LaTeX Manual Build

```bash
tectonic docs/TimeAhead_User_Manual.tex   # -> docs/TimeAhead_User_Manual.pdf
```

The manual is A4, 3 pages, and contains the Japanese sections including
`TimeAhead`, `カスタム入力`, and `開発者・配布担当者向け確認`.

## Known Constraints

- The app does not change or hide the system clock. It adds a separate offset
  clock in the menu bar.
- Earlier testing on macOS 26.2 showed that the standard right-side clock may
  reappear after attempts to hide it via `defaults` and `ControlCenter` restart.
- `build/` is ignored and should be regenerated locally.
- The app is ad-hoc signed unless `SIGN_IDENTITY` is provided. No notarization
  workflow exists yet.
- There is no SwiftPM package or Xcode project. Build automation uses `swiftc`
  directly.
- Distributed binaries are universal (`arm64` + `x86_64`). Runtime behavior has
  been verified on Apple Silicon; Intel slices are produced via cross-compile.

## Safe Next Actions

1. If adding features, keep `OffsetClock.swift` simple or first split it into
   small AppKit-focused modules with a real SwiftPM or Xcode project.
2. If preparing distribution, add Developer ID signing and notarization instead
   of relying on the default ad-hoc signature.
3. If changing the icon, regenerate `assets/TimeAhead.icns`, rebuild the app,
   and compare the source and bundled icon hashes.
4. If changing user-visible behavior, update both this handoff and
   `docs/TimeAhead_User_Manual.tex`, then rebuild the PDF.
5. Before GitHub sync, inspect `git status --short` and stage only scoped files.
