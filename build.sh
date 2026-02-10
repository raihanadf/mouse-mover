#!/bin/bash
set -e

echo "🔨 Building Mouse Jiggler..."

# Clean previous build
rm -rf .build/release
rm -rf MouseJiggler.app

# Build release version
echo "📦 Building release binary..."
swift build -c release

# Create app bundle
echo "📁 Creating app bundle..."
mkdir -p MouseJiggler.app/Contents/MacOS
mkdir -p MouseJiggler.app/Contents/Resources

# Copy binary
cp .build/release/MouseJiggler MouseJiggler.app/Contents/MacOS/

# Copy icon if exists
if [ -f "Assets/icon.icns" ]; then
    cp Assets/icon.icns MouseJiggler.app/Contents/Resources/
fi

# Create Info.plist
cat > MouseJiggler.app/Contents/Info.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>MouseJiggler</string>
    <key>CFBundleIdentifier</key>
    <string>com.raihan.MouseJiggler</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Mouse Jiggler</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSUserNotificationAlertStyle</key>
    <string>alert</string>
    <key>LSUIElement</key>
    <false/>
</dict>
</plist>
EOF

# Sign the app (ad-hoc signing for local use)
echo "🔏 Signing app..."
codesign --force --deep --sign - MouseJiggler.app

echo "✅ Build complete!"
echo ""
echo "App location: $(pwd)/MouseJiggler.app"
echo ""
echo "To install:"
echo "  cp -r MouseJiggler.app /Applications/"
echo ""
echo "To run:"
echo "  open MouseJiggler.app"
