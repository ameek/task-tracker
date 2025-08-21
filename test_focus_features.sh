#!/bin/bash

echo "🧪 Testing Focus Features for Task Tracker"
echo "=========================================="

# Clean up test environment
rm -rf "$HOME/.task-tracker"

# Make tracker executable
chmod +x ./tracker.sh

echo ""
echo "1️⃣ Testing task creation and auto-activation"
echo "-------------------------------------------"
./tracker.sh start "Test Task 1"
echo ""

echo "2️⃣ Checking active status"
echo "-------------------------"
./tracker.sh active
echo ""

echo "3️⃣ Starting second task (should pause first)"
echo "--------------------------------------------"
sleep 2  # Wait a bit to show time difference
./tracker.sh start "Test Task 2"
echo ""

echo "4️⃣ Checking active status again"
echo "-------------------------------"
./tracker.sh active
echo ""

echo "5️⃣ Getting task IDs for switching"
echo "---------------------------------"
TASK1_ID=$(jq -r '.[0].id' "$HOME/.task-tracker/tasks.json")
TASK2_ID=$(jq -r '.[1].id' "$HOME/.task-tracker/tasks.json")
echo "Task 1 ID: $TASK1_ID"
echo "Task 2 ID: $TASK2_ID"
echo ""

echo "6️⃣ Switching back to first task"
echo "-------------------------------"
sleep 2  # Wait a bit to show pause/resume timing
./tracker.sh setActive "$TASK1_ID"
echo ""

echo "7️⃣ Checking active status after switch"
echo "-------------------------------------"
./tracker.sh active
echo ""

echo "8️⃣ Adding details and links to active task"
echo "------------------------------------------"
./tracker.sh details "$TASK1_ID" "Important findings; Key insights; Next steps"
./tracker.sh link "$TASK1_ID" "https://example.com/docs"
echo ""

echo "9️⃣ Finishing first task"
echo "-----------------------"
sleep 2  # Wait a bit more to accumulate working time
./tracker.sh finish "$TASK1_ID" "Completed successfully with good progress"
echo ""

echo "🔟 Checking final status and showing all tasks"
echo "---------------------------------------------"
./tracker.sh active
echo ""
echo "All tasks:"
./tracker.sh show
echo ""

echo "1️⃣1️⃣ Testing error conditions"
echo "-----------------------------"
echo "Trying to set non-existent task as active:"
./tracker.sh setActive "nonexistent"
echo ""
echo "Trying to set finished task as active:"
./tracker.sh setActive "$TASK1_ID"
echo ""

echo "1️⃣2️⃣ Testing pause/resume timing validation"
echo "------------------------------------------"
TASK2_DATA=$(jq -r --arg id "$TASK2_ID" '.[] | select(.id==$id)' "$HOME/.task-tracker/tasks.json")
TOTAL_PAUSED=$(echo "$TASK2_DATA" | jq -r '.total_paused_seconds // 0')
echo "Task 2 total paused time: $TOTAL_PAUSED seconds"

if [ "$TOTAL_PAUSED" -gt 0 ]; then
    echo "✅ Pause/resume timing is working correctly"
else
    echo "⚠️  Warning: Expected some pause time for Task 2"
fi

echo ""
echo "🎉 Test completed! Check the results above to verify:"
echo "   • Tasks auto-activate when started"
echo "   • Only one task is active at a time"
echo "   • Switching tasks pauses/resumes correctly"
echo "   • Duration calculations exclude paused time"
echo "   • Error handling works for invalid operations"
