#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

APP_NAME="${APP_NAME:-TimeAhead}"
BUNDLE_ID="${BUNDLE_ID:-com.masatomoota.timeahead}"
VERSION="${VERSION:-1.0.0}"
BUILD_DIR="$ROOT_DIR/build"
APP_DIR="$BUILD_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
ICON_FILE="${ICON_FILE:-$ROOT_DIR/assets/TimeAhead.icns}"

SIGN_IDENTITY="${SIGN_IDENTITY:--}"
DEPLOYMENT_TARGET="${DEPLOYMENT_TARGET:-13.0}"

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

# Build a universal (arm64 + x86_64) binary by compiling each slice and
# combining them with lipo. Override ARCHS to build a thin binary, e.g.
# ARCHS="arm64" ./scripts/build_app.sh
ARCHS="${ARCHS:-arm64 x86_64}"
SLICES=()
for arch in $ARCHS; do
  slice="$BUILD_DIR/$APP_NAME-$arch"
  swiftc "$ROOT_DIR/OffsetClock.swift" \
    -target "$arch-apple-macosx$DEPLOYMENT_TARGET" \
    -o "$slice"
  SLICES+=("$slice")
done

if [[ ${#SLICES[@]} -gt 1 ]]; then
  lipo -create "${SLICES[@]}" -output "$MACOS_DIR/$APP_NAME"
else
  cp "${SLICES[0]}" "$MACOS_DIR/$APP_NAME"
fi
rm -f "${SLICES[@]}"
echo "Architectures: $(lipo -archs "$MACOS_DIR/$APP_NAME")"

if [[ -f "$ICON_FILE" ]]; then
  cp "$ICON_FILE" "$RESOURCES_DIR/TimeAhead.icns"
fi

cat > "$CONTENTS_DIR/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleIconFile</key>
    <string>TimeAhead</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleVersion</key>
    <string>$VERSION</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

codesign --force --deep --sign "$SIGN_IDENTITY" "$APP_DIR"

echo "Built app: $APP_DIR"
