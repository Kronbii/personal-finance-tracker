#!/bin/bash

# Build AppImage for Linux
# Prerequisites: flutter, appimagetool

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build/linux/x64/release/bundle"
APPDIR="$PROJECT_DIR/build/AppDir"
APP_NAME="Personal Finance Tracker"
APP_ID="com.kronbii.personal_finance_tracker"
VERSION="1.0.0"

echo "Building Flutter Linux release..."
cd "$PROJECT_DIR"
flutter build linux --release

echo "Creating AppDir structure..."
rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin"
mkdir -p "$APPDIR/usr/share/applications"
mkdir -p "$APPDIR/usr/share/icons/hicolor/256x256/apps"
mkdir -p "$APPDIR/usr/share/metainfo"

echo "Copying bundle..."
cp -r "$BUILD_DIR"/* "$APPDIR/usr/bin/"

echo "Creating desktop entry..."
cat > "$APPDIR/usr/share/applications/$APP_ID.desktop" << EOF
[Desktop Entry]
Name=$APP_NAME
Comment=A premium personal finance tracker
Exec=personal_finance_tracker
Icon=$APP_ID
Terminal=false
Type=Application
Categories=Office;Finance;
StartupWMClass=personal_finance_tracker
EOF

# Copy desktop file to AppDir root (required by AppImage)
cp "$APPDIR/usr/share/applications/$APP_ID.desktop" "$APPDIR/"

echo "Creating AppRun script..."
cat > "$APPDIR/AppRun" << 'EOF'
#!/bin/bash
SELF=$(readlink -f "$0")
HERE=${SELF%/*}
export PATH="${HERE}/usr/bin/:${PATH}"
export LD_LIBRARY_PATH="${HERE}/usr/lib/:${LD_LIBRARY_PATH}"
exec "${HERE}/usr/bin/personal_finance_tracker" "$@"
EOF
chmod +x "$APPDIR/AppRun"

# Create a placeholder icon (you should replace this with your actual icon)
echo "Creating placeholder icon..."
cat > "$APPDIR/usr/share/icons/hicolor/256x256/apps/$APP_ID.svg" << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 256 256">
  <defs>
    <linearGradient id="grad1" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#0A84FF;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#5E5CE6;stop-opacity:1" />
    </linearGradient>
  </defs>
  <rect width="256" height="256" rx="48" fill="url(#grad1)"/>
  <path d="M128 48c-44.183 0-80 35.817-80 80s35.817 80 80 80 80-35.817 80-80-35.817-80-80-80zm0 140c-33.137 0-60-26.863-60-60s26.863-60 60-60 60 26.863 60 60-26.863 60-60 60z" fill="white" opacity="0.9"/>
  <path d="M128 88v40l28 16" stroke="white" stroke-width="8" stroke-linecap="round" fill="none"/>
</svg>
EOF

# Copy icon to AppDir root
cp "$APPDIR/usr/share/icons/hicolor/256x256/apps/$APP_ID.svg" "$APPDIR/$APP_ID.svg"

echo "Creating AppStream metadata..."
cat > "$APPDIR/usr/share/metainfo/$APP_ID.appdata.xml" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<component type="desktop-application">
  <id>$APP_ID</id>
  <name>$APP_NAME</name>
  <summary>A premium personal finance tracker</summary>
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
    <binary>personal_finance_tracker</binary>
  </provides>
  <releases>
    <release version="$VERSION" date="$(date +%Y-%m-%d)"/>
  </releases>
</component>
EOF

echo "Building AppImage..."
if ! command -v appimagetool &> /dev/null; then
    echo "appimagetool not found. Downloading..."
    wget -O /tmp/appimagetool "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
    chmod +x /tmp/appimagetool
    APPIMAGETOOL="/tmp/appimagetool"
else
    APPIMAGETOOL="appimagetool"
fi

ARCH=x86_64 "$APPIMAGETOOL" "$APPDIR" "$PROJECT_DIR/build/Personal_Finance_Tracker-$VERSION-x86_64.AppImage"

echo ""
echo "========================================"
echo "AppImage built successfully!"
echo "Location: $PROJECT_DIR/build/Personal_Finance_Tracker-$VERSION-x86_64.AppImage"
echo "========================================"

