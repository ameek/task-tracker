#!/bin/bash

# install-tracker.sh - Installation script for Task Tracker
# This script installs the task tracker with system-wide access

set -e  # Exit on any error

echo "🚀 Installing Task Tracker..."
echo "================================"

# Define paths
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_SCRIPT="$CURRENT_DIR/tracker.sh"
INSTALL_DIR="$HOME/.task-tracker"
SCRIPT_NAME="tracker.sh"
SCRIPT_PATH="$INSTALL_DIR/$SCRIPT_NAME"
SYMLINK_PATH="/usr/local/bin/tracker"

# Check if source script exists
if [ ! -f "$SOURCE_SCRIPT" ]; then
    echo "❌ Source script not found: $SOURCE_SCRIPT"
    echo "   Make sure you're running this from the directory containing tracker.sh"
    exit 1
fi

# Create installation directory
echo "📁 Creating installation directory..."
mkdir -p "$INSTALL_DIR"

# Copy the tracker.sh script to the installation directory
echo "📄 Copying tracker script..."
cp "$SOURCE_SCRIPT" "$SCRIPT_PATH"

# Update the script to use the new directory structure
echo "🔧 Updating script paths..."
sed -i 's|FILE="$HOME/prod-tracker/tasks.json"|FILE="$HOME/.task-tracker/tasks.json"|g' "$SCRIPT_PATH"
sed -i 's|TMP="$HOME/prod-tracker/tmp_task.json"|TMP="$HOME/.task-tracker/tmp_task.json"|g' "$SCRIPT_PATH"
sed -i 's|if \[ ! -d "$HOME/prod-tracker" \]; then|if [ ! -d "$HOME/.task-tracker" ]; then|g' "$SCRIPT_PATH"
sed -i 's|mkdir -p "$HOME/prod-tracker"|mkdir -p "$HOME/.task-tracker"|g' "$SCRIPT_PATH"
sed -i 's|echo "📁 Created directory: $HOME/prod-tracker"|echo "📁 Created directory: $HOME/.task-tracker"|g' "$SCRIPT_PATH"
sed -i 's|Usage: ./tracker.sh|Usage: tracker|g' "$SCRIPT_PATH"
sed -i 's|Example: ./tracker.sh|Example: tracker|g' "$SCRIPT_PATH"
sed -i 's|"./tracker.sh|"tracker|g' "$SCRIPT_PATH"

# Add installation info to help
sed -i '/echo "------------------------------------"/i\
  echo "📂 Data stored in: $HOME/.task-tracker/"\
  echo "🔗 Installed at: '"$SCRIPT_PATH"'"' "$SCRIPT_PATH"

# Make the script executable
echo "🔧 Making script executable..."
chmod +x "$SCRIPT_PATH"

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "⚠️  jq is not installed. Installing jq..."
    if command -v apt &> /dev/null; then
        sudo apt update && sudo apt install -y jq
    elif command -v yum &> /dev/null; then
        sudo yum install -y jq
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y jq
    elif command -v pacman &> /dev/null; then
        sudo pacman -S jq
    elif command -v brew &> /dev/null; then
        brew install jq
    else
        echo "❌ Could not install jq automatically. Please install it manually:"
        echo "   Ubuntu/Debian: sudo apt install jq"
        echo "   CentOS/RHEL: sudo yum install jq"
        echo "   Fedora: sudo dnf install jq"
        echo "   Arch: sudo pacman -S jq"
        echo "   macOS: brew install jq"
        exit 1
    fi
fi

# Create system-wide symlink
echo "🔗 Creating system-wide access..."
if [ -L "$SYMLINK_PATH" ]; then
    echo "⚠️  Existing symlink found. Removing..."
    sudo rm "$SYMLINK_PATH"
elif [ -f "$SYMLINK_PATH" ]; then
    echo "⚠️  Existing file found at $SYMLINK_PATH. Backing up..."
    sudo mv "$SYMLINK_PATH" "$SYMLINK_PATH.backup"
fi

sudo ln -s "$SCRIPT_PATH" "$SYMLINK_PATH"

# Initialize the tracker data directory and file
echo "📊 Initializing tracker data..."
"$SCRIPT_PATH" -h > /dev/null 2>&1 || true

# Verify installation
echo "✅ Installation completed!"
echo "================================"
echo "📂 Installed to: $INSTALL_DIR/"
echo "📄 Script: $SCRIPT_PATH"
echo "🔗 System command: tracker"
echo "📊 Data will be stored in: $HOME/.task-tracker/"
echo ""

# Test the installation
echo "🧪 Testing installation..."
if command -v tracker &> /dev/null; then
    echo "✅ 'tracker' command is available system-wide!"
    
    # Show version/help as test
    echo ""
    echo "📋 Running help command..."
    tracker -h
    
    echo ""
    echo "🚀 Quick start examples:"
    echo "  tracker start \"My first task\""
    echo "  tracker active"
    echo "  tracker show"
    echo "  tracker summary"
else
    echo "❌ Installation failed. 'tracker' command not found."
    echo "   Try adding /usr/local/bin to your PATH or run:"
    echo "   export PATH=\"/usr/local/bin:\$PATH\""
    exit 1
fi

echo ""
echo "🎉 Installation successful!"
echo "   You can now use 'tracker' from anywhere in your system."
echo "   Data and logs are stored in $HOME/.task-tracker/"

# Optional: Add to shell profile for PATH
if ! echo "$PATH" | grep -q "/usr/local/bin"; then
    echo ""
    echo "💡 Tip: If 'tracker' command doesn't work after restarting terminal,"
    echo "   add this line to your ~/.bashrc or ~/.zshrc:"
    echo "   export PATH=\"/usr/local/bin:\$PATH\""
fi
