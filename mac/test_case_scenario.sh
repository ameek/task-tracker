#!/bin/bash
# macOS compatible scenario test
rm -rf "$HOME/.task-tracker"

echo "1️⃣ Starting first task (t1) - should become active"
./tracker.sh start "Task 1 - Reading documentation"
T1_ID=$(jq -r '.[-1].id' "$HOME/.task-tracker/tasks.json")
echo "Task 1 ID: $T1_ID"

echo "2️⃣ Checking that t1 is active"
./tracker.sh active

echo "3️⃣ Starting second task (t2) while t1 is active"
./tracker.sh start "Task 2 - Writing code"
T2_ID=$(jq -r '.[-1].id' "$HOME/.task-tracker/tasks.json")
echo "Task 2 ID: $T2_ID"

echo "4️⃣ Checking current status after creating t2"
./tracker.sh active

echo "5️⃣ Verifying the pause mechanism in JSON data"
T1_PAUSE_TIME=$(jq -r --arg id "$T1_ID" '.[] | select(.id==$id) | .pause_time // "null"' "$HOME/.task-tracker/tasks.json")
echo "Task 1 pause_time: $T1_PAUSE_TIME"
T2_PAUSE_TIME=$(jq -r --arg id "$T2_ID" '.[] | select(.id==$id) | .pause_time // "null"' "$HOME/.task-tracker/tasks.json")
echo "Task 2 pause_time: $T2_PAUSE_TIME"
CURRENT_ACTIVE=$(cat "$HOME/.task-tracker/active_task.txt" 2>/dev/null || echo "none")
echo "Currently active task ID: $CURRENT_ACTIVE"
echo "Expected: $T2_ID"
