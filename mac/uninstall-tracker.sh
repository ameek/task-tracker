#!/bin/bash

# uninstall-tracker.sh - Uninstallation script for Task Tracker (macOS compatible)
set -e

echo "🗑️  Uninstalling Task Tracker (macOS)..."
echo "================================"

INSTALL_DIR="$HOME/.task-tracker"
SYMLINK_PATH="/usr/local/bin/tracker"

# Remove system-wide symlink
if [ -L "$SYMLINK_PATH" ]; then
    sudo rm "$SYMLINK_PATH"
    echo "✅ Removed: $SYMLINK_PATH"
elif [ -f "$SYMLINK_PATH" ]; then
    echo "⚠️  Found file (not symlink) at $SYMLINK_PATH"
    echo "   Please remove manually if it's the tracker"
fi

echo ""
echo "📊 Your task data is stored in: $INSTALL_DIR"
echo "   This includes your tasks.json with all your tracked work."
echo ""
read -p "Do you want to remove all data? (y/N): " -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [ -d "$INSTALL_DIR" ]; then
        rm -rf "$INSTALL_DIR"
        echo "✅ Removed: $INSTALL_DIR"
    else
        echo "ℹ️  Data directory not found: $INSTALL_DIR"
    fi
else
    echo "📁 Keeping your data in: $INSTALL_DIR"
    echo "   You can manually remove it later if needed."
fi

echo ""
echo "🧪 Testing uninstallation..."
if command -v tracker &> /dev/null; then
    echo "⚠️  'tracker' command is still available"
    echo "   Check your PATH for other installations"
else
    echo "✅ 'tracker' command successfully removed"
fi

echo "🎉 Uninstallation completed! Thank you for using Task Tracker!"
