# Lessons

- 2026-05-25: Do not trust prior `tasks/todo.md` or handoff install records as live state. For desktop runtime tasks, verify `/Applications`, `~/Library/LaunchAgents`, and `launchctl` before deciding whether the app is actually installed.
- 2026-05-25: When a desktop app needs local installation and login startup, keep a single repo-owned installer script so the runtime state can be recreated instead of hand-running loosely documented commands.
- 2026-06-27: When GitHub safe sync finds `no merge base`, treat it as an unrelated-history integration. Create a backup branch, preserve both histories with an explicit merge, resolve files by intent, and verify before pushing; do not force-push or reset one side away.
- 2026-06-27: For menu bar apps, do not write `NSStatusItem` button properties on every timer tick when the rendered value is unchanged. Cache the displayed value and verify WindowServer/TimeAhead logs before and after installing the fix.
