#!/bin/bash
set -euo pipefail

VERSION="${IMAGEFORGE_VERSION:-$(tr -d '[:space:]' < VERSION)}"
BUILD_NUMBER="${IMAGEFORGE_BUILD_NUMBER:-0}"

swift build -c release

APP="dist/ImageForge.app"
ZIP="dist/ImageForge-macOS-arm64.zip"

rm -rf "$APP" "$ZIP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp ".build/release/ImageForge" "$APP/Contents/MacOS/ImageForge"

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
