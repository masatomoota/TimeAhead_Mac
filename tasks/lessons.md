# Lessons

- 2026-05-25: Do not trust prior `tasks/todo.md` or handoff install records as live state. For desktop runtime tasks, verify `/Applications`, `~/Library/LaunchAgents`, and `launchctl` before deciding whether the app is actually installed.
- 2026-05-25: When a desktop app needs local installation and login startup, keep a single repo-owned installer script so the runtime state can be recreated instead of hand-running loosely documented commands.
