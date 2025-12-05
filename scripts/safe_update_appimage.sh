#!/bin/bash

# Safe AppImage Update Script
# This script safely updates the AppImage while preserving your production database
# It creates backups and only updates the binary, not your data

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
APPIMAGE_PATH="$HOME/.local/bin/ree.AppImage"
BACKUP_DIR="$HOME/.local/share/ree/backups"
DB_DIR="$HOME/.local/share/ree"
DB_FILE="$DB_DIR/ree.db"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/database_backup_$TIMESTAMP.db"

echo "=========================================="
echo "REE - Safe AppImage Update"
echo "=========================================="
echo ""

# Check if AppImage exists
if [ ! -f "$APPIMAGE_PATH" ]; then
    echo "⚠️  Existing AppImage not found at $APPIMAGE_PATH"
    echo "   This appears to be a fresh installation."
    echo ""
    read -p "Continue with fresh installation? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Update cancelled."
        exit 1
    fi
    FRESH_INSTALL=true
else
    FRESH_INSTALL=false
    echo "✓ Found existing AppImage at: $APPIMAGE_PATH"
fi

# Create backup directory
echo ""
echo "Creating backup directory..."
mkdir -p "$BACKUP_DIR"
mkdir -p "$(dirname "$APPIMAGE_PATH")"

# Backup existing AppImage if it exists
if [ "$FRESH_INSTALL" = false ]; then
    echo ""
    echo "Backing up existing AppImage..."
    APPIMAGE_BACKUP="$BACKUP_DIR/ree.AppImage.backup_$TIMESTAMP"
    cp "$APPIMAGE_PATH" "$APPIMAGE_BACKUP"
    echo "✓ AppImage backed up to: $APPIMAGE_BACKUP"
fi

# Backup database if it exists
if [ -f "$DB_FILE" ]; then
    echo ""
    echo "🔒 Backing up production database..."
    echo "   Source: $DB_FILE"
    echo "   Backup: $BACKUP_FILE"
    
    # Check if database is locked (app might be running)
    if lsof "$DB_FILE" >/dev/null 2>&1; then
        echo ""
        echo "⚠️  WARNING: Database file is currently in use!"
        echo "   The app might be running. Please close the app before updating."
        echo ""
        read -p "Continue anyway? (NOT RECOMMENDED) (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Update cancelled. Please close the app and try again."
            exit 1
        fi
    fi
    
    # Create backup
    cp "$DB_FILE" "$BACKUP_FILE"
    
    # Verify backup was created
    if [ -f "$BACKUP_FILE" ]; then
        ORIGINAL_SIZE=$(stat -f%z "$DB_FILE" 2>/dev/null || stat -c%s "$DB_FILE" 2>/dev/null)
        BACKUP_SIZE=$(stat -f%z "$BACKUP_FILE" 2>/dev/null || stat -c%s "$BACKUP_FILE" 2>/dev/null)
        
        if [ "$ORIGINAL_SIZE" -eq "$BACKUP_SIZE" ]; then
            echo "✓ Database backup created successfully ($(numfmt --to=iec-i --suffix=B $BACKUP_SIZE 2>/dev/null || echo "${BACKUP_SIZE} bytes"))"
        else
            echo "⚠️  Warning: Backup size doesn't match original!"
            echo "   Original: $ORIGINAL_SIZE bytes"
            echo "   Backup: $BACKUP_SIZE bytes"
            read -p "Continue anyway? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                echo "Update cancelled. Backup preserved at: $BACKUP_FILE"
                exit 1
            fi
        fi
    else
        echo "❌ Error: Failed to create database backup!"
        echo "   Update cancelled to protect your data."
        exit 1
    fi
else
    echo ""
    echo "ℹ️  No existing database found (fresh installation)"
fi

# Build new AppImage
echo ""
echo "=========================================="
echo "Building new AppImage..."
echo "=========================================="
cd "$PROJECT_DIR"
bash "$SCRIPT_DIR/build_appimage.sh"

