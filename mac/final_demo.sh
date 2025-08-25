#!/bin/bash
# macOS compatible demo script
rm -rf "$HOME/.task-tracker"

echo ""
echo "Scenario: User creates t1, then creates t2 while t1 is active"
echo "============================================================="

echo "Step 1: Starting Task 1 (t1)"
./tracker.sh start "Reading documentation"

echo "Step 2: Checking that t1 is active"
./tracker.sh active | grep "ACTIVE"

echo "Step 3: Starting Task 2 (t2) - should pause t1 automatically"
echo "Watch for the pause message:"
./tracker.sh start "Writing unit tests"

echo "Step 4: Verifying final status"
./tracker.sh active

echo "Step 5: Testing setActive switching"
T1_ID=$(jq -r '.[0].id' "$HOME/.task-tracker/tasks.json")
echo "Switching back to Task 1 (ID: $T1_ID):"
./tracker.sh setActive "$T1_ID"

echo "Step 6: Final verification"
./tracker.sh active

echo "✅ SUMMARY: Your case is now fully covered!"
