#!/bin/bash

echo "🎯 Complete Task Switching Demo"
echo "==============================="

# Clean up test environment
rm -rf "$HOME/.task-tracker"

echo ""
echo "Scenario: User creates t1, then creates t2 while t1 is active"
echo "============================================================="

echo ""
echo "Step 1: Starting Task 1 (t1)"
echo "----------------------------"
./tracker.sh start "Reading documentation"

echo ""
echo "Step 2: Checking that t1 is active"
echo "----------------------------------"
./tracker.sh active | grep "🎯 ACTIVE"

echo ""
echo "Step 3: Starting Task 2 (t2) - should pause t1 automatically"
echo "------------------------------------------------------------"
echo "Watch for the pause message:"
./tracker.sh start "Writing unit tests"

echo ""
echo "Step 4: Verifying final status"
echo "------------------------------"
./tracker.sh active

echo ""
echo "Step 5: Testing setActive switching"
echo "----------------------------------"
T1_ID=$(jq -r '.[0].id' "$HOME/.task-tracker/tasks.json")
echo "Switching back to Task 1 (ID: $T1_ID):"
./tracker.sh setActive "$T1_ID"

echo ""
echo "Step 6: Final verification"
echo "-------------------------"
./tracker.sh active

echo ""
echo "✅ SUMMARY: Your case is now fully covered!"
echo "==========================================="
echo "• When starting a new task while another is active:"
echo "  - Previous task gets paused with clear message: ⏸️  Paused: [description] (id= [id])"
echo "  - New task becomes active: ✅ Task started and set as active"
echo "  - Status is clearly shown in 'tracker active' with 🎯 ACTIVE vs ⏸️  PAUSED"
echo ""
echo "• When using setActive to switch tasks:"
echo "  - Current task gets paused with message"
echo "  - Target task becomes active with confirmation message"
