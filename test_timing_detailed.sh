#!/bin/bash

echo "🧪 Testing Pause/Resume Timing in Detail"
echo "========================================"

# Clean up test environment
rm -rf "$HOME/.task-tracker"

echo ""
echo "1️⃣ Starting Task A and letting it run for 3 seconds"
echo "---------------------------------------------------"
./tracker.sh start "Task A - Long running"
TASK_A_ID=$(jq -r '.[-1].id' "$HOME/.task-tracker/tasks.json")
echo "Task A ID: $TASK_A_ID"
sleep 3

echo ""
echo "2️⃣ Starting Task B (should pause Task A)"
echo "----------------------------------------"
./tracker.sh start "Task B - Interruption"
TASK_B_ID=$(jq -r '.[-1].id' "$HOME/.task-tracker/tasks.json")
echo "Task B ID: $TASK_B_ID"
sleep 2

echo ""
echo "3️⃣ Switching back to Task A (should resume and accumulate pause time)"
echo "--------------------------------------------------------------------"
./tracker.sh setActive "$TASK_A_ID"
sleep 2

echo ""
echo "4️⃣ Switching to Task B again"
echo "----------------------------"
./tracker.sh setActive "$TASK_B_ID"
sleep 1

echo ""
echo "5️⃣ Checking pause/resume data"
echo "-----------------------------"
echo "Full task data:"
./tracker.sh show | jq '.'

echo ""
echo "6️⃣ Finishing both tasks to see final working durations"
echo "-----------------------------------------------------"
./tracker.sh finish "$TASK_B_ID" "Task B completed"
./tracker.sh setActive "$TASK_A_ID"
sleep 1
./tracker.sh finish "$TASK_A_ID" "Task A completed"

echo ""
echo "7️⃣ Final results showing working durations vs total elapsed time"
echo "---------------------------------------------------------------"
./tracker.sh show | jq '.[] | {
  id: .id,
  task: .start_desc,
  start: .start,
  end: .end,
  working_duration: .duration,
  total_paused_seconds: .total_paused_seconds,
  completed: .end_desc
}'

echo ""
echo "✅ Analysis: Both tasks should show working duration less than total elapsed time"
echo "   due to the pause/resume functionality working correctly."
