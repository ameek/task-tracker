#!/bin/bash
# macOS compatible test for pauseAll and resumeAll features

echo "🧪 Testing pauseAll and resumeAll Features (macOS)"
echo "================================================="

# Clean up test environment
rm -rf "$HOME/.task-tracker"

echo ""
echo "1️⃣ Setting up test scenario with multiple active tasks"
echo "-----------------------------------------------------"

# Start first task
echo "Starting Task 1..."
./tracker.sh start "Reading documentation"
TASK1_ID=$(jq -r '.[-1].id' "$HOME/.task-tracker/tasks.json")
echo "Task 1 ID: $TASK1_ID"

# Start second task (this pauses first one)
echo "Starting Task 2..."
./tracker.sh start "Writing code"
TASK2_ID=$(jq -r '.[-1].id' "$HOME/.task-tracker/tasks.json")
echo "Task 2 ID: $TASK2_ID"

# Start third task
echo "Starting Task 3..."
./tracker.sh start "Testing features"
TASK3_ID=$(jq -r '.[-1].id' "$HOME/.task-tracker/tasks.json")
echo "Task 3 ID: $TASK3_ID"

echo ""
echo "2️⃣ Checking current status before break"
echo "--------------------------------------"
./tracker.sh active

echo ""
echo "3️⃣ Testing pauseAll - Going for a break"
echo "---------------------------------------"
./tracker.sh pauseAll

echo ""
echo "4️⃣ Checking status after pauseAll"
echo "---------------------------------"
./tracker.sh active

echo ""
echo "5️⃣ Testing resumeAll - Back from break"
echo "-------------------------------------"
sleep 2  # Simulate break time
./tracker.sh resumeAll

echo ""
echo "6️⃣ Checking status after resumeAll"
echo "----------------------------------"
./tracker.sh active

echo ""
echo "7️⃣ Testing edge cases"
echo "--------------------"
echo "Testing pauseAll when no tasks are active:"
./tracker.sh finish "$TASK1_ID" "Completed"
./tracker.sh finish "$TASK2_ID" "Completed"
./tracker.sh finish "$TASK3_ID" "Completed"
./tracker.sh pauseAll

echo ""
echo "Testing resumeAll when no tasks are paused:"
./tracker.sh resumeAll

echo ""
echo "✅ pauseAll and resumeAll tests completed!"
echo "==========================================="
echo "New commands available:"
echo "• tracker pauseAll    - Pause all active tasks for a break"
echo "• tracker resumeAll   - Resume all paused tasks after break"
echo ""
echo "Use cases:"
echo "• Going for lunch/meeting - pauseAll before leaving"
echo "• End of day - pauseAll to stop tracking"
echo "• Start of day - resumeAll to continue previous work"
echo "• Break management - clear separation of work/break time"
