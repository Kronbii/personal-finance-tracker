#!/bin/bash

# Database Restore Script
# Use this to restore your database from a backup if needed

set -e

BACKUP_DIR="$HOME/.local/share/ree/backups"
DB_FILE="$HOME/.local/share/ree/ree.db"

echo "=========================================="
echo "REE - Database Restore"
echo "=========================================="
echo ""

# List available backups
if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A "$BACKUP_DIR"/database_backup_*.db 2>/dev/null)" ]; then
    echo "❌ No backups found in: $BACKUP_DIR"
    exit 1
fi

echo "Available backups:"
echo ""
BACKUPS=($(ls -t "$BACKUP_DIR"/database_backup_*.db 2>/dev/null))
for i in "${!BACKUPS[@]}"; do
    BACKUP="${BACKUPS[$i]}"
    BACKUP_NAME=$(basename "$BACKUP")
    BACKUP_SIZE=$(stat -f%z "$BACKUP" 2>/dev/null || stat -c%s "$BACKUP" 2>/dev/null)
    BACKUP_DATE=$(echo "$BACKUP_NAME" | sed 's/database_backup_\(.*\)\.db/\1/')
    echo "  [$((i+1))] $BACKUP_DATE ($(numfmt --to=iec-i --suffix=B $BACKUP_SIZE 2>/dev/null || echo "${BACKUP_SIZE} bytes"))"
done

echo ""
read -p "Select backup to restore (1-${#BACKUPS[@]}): " SELECTION

if ! [[ "$SELECTION" =~ ^[0-9]+$ ]] || [ "$SELECTION" -lt 1 ] || [ "$SELECTION" -gt "${#BACKUPS[@]}" ]; then
    echo "❌ Invalid selection"
    exit 1
fi

SELECTED_BACKUP="${BACKUPS[$((SELECTION-1))]}"

# Confirm restore
echo ""
echo "⚠️  WARNING: This will replace your current database!"
echo "   Current: $DB_FILE"
echo "   Restore from: $SELECTED_BACKUP"
echo ""
read -p "Are you sure you want to restore? (yes/N): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Restore cancelled."
    exit 0
fi

# Check if database is locked
if [ -f "$DB_FILE" ] && lsof "$DB_FILE" >/dev/null 2>&1; then
    echo ""
    echo "❌ Error: Database file is currently in use!"
    echo "   Please close the app before restoring."
    exit 1
fi

# Backup current database before restore
if [ -f "$DB_FILE" ]; then
    CURRENT_BACKUP="$BACKUP_DIR/pre_restore_$(date +%Y%m%d_%H%M%S).db"
    echo ""
    echo "Creating backup of current database..."
    cp "$DB_FILE" "$CURRENT_BACKUP"
    echo "✓ Current database backed up to: $CURRENT_BACKUP"
fi

# Restore
echo ""
echo "Restoring database..."
cp "$SELECTED_BACKUP" "$DB_FILE"
chmod 600 "$DB_FILE"

# Verify
if [ -f "$DB_FILE" ]; then
    RESTORED_SIZE=$(stat -f%z "$DB_FILE" 2>/dev/null || stat -c%s "$DB_FILE" 2>/dev/null)
    BACKUP_SIZE=$(stat -f%z "$SELECTED_BACKUP" 2>/dev/null || stat -c%s "$SELECTED_BACKUP" 2>/dev/null)
    
    if [ "$RESTORED_SIZE" -eq "$BACKUP_SIZE" ]; then
        echo "✅ Database restored successfully!"
        echo "   Size: $(numfmt --to=iec-i --suffix=B $RESTORED_SIZE 2>/dev/null || echo "${RESTORED_SIZE} bytes")"
    else
        echo "⚠️  Warning: Restored database size doesn't match backup!"
        echo "   Backup: $BACKUP_SIZE bytes"
        echo "   Restored: $RESTORED_SIZE bytes"
    fi
else
    echo "❌ Error: Failed to restore database!"
    exit 1
fi

echo ""
echo "✅ Restore complete! You can now launch the app."

