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
