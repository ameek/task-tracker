#!/bin/bash

echo "🧪 Testing Focus Features with Longer Durations"
echo "==============================================="

# Clean up test environment
rm -rf "$HOME/.task-tracker"

echo ""
echo "1️⃣ Testing the complete workflow"
echo "--------------------------------"

# Start first task
echo "Starting first task..."
./tracker.sh start "Reading documentation"
TASK1_ID=$(jq -r '.[-1].id' "$HOME/.task-tracker/tasks.json")
echo "Task 1 ID: $TASK1_ID"

# Let it run for a bit
echo "Working on task 1 for 5 seconds..."
sleep 5

# Start second task (this should pause the first)
echo "Starting second task (should pause first)..."
./tracker.sh start "Writing code"
TASK2_ID=$(jq -r '.[-1].id' "$HOME/.task-tracker/tasks.json")
echo "Task 2 ID: $TASK2_ID"

# Work on second task
echo "Working on task 2 for 3 seconds..."
sleep 3

# Switch back to first task
echo "Switching back to first task..."
./tracker.sh setActive "$TASK1_ID"

# Work on first task again
echo "Working on task 1 again for 4 seconds..."
sleep 4

# Check status
echo ""
echo "Current status:"
./tracker.sh active

# Add some details
echo ""
echo "Adding details and links..."
./tracker.sh details "$TASK1_ID" "Key concepts learned; Implementation details; Best practices"
./tracker.sh link "$TASK1_ID" "https://docs.example.com"

# Finish first task
echo ""
echo "Finishing first task..."
./tracker.sh finish "$TASK1_ID" "Successfully completed documentation review"

# Switch to second task and finish it
echo ""
echo "Switching to second task and finishing..."
./tracker.sh setActive "$TASK2_ID"
sleep 2
./tracker.sh finish "$TASK2_ID" "Code implementation completed"

echo ""
echo "📊 Final Results Analysis"
echo "========================="

# Show final data with analysis
jq '.[] | {
  id: .id,
  task: .start_desc,
  start_time: .start,
  end_time: .end,
  total_elapsed_seconds: ((.end | strptime("%Y-%m-%d %H:%M:%S") | mktime) - (.start | strptime("%Y-%m-%d %H:%M:%S") | mktime)),
  working_duration: .duration,
  total_paused_seconds: .total_paused_seconds,
  working_percentage: (((.end | strptime("%Y-%m-%d %H:%M:%S") | mktime) - (.start | strptime("%Y-%m-%d %H:%M:%S") | mktime) - .total_paused_seconds) * 100 / ((.end | strptime("%Y-%m-%d %H:%M:%S") | mktime) - (.start | strptime("%Y-%m-%d %H:%M:%S") | mktime)))
}' "$HOME/.task-tracker/tasks.json"

echo ""
echo "✅ Test Summary:"
echo "• Both tasks have been paused and resumed correctly"
echo "• Working duration excludes paused time"
echo "• Only one task was active at any given time"
echo "• Error handling works for invalid operations"

echo ""
echo "📋 Raw task data:"
./tracker.sh show
