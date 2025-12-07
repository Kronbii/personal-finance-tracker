# AppImage File Locations

This document describes where all files are located in your REE AppImage and on your system.

## 📦 AppImage Structure

When you build the AppImage, it creates a self-contained package. Here's the internal structure:

```
REE-1.0.0-x86_64.AppImage (mounted or extracted)
├── AppRun                    # Main launcher script
├── com.kronbii.ree.desktop   # Desktop entry file
├── com.kronbii.ree.png       # App icon (root level)
├── .DirIcon                  # Directory icon for file managers
└── usr/
    ├── bin/
    │   ├── ree               # ⭐ MAIN EXECUTABLE (your app binary)
    │   ├── lib/              # Shared libraries
    │   └── data/             # Flutter assets and resources
    ├── lib/                  # Additional libraries
    ├── share/
    │   ├── applications/
    │   │   └── com.kronbii.ree.desktop  # Desktop entry
    │   ├── icons/
    │   │   └── hicolor/256x256/apps/
    │   │       └── com.kronbii.ree.png   # App icon
    │   └── metainfo/
    │       └── com.kronbii.ree.appdata.xml  # AppStream metadata
```

## 🗂️ System File Locations (After Installation)

### Executable
- **Location**: `~/.local/bin/ree.AppImage`
- **Description**: The AppImage file itself is the executable. It's self-contained and portable.

### Database (Production)
- **Location**: `~/.local/share/ree/ree.db`
- **Description**: Your production SQLite database with all your financial data
- **Backup Location**: `~/.local/share/ree/backups/`
  - Format: `database_backup_YYYYMMDD_HHMMSS.db`
  - Keeps last 5 backups automatically

### App Icon
- **Source**: `linux/icons/ree.png` (in your project)
- **In AppImage**: 
  - `com.kronbii.ree.png` (root)
  - `usr/share/icons/hicolor/256x256/apps/com.kronbii.ree.png`
- **System Integration**: Desktop environments will use this for app launchers

### Desktop Entry
- **In AppImage**: 
  - `com.kronbii.ree.desktop` (root)
  - `usr/share/applications/com.kronbii.ree.desktop`
- **System Integration**: If installed system-wide, appears in:
  - `~/.local/share/applications/com.kronbii.ree.desktop` (user)
  - `/usr/share/applications/com.kronbii.ree.desktop` (system)

### Configuration & Data
- **App Data Directory**: `~/.local/share/ree/`
  - Database: `ree.db`
  - Backups: `backups/`
  - Any other app-specific data

### Test Database (Development Only)
- **Location**: `.test_data/ree_test.db` (in project directory)
- **Description**: Only used when running in debug mode from source

## 🔍 How to Inspect AppImage Contents

### Method 1: Mount the AppImage
```bash
# Make it executable
chmod +x ~/.local/bin/ree.AppImage

# Mount it (creates a mount point)
mkdir -p /tmp/ree-appimage
~/.local/bin/ree.AppImage --appimage-mount &
# Note the mount point from output, then explore it
```

### Method 2: Extract the AppImage
```bash
# Extract to a directory
~/.local/bin/ree.AppImage --appimage-extract
# Explore the extracted directory
ls -la squashfs-root/
```

### Method 3: List Contents
```bash
# List files in AppImage
~/.local/bin/ree.AppImage --appimage-list
```

## 📝 Key Files Summary

| Item | Location | Purpose |
|------|----------|---------|
| **Executable** | `~/.local/bin/ree.AppImage` | The app itself (self-contained) |
| **Database** | `~/.local/share/ree/ree.db` | Your production data |
| **Icon** | `linux/icons/ree.png` (source) | App icon |
| **Desktop Entry** | `linux/ree.desktop` (source) | Desktop integration |
| **Backups** | `~/.local/share/ree/backups/` | Database backups |

## 🛠️ Building the AppImage

The build script (`scripts/build_appimage.sh`) creates the AppImage structure:

1. Builds Flutter Linux release
2. Creates AppDir structure
3. Copies executable to `usr/bin/ree`
4. Copies icon to multiple locations
5. Creates desktop entry
6. Packages everything into AppImage

## 🔐 Important Notes

- **Database is NOT in AppImage**: Your database is stored separately in `~/.local/share/ree/` to preserve data across updates
- **AppImage is Portable**: You can move `ree.AppImage` anywhere and it will work
- **Data Persists**: Database location is independent of AppImage location
- **Backups are Automatic**: The safe update script creates backups before updating

