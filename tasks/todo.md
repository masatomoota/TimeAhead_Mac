# TimeAhead app build and icon generation

## Plan
- [x] Review the current app structure and existing build scripts.
- [x] Generate a clear, pop-style icon that communicates an offset menu-bar clock.
- [x] Convert the icon into a macOS `.icns` asset and wire it into the app bundle build.
- [x] Build `build/TimeAhead.app` from the existing Swift source.
- [x] Verify the bundle metadata, code signature, executable, and launch behavior.

## Review
- Generated `assets/TimeAheadIcon.png` as the source image and `assets/TimeAhead.icns` as the macOS icon.
- Updated `scripts/build_app.sh` to copy `assets/TimeAhead.icns` into `Contents/Resources/TimeAhead.icns` and set `CFBundleIconFile` to `TimeAhead`.
- Built `/Volumes/work-ssd-4TB-USB4/_Git_Repository/TimeAhead_Mac/build/TimeAhead.app`.
- Verified `Info.plist` contains `CFBundleIconFile`, `LSUIElement`, and the expected bundle identifier.
- Verified `codesign --verify --deep --strict --verbose=2 build/TimeAhead.app`.
- Launched `build/TimeAhead.app` with `--no-prompt-on-launch`, confirmed the `TimeAhead` process stayed alive, then stopped the verification process.

# Handoff, PDF manual, and GitHub sync

## Plan
- [x] Update `HANDOVER.md` so another LLM can resume development from repository state, artifact paths, build commands, verification evidence, and remaining caveats.
- [x] Create a graphical human-facing LaTeX manual under `docs/`.
- [x] Compile the LaTeX manual into a PDF.
- [x] Re-run app and document verification.
- [x] Commit the scoped changes and push them to GitHub.

## Review
- Replaced stale absolute paths in `README.md` with relative repository paths and added the manual/icon locations.
- Created `docs/TimeAhead_User_Manual.tex` and built `docs/TimeAhead_User_Manual.pdf` with the bundled Tectonic helper.
- Rendered the 3-page PDF to PNG previews with `pdftoppm` and inspected the pages visually.
- Verified `build/TimeAhead.app` after rebuild with `plutil`, `codesign --verify --deep --strict`, `file`, SHA-256 hash checks, and launch/stop verification.
- PDF verification: `pdfinfo` reports A4, 3 pages, PDF 1.5, and `pdftotext` contains the expected Japanese sections.

# Install to Applications and register startup

## Plan
- [x] Rebuild the current `build/TimeAhead.app` bundle.
- [x] Copy the app bundle to `/Applications/TimeAhead.app`.
- [x] Launch `/Applications/TimeAhead.app` and confirm the `TimeAhead` process is running.
- [x] Register a per-user LaunchAgent for login startup.
- [x] Verify the LaunchAgent is loaded and points to `/Applications/TimeAhead.app`.

## Review
- Rebuilt `build/TimeAhead.app` and copied it to `/Applications/TimeAhead.app`.
- Verified the installed app with `codesign --verify --deep --strict`, `plutil`, and matching icon SHA-256 hashes.
- Launched the app from `/Applications/TimeAhead.app` and confirmed the `TimeAhead` process.
- Created `/Users/masatomo/Library/LaunchAgents/com.masatomoota.timeahead.plist` for per-user login startup.
- Loaded and kickstarted the LaunchAgent; `launchctl print gui/501/com.masatomoota.timeahead` reports `state = running` and PID `22685`.
- Updated `README.md` and `HANDOVER.md` to use the current LaunchAgent label instead of the old `local.offsetclock` label.

# Reinstall on current Mac and restore auto-start

## Plan
- [x] Append the current installation wave and verification scope.
- [x] Add a repeatable installer script that rebuilds the app, installs it into `/Applications`, and registers the LaunchAgent.
- [x] Update the operator-facing install instructions in `README.md`.
- [x] Run the installer on this Mac and prove the app is launched by `launchctl`.
- [x] Record the live verification results and the lesson from the stale prior install record.

## Review
- Added `scripts/install_app.sh` so this repo can rebuild, install to `/Applications/TimeAhead.app`, recreate `~/Library/LaunchAgents/com.masatomoota.timeahead.plist`, and reload the LaunchAgent in one step.
- Ran `./scripts/install_app.sh` on 2026-05-25 and confirmed the installed app bundle exists at `/Applications/TimeAhead.app`.
- Verified `/Applications/TimeAhead.app` with `codesign --verify --deep --strict --verbose=2` and `plutil -p`; bundle metadata still reports `CFBundleIdentifier = com.masatomoota.timeahead`, `CFBundleIconFile = TimeAhead`, and `LSUIElement = true`.
- Verified `~/Library/LaunchAgents/com.masatomoota.timeahead.plist` points at `/Applications/TimeAhead.app/Contents/MacOS/TimeAhead --no-prompt-on-launch`.
- Verified `launchctl print gui/501/com.masatomoota.timeahead` reports `state = running`, `program = /Applications/TimeAhead.app/Contents/MacOS/TimeAhead`, and `pid = 84504`.
- Verified `pgrep -af "/Applications/TimeAhead.app/Contents/MacOS/TimeAhead"` returns the running app process and the installed icon hash matches `assets/TimeAhead.icns`.

# GitHub safe sync after unrelated-history divergence

## Plan
- [x] Fetch `origin` and prove the local/remote ancestry state before changing files.
- [x] Preserve both sides of the unrelated histories: keep GitHub's public release docs/assets and keep local installer/task records.
- [x] Merge `origin/main` into local `main` with explicit conflict resolution instead of force-pushing or rebasing.
- [x] Rebuild and verify `TimeAhead.app`, then inspect Git state and push only after checks pass.
- [ ] Record the final review evidence here after local and remote branches match.
