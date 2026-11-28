#!/bin/sh
set -eu
cd "$(dirname "$0")"
app=".build/Bend 2 Life.app"
mkdir -p "$app/Contents/MacOS" .build/modules
"${BEND:-bend}" native.bend -o .build/window.c
xcrun clang -x objective-c -fobjc-arc -fmodules -fmodules-cache-path=.build/modules \
  -std=c11 -O3 .build/window.c -lpthread -lm -framework AppKit \
  -framework QuartzCore -framework CoreVideo -framework Metal \
  -o "$app/Contents/MacOS/Bend2Life"
cat >"$app/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleIdentifier</key><string>dev.dicenull.bend2-life</string>
  <key>CFBundleName</key><string>Bend 2 Life</string>
  <key>CFBundleExecutable</key><string>Bend2Life</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
printf '%s\n' "$app"
