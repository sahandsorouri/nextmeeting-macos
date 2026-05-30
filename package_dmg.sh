#!/bin/bash
# Package NextMeeting.app into a drag-to-Applications .dmg.
#
# Usage:
#   ./package_dmg.sh
#
# Builds a fresh UNIVERSAL app first, then lays out a DMG with the app and a
# symlink to /Applications so users can drag to install.
#
# Distribution note: we have NO Apple Developer account, so the app is only
# ad-hoc signed and the DMG is NOT notarized. On first launch users must
# right-click the app -> Open (Gatekeeper warning is expected, not a bug).
set -euo pipefail

cd "$(dirname "$0")"

APP_NAME="NextMeeting"
BUILD_DIR="build"
APP_DIR="$BUILD_DIR/$APP_NAME.app"

# Version pulled from the bundle's Info.plist so the DMG name stays in sync.
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' \
    Resources/Info.plist 2>/dev/null || echo '0.0.0')"

STAGE="$BUILD_DIR/dmg-stage"
DMG_PATH="$BUILD_DIR/$APP_NAME-$VERSION.dmg"
VOL_NAME="$APP_NAME $VERSION"

echo "==> Building universal app for packaging"
./build.sh universal >/dev/null
echo "    app ready ($(lipo -archs "$APP_DIR/Contents/MacOS/$APP_NAME"))"

echo "==> Staging DMG contents"
rm -rf "$STAGE" "$DMG_PATH"
mkdir -p "$STAGE"
# Copy the app (ditto preserves the bundle + signature correctly).
ditto "$APP_DIR" "$STAGE/$APP_NAME.app"
# Drag-to-install target.
ln -s /Applications "$STAGE/Applications"

echo "==> Creating compressed DMG: $DMG_PATH"
hdiutil create \
    -volname "$VOL_NAME" \
    -srcfolder "$STAGE" \
    -ov \
    -format UDZO \
    "$DMG_PATH" >/dev/null

rm -rf "$STAGE"

echo "==> Done: $DMG_PATH"
echo "    $(du -h "$DMG_PATH" | cut -f1) — universal, ad-hoc signed (not notarized)."
echo "    First launch on another Mac: right-click the app -> Open."
