#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

APP_NAME="${APP_NAME:-TimeAhead}"
BUNDLE_ID="${BUNDLE_ID:-com.masatomoota.timeahead}"
LAUNCH_AGENT_LABEL="${LAUNCH_AGENT_LABEL:-$BUNDLE_ID}"
BUILD_APP_SCRIPT="$SCRIPT_DIR/build_app.sh"
BUILD_DIR="$ROOT_DIR/build"
SOURCE_APP_DIR="${SOURCE_APP_DIR:-$BUILD_DIR/$APP_NAME.app}"
TARGET_APP_DIR="${TARGET_APP_DIR:-/Applications/$APP_NAME.app}"
LAUNCH_AGENTS_DIR="${LAUNCH_AGENTS_DIR:-$HOME/Library/LaunchAgents}"
LAUNCH_AGENT_PATH="${LAUNCH_AGENT_PATH:-$LAUNCH_AGENTS_DIR/$LAUNCH_AGENT_LABEL.plist}"
APP_EXECUTABLE="$TARGET_APP_DIR/Contents/MacOS/$APP_NAME"

mkdir -p "$LAUNCH_AGENTS_DIR"

"$BUILD_APP_SCRIPT"

rm -rf "$TARGET_APP_DIR"
ditto "$SOURCE_APP_DIR" "$TARGET_APP_DIR"

cat > "$LAUNCH_AGENT_PATH" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$LAUNCH_AGENT_LABEL</string>
    <key>ProgramArguments</key>
    <array>
        <string>$APP_EXECUTABLE</string>
        <string>--no-prompt-on-launch</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <false/>
    <key>LimitLoadToSessionType</key>
    <array>
        <string>Aqua</string>
    </array>
</dict>
</plist>
EOF

uid="$(id -u)"
launchctl bootout "gui/$uid/$LAUNCH_AGENT_LABEL" 2>/dev/null || true
pkill -f "$APP_NAME.app/Contents/MacOS/$APP_NAME" 2>/dev/null || true
launchctl bootstrap "gui/$uid" "$LAUNCH_AGENT_PATH"
launchctl kickstart -kp "gui/$uid/$LAUNCH_AGENT_LABEL"

echo "Installed app: $TARGET_APP_DIR"
echo "LaunchAgent: $LAUNCH_AGENT_PATH"
echo "Service label: $LAUNCH_AGENT_LABEL"
