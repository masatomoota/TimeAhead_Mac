#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

APP_NAME="${APP_NAME:-TimeAhead}"
VOLUME_NAME="${VOLUME_NAME:-TimeAhead}"
BUILD_DIR="$ROOT_DIR/build"
APP_DIR="$BUILD_DIR/$APP_NAME.app"
DMG_STAGING_DIR="$BUILD_DIR/dmg-staging"
DMG_PATH="$BUILD_DIR/$APP_NAME.dmg"

if [[ ! -d "$APP_DIR" ]]; then
  "$SCRIPT_DIR/build_app.sh"
fi

rm -rf "$DMG_STAGING_DIR"
mkdir -p "$DMG_STAGING_DIR"

cp -R "$APP_DIR" "$DMG_STAGING_DIR/"
ln -s /Applications "$DMG_STAGING_DIR/Applications"

hdiutil create \
  -volname "$VOLUME_NAME" \
  -srcfolder "$DMG_STAGING_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

echo "Built dmg: $DMG_PATH"
