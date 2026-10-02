#!/bin/bash
set -euo pipefail

VERSION="${IMAGEFORGE_VERSION:-$(tr -d '[:space:]' < VERSION)}"
BUILD_NUMBER="${IMAGEFORGE_BUILD_NUMBER:-0}"

swift build -c release

APP="dist/ImageForge.app"
ZIP="dist/ImageForge-macOS-arm64.zip"
ICON_SOURCE="assets/AppIcon.png"
ICON_MASTER="dist/AppIcon-1024.png"
ICONSET="dist/AppIcon.iconset"

rm -rf "$APP" "$ZIP" "$ICONSET" "$ICON_MASTER"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp ".build/release/ImageForge" "$APP/Contents/MacOS/ImageForge"

# Use the checked-in canonical ImageForge artwork for both the app and repo branding.
# Scale once to a 1024px master, then generate the complete macOS iconset.
/usr/bin/sips -z 1024 1024 "$ICON_SOURCE" --out "$ICON_MASTER" >/dev/null
mkdir -p "$ICONSET"

/usr/bin/sips -z 16 16     "$ICON_MASTER" --out "$ICONSET/icon_16x16.png" >/dev/null
/usr/bin/sips -z 32 32     "$ICON_MASTER" --out "$ICONSET/icon_16x16@2x.png" >/dev/null
/usr/bin/sips -z 32 32     "$ICON_MASTER" --out "$ICONSET/icon_32x32.png" >/dev/null
/usr/bin/sips -z 64 64     "$ICON_MASTER" --out "$ICONSET/icon_32x32@2x.png" >/dev/null
/usr/bin/sips -z 128 128   "$ICON_MASTER" --out "$ICONSET/icon_128x128.png" >/dev/null
/usr/bin/sips -z 256 256   "$ICON_MASTER" --out "$ICONSET/icon_128x128@2x.png" >/dev/null
/usr/bin/sips -z 256 256   "$ICON_MASTER" --out "$ICONSET/icon_256x256.png" >/dev/null
/usr/bin/sips -z 512 512   "$ICON_MASTER" --out "$ICONSET/icon_256x256@2x.png" >/dev/null
/usr/bin/sips -z 512 512   "$ICON_MASTER" --out "$ICONSET/icon_512x512.png" >/dev/null
cp "$ICON_MASTER" "$ICONSET/icon_512x512@2x.png"

/usr/bin/iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key>
  <string>ImageForge</string>
  <key>CFBundleDisplayName</key>
  <string>ImageForge</string>
  <key>CFBundleIdentifier</key>
  <string>com.thedeichlers.imageforge</string>
  <key>CFBundleVersion</key>
  <string>$BUILD_NUMBER</string>
  <key>CFBundleShortVersionString</key>
  <string>$VERSION</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleExecutable</key>
  <string>ImageForge</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>LSMinimumSystemVersion</key>
  <string>15.0</string>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
PLIST

/usr/bin/plutil -lint "$APP/Contents/Info.plist"
/usr/bin/codesign --force --deep --sign - "$APP"
/usr/bin/codesign --verify --deep --strict "$APP"
/usr/bin/ditto -c -k --keepParent "$APP" "$ZIP"

echo "Packaged $ZIP (version $VERSION, build $BUILD_NUMBER)"
