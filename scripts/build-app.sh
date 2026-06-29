#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$ROOT_DIR/.build/LocalHostMonitor.app"
EXECUTABLE="$ROOT_DIR/.build/release/LocalHostMonitor"
ICON_SVG="$ROOT_DIR/Resources/AppIcon.svg"
ICONSET_DIR="$ROOT_DIR/.build/LocalHostMonitor.iconset"
ICON_FILE="$APP_DIR/Contents/Resources/AppIcon.icns"

render_icon_png() {
    local size="$1"
    local output="$2"

    if command -v rsvg-convert >/dev/null 2>&1; then
        rsvg-convert -w "$size" -h "$size" "$ICON_SVG" -o "$output"
    elif command -v magick >/dev/null 2>&1; then
        magick -background none "$ICON_SVG" -resize "${size}x${size}" "$output"
    else
        echo "Install librsvg or ImageMagick to render AppIcon.icns" >&2
        return 1
    fi
}

build_app_icon() {
    rm -rf "$ICONSET_DIR"
    mkdir -p "$ICONSET_DIR"

    render_icon_png 16 "$ICONSET_DIR/icon_16x16.png"
    render_icon_png 32 "$ICONSET_DIR/icon_16x16@2x.png"
    render_icon_png 32 "$ICONSET_DIR/icon_32x32.png"
    render_icon_png 64 "$ICONSET_DIR/icon_32x32@2x.png"
    render_icon_png 128 "$ICONSET_DIR/icon_128x128.png"
    render_icon_png 256 "$ICONSET_DIR/icon_128x128@2x.png"
    render_icon_png 256 "$ICONSET_DIR/icon_256x256.png"
    render_icon_png 512 "$ICONSET_DIR/icon_256x256@2x.png"
    render_icon_png 512 "$ICONSET_DIR/icon_512x512.png"
    render_icon_png 1024 "$ICONSET_DIR/icon_512x512@2x.png"

    iconutil -c icns "$ICONSET_DIR" -o "$ICON_FILE"
}

cd "$ROOT_DIR"
swift build -c release

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp "$EXECUTABLE" "$APP_DIR/Contents/MacOS/LocalHostMonitor"
build_app_icon

cat > "$APP_DIR/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>LocalHostMonitor</string>
    <key>CFBundleIdentifier</key>
    <string>dev.localhost.monitor</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleName</key>
    <string>LocalHost</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>0.1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.developer-tools</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

if command -v codesign >/dev/null 2>&1; then
    codesign --force --deep --sign - "$APP_DIR" >/dev/null 2>&1 || true
fi

echo "$APP_DIR"
