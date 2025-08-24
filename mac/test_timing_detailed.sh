#!/bin/bash
# macOS compatible timing test
rm -rf "$HOME/.task-tracker"

echo "Starting Task A and letting it run for 3 seconds"
./tracker.sh start "Task A - Long running"
TASK_A_ID=$(jq -r '.[-1].id' "$HOME/.task-tracker/tasks.json")
sleep 3

echo "Starting Task B (should pause Task A)"
./tracker.sh start "Task B - Interruption"
TASK_B_ID=$(jq -r '.[-1].id' "$HOME/.task-tracker/tasks.json")
sleep 2

echo "Switching back to Task A (should resume and accumulate pause time)"
./tracker.sh setActive "$TASK_A_ID"
sleep 2

echo "Switching to Task B again"
./tracker.sh setActive "$TASK_B_ID"
sleep 1

echo "Checking pause/resume data"
./tracker.sh show | jq '.'
