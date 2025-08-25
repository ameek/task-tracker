#!/bin/bash

# install-tracker.sh - Installation script for Task Tracker (macOS compatible)
set -e

echo "🚀 Installing Task Tracker (macOS)..."
echo "================================"

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_SCRIPT="$CURRENT_DIR/tracker.sh"
INSTALL_DIR="$HOME/.task-tracker"
SCRIPT_NAME="tracker.sh"
SCRIPT_PATH="$INSTALL_DIR/$SCRIPT_NAME"
SYMLINK_PATH="/usr/local/bin/tracker"

# Check for jq
if ! command -v jq &> /dev/null; then
    echo "⚠️  jq is not installed. Installing jq..."
    if command -v brew &> /dev/null; then
        brew install jq
    else
        echo "❌ Please install jq manually: brew install jq"
        exit 1
    fi
fi

# Check for gdate
if ! command -v gdate &> /dev/null; then
    echo "⚠️  gdate (coreutils) is not installed. Installing..."
    if command -v brew &> /dev/null; then
        brew install coreutils
    else
        echo "❌ Please install coreutils manually: brew install coreutils"
        exit 1
    fi
fi

# Create installation directory
mkdir -p "$INSTALL_DIR"
cp "$SOURCE_SCRIPT" "$SCRIPT_PATH"
chmod +x "$SCRIPT_PATH"

# Create system-wide symlink
if [ -L "$SYMLINK_PATH" ]; then
    sudo rm "$SYMLINK_PATH"
elif [ -f "$SYMLINK_PATH" ]; then
    sudo mv "$SYMLINK_PATH" "$SYMLINK_PATH.backup"
fi
sudo ln -s "$SCRIPT_PATH" "$SYMLINK_PATH"

# Initialize tracker data
echo "📊 Initializing tracker data..."
"$SCRIPT_PATH" -h > /dev/null 2>&1 || true

echo "✅ Installation completed!"
echo "================================"
echo "📂 Installed to: $INSTALL_DIR/"
echo "📄 Script: $SCRIPT_PATH"
echo "🔗 System command: tracker"
echo "📊 Data will be stored in: $HOME/.task-tracker/"
echo ""
echo "🧪 Testing installation..."
if command -v tracker &> /dev/null; then
    echo "✅ 'tracker' command is available system-wide!"
    tracker -h
else
    echo "❌ Installation failed. 'tracker' command not found."
    echo "   Try adding /usr/local/bin to your PATH or run:"
    echo "   export PATH=\"/usr/local/bin:\$PATH\""
    exit 1
fi

echo "🎉 Installation successful! You can now use 'tracker' from anywhere in your system."
