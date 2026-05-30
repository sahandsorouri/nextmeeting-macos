#!/bin/bash
# Build NextMeeting.app from the command line (no Xcode required).
#
# Usage:
#   ./build.sh              Build for THIS Mac's arch (fast — daily dev).
#   ./build.sh run          Build (native arch) and launch.
#   ./build.sh universal    Build a universal (arm64 + x86_64) binary.
#   ./build.sh universal run Universal build, then launch.
set -euo pipefail

cd "$(dirname "$0")"

APP_NAME="NextMeeting"
BUNDLE_ID="com.sahand.nextmeeting"
DEPLOY_TARGET="14.0"

BUILD_DIR="build"
APP_DIR="$BUILD_DIR/$APP_NAME.app"
MACOS_DIR="$APP_DIR/Contents/MacOS"
RES_DIR="$APP_DIR/Contents/Resources"
MODULE_CACHE_DIR="$BUILD_DIR/module-cache"

SDK_PATH="$(xcrun --sdk macosx --show-sdk-path)"
ARCH="$(uname -m)" # arm64 or x86_64

# Parse args (order-independent): "universal" picks the universal build;
# "run" launches afterwards.
UNIVERSAL=0
RUN=0
for arg in "$@"; do
    case "$arg" in
        universal) UNIVERSAL=1 ;;
        run)       RUN=1 ;;
    esac
done

echo "==> Cleaning"
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RES_DIR" "$MODULE_CACHE_DIR"

compile_arch() {
    # $1 = arch (arm64|x86_64), $2 = output binary path
    swiftc \
        -sdk "$SDK_PATH" \
        -target "$1-apple-macos$DEPLOY_TARGET" \
        -framework SwiftUI -framework AppKit \
        -framework ServiceManagement -framework Carbon \
        -module-cache-path "$MODULE_CACHE_DIR" \
        -parse-as-library \
        -O \
        -o "$2" \
        Sources/*.swift
}

if [[ "$UNIVERSAL" == "1" ]]; then
    echo "==> Compiling universal (arm64 + x86_64, macOS $DEPLOY_TARGET)"
    compile_arch arm64  "$BUILD_DIR/$APP_NAME-arm64"
    compile_arch x86_64 "$BUILD_DIR/$APP_NAME-x86_64"
    echo "==> Merging slices with lipo"
    lipo -create \
        "$BUILD_DIR/$APP_NAME-arm64" "$BUILD_DIR/$APP_NAME-x86_64" \
        -output "$MACOS_DIR/$APP_NAME"
    rm -f "$BUILD_DIR/$APP_NAME-arm64" "$BUILD_DIR/$APP_NAME-x86_64"
    echo "    -> $(lipo -archs "$MACOS_DIR/$APP_NAME")"
else
    echo "==> Compiling Swift ($ARCH, macOS $DEPLOY_TARGET)"
    compile_arch "$ARCH" "$MACOS_DIR/$APP_NAME"
fi

echo "==> Copying Info.plist"
cp Resources/Info.plist "$APP_DIR/Contents/Info.plist"
cp Resources/NextMeeting.icns "$RES_DIR/"
cp Resources/MenuBarIcon.png "$RES_DIR/"

strip_and_sign() {
    # iCloud re-adds com.apple.FinderInfo, which codesign rejects. Strip it from
    # every path in the bundle, then sign immediately.
    find "$APP_DIR" -print0 | xargs -0 /usr/bin/xattr -d com.apple.FinderInfo 2>/dev/null || true
    codesign --force --sign - "$APP_DIR" 2>&1
}

echo "==> Stripping Finder metadata (this dir is iCloud-synced) + signing"
if ! strip_and_sign; then
    echo "   retrying sign..."
    sleep 1
    strip_and_sign
fi

echo "==> Built: $APP_DIR"

if [[ "$RUN" == "1" ]]; then
    echo "==> Launching"
    # Kill any previous instance, then launch fresh.
    pkill -x "$APP_NAME" 2>/dev/null || true
    open "$APP_DIR"
fi
