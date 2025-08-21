#!/bin/bash

echo "🧪 Testing Task Switching Scenario"
echo "=================================="

# Clean up test environment
rm -rf "$HOME/.task-tracker"

echo ""
echo "1️⃣ Starting first task (t1) - should become active"
echo "-------------------------------------------------"
./tracker.sh start "Task 1 - Reading documentation"
T1_ID=$(jq -r '.[-1].id' "$HOME/.task-tracker/tasks.json")
echo "Task 1 ID: $T1_ID"

echo ""
echo "2️⃣ Checking that t1 is active"
echo "-----------------------------"
./tracker.sh active

echo ""
echo "3️⃣ Starting second task (t2) while t1 is active"
echo "-----------------------------------------------"
echo "Expected: t1 should be paused automatically and t2 should become active"
./tracker.sh start "Task 2 - Writing code"
T2_ID=$(jq -r '.[-1].id' "$HOME/.task-tracker/tasks.json")
echo "Task 2 ID: $T2_ID"

echo ""
echo "4️⃣ Checking current status after creating t2"
echo "--------------------------------------------"
echo "Expected: t1 should show as ⏸️  PAUSED, t2 should show as 🎯 ACTIVE"
./tracker.sh active

echo ""
echo "5️⃣ Verifying the pause mechanism in JSON data"
echo "--------------------------------------------"
echo "Checking if t1 has pause_time set:"
T1_PAUSE_TIME=$(jq -r --arg id "$T1_ID" '.[] | select(.id==$id) | .pause_time // "null"' "$HOME/.task-tracker/tasks.json")
echo "Task 1 pause_time: $T1_PAUSE_TIME"

echo "Checking if t2 is not paused:"
T2_PAUSE_TIME=$(jq -r --arg id "$T2_ID" '.[] | select(.id==$id) | .pause_time // "null"' "$HOME/.task-tracker/tasks.json")
echo "Task 2 pause_time: $T2_PAUSE_TIME"

echo ""
echo "6️⃣ Checking active task file"
echo "---------------------------"
CURRENT_ACTIVE=$(cat "$HOME/.task-tracker/active_task.txt" 2>/dev/null || echo "none")
echo "Currently active task ID: $CURRENT_ACTIVE"
echo "Expected: $T2_ID"

echo ""
echo "7️⃣ Analysis Results"
echo "------------------"

if [ "$T1_PAUSE_TIME" != "null" ] && [ "$T1_PAUSE_TIME" != "" ]; then
    echo "✅ Task 1 was properly paused (has pause_time)"
else
    echo "❌ Task 1 was NOT paused (missing pause_time)"
fi

if [ "$T2_PAUSE_TIME" = "null" ] || [ "$T2_PAUSE_TIME" = "" ]; then
    echo "✅ Task 2 is active (no pause_time)"
else
    echo "❌ Task 2 should not be paused"
fi

if [ "$CURRENT_ACTIVE" = "$T2_ID" ]; then
    echo "✅ Task 2 is correctly set as active"
else
    echo "❌ Active task file doesn't match Task 2"
fi

echo ""
echo "8️⃣ Testing the message clarity"
echo "-----------------------------"
echo "Current output when starting a new task doesn't explicitly mention pausing the previous task."
echo "The user needs to check 'tracker active' to see the pause status."

echo ""
echo "🎯 RECOMMENDATION: Enhance the start_task function to show a pause message"
echo "======================================================================="
