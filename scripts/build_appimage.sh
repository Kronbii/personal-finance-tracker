#!/bin/bash

# Build AppImage for REE - Personal Finance Tracker
# Prerequisites: flutter, appimagetool

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build/linux/x64/release/bundle"
APPDIR="$PROJECT_DIR/build/AppDir"
APP_NAME="REE"
APP_ID="com.kronbii.ree"
BINARY_NAME="ree"
VERSION="1.0.0"

echo "Building Flutter Linux release..."
cd "$PROJECT_DIR"
flutter build linux --release

echo "Creating AppDir structure..."
rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin"
mkdir -p "$APPDIR/usr/lib"
mkdir -p "$APPDIR/usr/share/applications"
mkdir -p "$APPDIR/usr/share/icons/hicolor/256x256/apps"
mkdir -p "$APPDIR/usr/share/metainfo"

echo "Copying bundle..."
cp -r "$BUILD_DIR"/* "$APPDIR/usr/bin/"

# Copy libraries to lib folder
if [ -d "$BUILD_DIR/lib" ]; then
    cp -r "$BUILD_DIR/lib"/* "$APPDIR/usr/lib/" 2>/dev/null || true
fi

echo "Creating desktop entry..."
cat > "$APPDIR/$APP_ID.desktop" << EOF
[Desktop Entry]
Name=$APP_NAME
Comment=REE - Personal Finance Tracker
Exec=$BINARY_NAME
Icon=$APP_ID
Terminal=false
Type=Application
Categories=Office;Finance;
StartupWMClass=$BINARY_NAME
EOF

# Also copy to standard location
cp "$APPDIR/$APP_ID.desktop" "$APPDIR/usr/share/applications/"

echo "Creating AppRun script..."
cat > "$APPDIR/AppRun" << 'APPRUNEOF'
#!/bin/bash
SELF=$(readlink -f "$0")
HERE=${SELF%/*}
export PATH="${HERE}/usr/bin/:${PATH}"
export LD_LIBRARY_PATH="${HERE}/usr/bin/lib:${HERE}/usr/lib:${LD_LIBRARY_PATH}"
cd "${HERE}/usr/bin"
exec "${HERE}/usr/bin/ree" "$@"
APPRUNEOF
chmod +x "$APPDIR/AppRun"

echo "Copying app icon..."
# Use the existing icon if available
if [ -f "$PROJECT_DIR/linux/icons/ree.png" ]; then
    cp "$PROJECT_DIR/linux/icons/ree.png" "$APPDIR/$APP_ID.png"
    cp "$PROJECT_DIR/linux/icons/ree.png" "$APPDIR/usr/share/icons/hicolor/256x256/apps/$APP_ID.png"
    cp "$PROJECT_DIR/linux/icons/ree.png" "$APPDIR/.DirIcon"
else
    echo "Warning: Icon not found at linux/icons/ree.png, creating placeholder..."
    touch "$APPDIR/$APP_ID.png"
fi

echo "Creating AppStream metadata..."
cat > "$APPDIR/usr/share/metainfo/$APP_ID.appdata.xml" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<component type="desktop-application">
  <id>$APP_ID</id>
  <name>$APP_NAME</name>
  <summary>REE - Personal Finance Tracker</summary>
  <metadata_license>MIT</metadata_license>
  <project_license>MIT</project_license>
  <description>
    <p>
      A beautiful, desktop-first personal finance application with Apple-inspired design.
      Track your income, expenses, subscriptions, debts, and savings goals with ease.
    </p>
  </description>
  <launchable type="desktop-id">$APP_ID.desktop</launchable>
  <url type="homepage">https://github.com/kronbii/personal-finance-tracker</url>
  <provides>
    <binary>$BINARY_NAME</binary>
  </provides>
  <releases>
    <release version="$VERSION" date="$(date +%Y-%m-%d)"/>
  </releases>
</component>
EOF

echo "Building AppImage..."
APPIMAGETOOL=""

# Check for appimagetool in common locations
if command -v appimagetool &> /dev/null; then
    APPIMAGETOOL="appimagetool"
elif [ -x "/tmp/appimagetool" ]; then
    APPIMAGETOOL="/tmp/appimagetool"
else
    echo "appimagetool not found. Downloading..."
    wget -q --show-progress -O /tmp/appimagetool "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
    chmod +x /tmp/appimagetool
    APPIMAGETOOL="/tmp/appimagetool"
fi

# Run appimagetool (may need --appimage-extract-and-run on some systems)
ARCH=x86_64 "$APPIMAGETOOL" --appimage-extract-and-run "$APPDIR" "$PROJECT_DIR/build/REE-$VERSION-x86_64.AppImage" || \
ARCH=x86_64 "$APPIMAGETOOL" "$APPDIR" "$PROJECT_DIR/build/REE-$VERSION-x86_64.AppImage"

echo ""
echo "========================================"
echo "AppImage built successfully!"
echo "Location: $PROJECT_DIR/build/REE-$VERSION-x86_64.AppImage"
echo "========================================"

# Auto-install to ~/.local/bin
echo "Installing to ~/.local/bin/ree.AppImage..."
mkdir -p ~/.local/bin
cp "$PROJECT_DIR/build/REE-$VERSION-x86_64.AppImage" ~/.local/bin/ree.AppImage
chmod +x ~/.local/bin/ree.AppImage

echo ""
echo "✓ Installed! You can now launch REE from your app menu."
echo "  Or run: ~/.local/bin/ree.AppImage"


