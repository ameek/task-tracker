#!/bin/bash
# macOS compatible complete workflow test
rm -rf "$HOME/.task-tracker"

echo "Starting first task..."
./tracker.sh start "Reading documentation"
TASK1_ID=$(jq -r '.[-1].id' "$HOME/.task-tracker/tasks.json")
echo "Task 1 ID: $TASK1_ID"
sleep 5

echo "Starting second task (should pause first)..."
./tracker.sh start "Writing code"
TASK2_ID=$(jq -r '.[-1].id' "$HOME/.task-tracker/tasks.json")
echo "Task 2 ID: $TASK2_ID"
sleep 3

echo "Switching back to first task..."
./tracker.sh setActive "$TASK1_ID"
sleep 4

echo "Current status:"
./tracker.sh active

echo "Adding details and links..."
./tracker.sh details "$TASK1_ID" "Key concepts learned; Implementation details; Best practices"
./tracker.sh link "$TASK1_ID" "https://docs.example.com"

echo "Finishing first task..."
./tracker.sh finish "$TASK1_ID" "Successfully completed documentation review"

echo "Switching to second task and finishing..."
./tracker.sh setActive "$TASK2_ID"
sleep 2
./tracker.sh finish "$TASK2_ID" "Code implementation completed"