# Verify new AppImage was built
NEW_APPIMAGE="$PROJECT_DIR/build/REE-1.0.0-x86_64.AppImage"
if [ ! -f "$NEW_APPIMAGE" ]; then
    echo ""
    echo "❌ Error: New AppImage was not built successfully!"
    echo "   Restoring previous AppImage..."
    
    if [ "$FRESH_INSTALL" = false ] && [ -f "$APPIMAGE_BACKUP" ]; then
        cp "$APPIMAGE_BACKUP" "$APPIMAGE_PATH"
        echo "✓ Previous AppImage restored"
    fi
    
    exit 1
fi

# Replace AppImage (this is safe - database is separate)
echo ""
echo "=========================================="
echo "Installing new AppImage..."
echo "=========================================="
echo "   Replacing: $APPIMAGE_PATH"
cp "$NEW_APPIMAGE" "$APPIMAGE_PATH"
chmod +x "$APPIMAGE_PATH"

# Verify installation
if [ -f "$APPIMAGE_PATH" ]; then
    NEW_SIZE=$(stat -f%z "$APPIMAGE_PATH" 2>/dev/null || stat -c%s "$APPIMAGE_PATH" 2>/dev/null)
    echo "✓ New AppImage installed ($(numfmt --to=iec-i --suffix=B $NEW_SIZE 2>/dev/null || echo "${NEW_SIZE} bytes"))"
else
    echo "❌ Error: Failed to install new AppImage!"
    echo "   Restoring previous AppImage..."
    
    if [ "$FRESH_INSTALL" = false ] && [ -f "$APPIMAGE_BACKUP" ]; then
        cp "$APPIMAGE_BACKUP" "$APPIMAGE_PATH"
        echo "✓ Previous AppImage restored"
    fi
    
    exit 1
fi

# Verify database is still intact
if [ -f "$DB_FILE" ]; then
    echo ""
    echo "🔍 Verifying database integrity..."
    CURRENT_SIZE=$(stat -f%z "$DB_FILE" 2>/dev/null || stat -c%s "$DB_FILE" 2>/dev/null)
    BACKUP_SIZE=$(stat -f%z "$BACKUP_FILE" 2>/dev/null || stat -c%s "$BACKUP_FILE" 2>/dev/null)
    
    if [ "$CURRENT_SIZE" -eq "$BACKUP_SIZE" ]; then
        echo "✓ Database verified - size unchanged ($(numfmt --to=iec-i --suffix=B $CURRENT_SIZE 2>/dev/null || echo "${CURRENT_SIZE} bytes"))"
    else
        echo "⚠️  Warning: Database size changed!"
        echo "   This might be normal if migrations ran."
        echo "   Original: $(numfmt --to=iec-i --suffix=B $BACKUP_SIZE 2>/dev/null || echo "${BACKUP_SIZE} bytes")"
        echo "   Current: $(numfmt --to=iec-i --suffix=B $CURRENT_SIZE 2>/dev/null || echo "${CURRENT_SIZE} bytes")"
    fi
fi

# Clean up old backups (keep last 5)
echo ""
echo "Cleaning up old backups (keeping last 5)..."
cd "$BACKUP_DIR"
ls -t database_backup_*.db 2>/dev/null | tail -n +6 | xargs -r rm -f
ls -t ree.AppImage.backup_* 2>/dev/null | tail -n +6 | xargs -r rm -f
echo "✓ Old backups cleaned up"

echo ""
echo "=========================================="
echo "✅ Update Complete!"
echo "=========================================="
echo ""
echo "New AppImage installed to: $APPIMAGE_PATH"
if [ -f "$BACKUP_FILE" ]; then
    echo ""
    echo "🔒 Database backup saved to:"
    echo "   $BACKUP_FILE"
    echo ""
    echo "💡 To restore database if needed:"
    echo "   cp \"$BACKUP_FILE\" \"$DB_FILE\""
fi
echo ""
echo "You can now launch the updated app:"
echo "   ~/.local/bin/ree.AppImage"
echo ""
echo "Note: Database migrations will run automatically on first launch."
echo "      Your data is safe and will be preserved."
echo ""

