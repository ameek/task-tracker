#!/bin/bash
# macOS compatible focus features test
rm -rf "$HOME/.task-tracker"
chmod +x ./tracker.sh

echo "Testing task creation and auto-activation"
./tracker.sh start "Test Task 1"

echo "Checking active status"
./tracker.sh active

echo "Starting second task (should pause first)"
sleep 2
./tracker.sh start "Test Task 2"

echo "Checking active status again"
./tracker.sh active
