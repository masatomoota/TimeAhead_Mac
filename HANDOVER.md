# TimeAhead Mac Development Handoff

Last updated: 2026-05-24

This handoff is written so another LLM can resume TimeAhead development without
reading the originating chat. Treat this repository as the source of truth.

## Repository

- Local path: `/Volumes/work-ssd-4TB-USB4/_Git_Repository/TimeAhead_Mac`
- Git remote: `https://github.com/masatomoota/TimeAhead_Mac.git`
- Current branch during this handoff: `main`
- App name: `TimeAhead`
- Bundle identifier: `com.masatomoota.timeahead`
- Minimum macOS version in bundle metadata: `13.0`
- Current app version in build script: `1.0.0`

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
  - Copies `assets/TimeAhead.icns` into `Contents/Resources/TimeAhead.icns`
    when the icon file exists.
  - Writes `Contents/Info.plist` including `CFBundleIconFile=TimeAhead`.
  - Performs ad-hoc code signing by default through `codesign --sign -`.
  - Optional environment variables:
    - `APP_NAME`
    - `BUNDLE_ID`
    - `VERSION`
    - `ICON_FILE`
    - `SIGN_IDENTITY`
- `scripts/build_dmg.sh`
  - Builds `build/TimeAhead.dmg` after ensuring `build/TimeAhead.app` exists.
- `assets/TimeAheadIcon.png`
  - Generated pop-style source image for the application icon.
  - The icon communicates a forward-shifted clock using a clock face, arrow,
    menu-bar cue, and plus badge.
- `assets/TimeAhead.icns`
  - macOS icon built from `assets/TimeAheadIcon.png`.
  - This is the icon file consumed by `scripts/build_app.sh`.
- `build/TimeAhead.app`
  - Generated app bundle. `build/` is ignored by Git.
  - Rebuild it from source instead of treating it as durable source.
- `docs/TimeAhead_User_Manual.tex`
  - Human-facing graphical LaTeX manual.
- `docs/TimeAhead_User_Manual.pdf`
  - Built PDF manual.
- `tasks/todo.md`
  - Append-only task plan and verification notes for recent work.
- `tasks/lessons.md`
  - Not present as of this handoff. Create/update it only when a user correction
    or fix pattern needs to be preserved.

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
./scripts/build_app.sh
```

Expected output:

```text
Built app: /Volumes/work-ssd-4TB-USB4/_Git_Repository/TimeAhead_Mac/build/TimeAhead.app
```

To use a Developer ID identity instead of ad-hoc signing:

```bash
SIGN_IDENTITY="Developer ID Application: YOUR_NAME (TEAM_ID)" ./scripts/build_app.sh
```

To build the DMG:

```bash
./scripts/build_dmg.sh
```

## Verification Commands

Run these from repository root after changing app code, build scripts, icons, or
manual artifacts.

```bash
./scripts/build_app.sh
plutil -p build/TimeAhead.app/Contents/Info.plist
codesign --verify --deep --strict --verbose=2 build/TimeAhead.app
file build/TimeAhead.app/Contents/MacOS/TimeAhead assets/TimeAhead.icns
shasum -a 256 assets/TimeAheadIcon.png assets/TimeAhead.icns build/TimeAhead.app/Contents/Resources/TimeAhead.icns
```

Launch verification used in this session:

```bash
if pgrep -x TimeAhead >/dev/null 2>&1; then
  echo "preexisting TimeAhead process detected; stop it or skip destructive launch verification"
  exit 2
fi
open -n "$PWD/build/TimeAhead.app" --args --no-prompt-on-launch
pid=""
for _ in {1..30}; do
  pid="$(pgrep -x TimeAhead || true)"
  if [[ -n "$pid" ]]; then
    break
  fi
  sleep 0.2
done
test -n "$pid"
sleep 1
ps -p "$pid" -o pid=,comm=
pkill -x TimeAhead
```

Verified evidence from 2026-05-24:

- `plutil` showed `CFBundleIconFile => TimeAhead`, `LSUIElement => true`, and
  `CFBundleIdentifier => com.masatomoota.timeahead`.
- `codesign --verify --deep --strict --verbose=2 build/TimeAhead.app` succeeded.
- `codesign -dv --verbose=4 build/TimeAhead.app` reported an ad-hoc signature,
  thin `arm64` Mach-O app bundle, and CDHash
  `9ee9ba6bcba93c29d239f5b746bf7df812a53467`.
- `file build/TimeAhead.app/Contents/MacOS/TimeAhead` reported
  `Mach-O 64-bit executable arm64`.
- Icon hashes matched between source `assets/TimeAhead.icns` and the copied
  bundle resource:
  - `assets/TimeAheadIcon.png`:
    `56b96a654db02ff6ac3ae6797bd14aced10cda9440cbd7358e98c6a47b8a7a81`
  - `assets/TimeAhead.icns`:
    `18fac26cee4d0eb55e7277a44a134dbab4c203c8ae0edf72025c0197221f95df`
  - `build/TimeAhead.app/Contents/Resources/TimeAhead.icns`:
    `18fac26cee4d0eb55e7277a44a134dbab4c203c8ae0edf72025c0197221f95df`
- Launch verification started a `TimeAhead` process and stopped it after proving
  it stayed alive.

## LaTeX Manual Build

The manual source is expected at:

```text
docs/TimeAhead_User_Manual.tex
```

Build it with the bundled LaTeX compile helper:

```bash
python3 /Users/masatomo/.codex/plugins/cache/openai-bundled/latex/0.2.0/scripts/compile_latex.py \
  /Volumes/work-ssd-4TB-USB4/_Git_Repository/TimeAhead_Mac/docs/TimeAhead_User_Manual.tex \
  --compiler tectonic
```

Expected generated PDF:

```text
docs/TimeAhead_User_Manual.pdf
```

Verified PDF evidence from 2026-05-24:

- `pdfinfo docs/TimeAhead_User_Manual.pdf` reported A4, 3 pages, PDF 1.5,
  title `TimeAhead User Manual`, and file size `1726854` bytes.
- `pdftotext docs/TimeAhead_User_Manual.pdf -` found the expected Japanese
  sections including `TimeAhead`, `カスタム入力`, `開発者・配布担当者向け確認`,
  and `build/TimeAhead.app`.
- Rendered page previews were inspected from `pdftoppm -png -f 1 -l 3 -r 120`.
- PDF SHA-256:
  `b312f7f6f5661e66acdbca986625bc435feaac3ad7035dd108ce8b98ae2e85ca`

## Known Constraints

- The app does not change or hide the system clock. It adds a separate offset
  clock in the menu bar.
- Earlier testing on macOS 26.2 showed that the standard right-side clock may
  reappear after attempts to hide it via `defaults` and `ControlCenter` restart.
- `build/` is ignored and should be regenerated locally.
- The app is ad-hoc signed unless `SIGN_IDENTITY` is provided.
- No notarization workflow exists yet.
- There is no SwiftPM package or Xcode project. Build automation uses `swiftc`
  directly.
- The app is currently verified on Apple Silicon / `arm64`.

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

## Current Completion Target

The 2026-05-24 target is complete when all of the following are true:

- `build/TimeAhead.app` exists and has the generated icon.
- `HANDOVER.md` contains current repo state, commands, verification evidence,
  caveats, and next actions.
- `docs/TimeAhead_User_Manual.pdf` is built from LaTeX.
- The scoped changes are committed and pushed to GitHub.
