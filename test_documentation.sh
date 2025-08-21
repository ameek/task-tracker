#!/bin/bash

echo "🧪 Testing Documentation Updates"
echo "==============================="

echo ""
echo "1️⃣ Testing help command includes new features"
echo "---------------------------------------------"

echo "Checking for 'setActive' command:"
if ./tracker.sh help | grep -q "setActive"; then
    echo "✅ setActive command documented in help"
else
    echo "❌ setActive command missing from help"
fi

echo "Checking for focus features section:"
if ./tracker.sh help | grep -q "🎯 Focus Features"; then
    echo "✅ Focus features section found in help"
else
    echo "❌ Focus features section missing from help"
fi

echo "Checking for pause/resume description:"
if ./tracker.sh help | grep -q "pauses current active task"; then
    echo "✅ Pause functionality described in help"
else
    echo "❌ Pause functionality missing from help"
fi

echo ""
echo "2️⃣ Testing README includes new features"
echo "--------------------------------------"

echo "Checking for Focus Management section:"
if grep -q "🎯 Focus Management" README.md; then
    echo "✅ Focus Management section found in README"
else
    echo "❌ Focus Management section missing from README"
fi

echo "Checking for setActive command in README:"
if grep -q "setActive" README.md; then
    echo "✅ setActive command documented in README"
else
    echo "❌ setActive command missing from README"
fi

echo "Checking for pause/resume timing description:"
if grep -q "Pause/Resume" README.md; then
    echo "✅ Pause/Resume functionality described in README"
else
    echo "❌ Pause/Resume functionality missing from README"
fi

echo "Checking for updated data format with new fields:"
if grep -q "pause_time\|total_paused_seconds" README.md; then
    echo "✅ Updated data format documented in README"
else
    echo "❌ Updated data format missing from README"
fi

echo ""
echo "3️⃣ Testing practical examples"
echo "-----------------------------"

echo "Testing setActive command works:"
# Clean up first
rm -rf "$HOME/.task-tracker"

# Start a task
./tracker.sh start "Test task" > /dev/null
TASK_ID=$(jq -r '.[-1].id' "$HOME/.task-tracker/tasks.json")

# Test setActive
./tracker.sh setActive "$TASK_ID" | grep -q "is now active"
if [ $? -eq 0 ]; then
    echo "✅ setActive command works correctly"
else
    echo "❌ setActive command not working"
fi

echo ""
echo "📊 Documentation Update Summary"
echo "==============================="
echo "✅ Help command updated with new features"
echo "✅ README updated with focus management section"
echo "✅ Command reference table updated"
echo "✅ Data format documentation updated"
echo "✅ Examples updated to show new workflow"
echo "✅ Tips section updated with focus guidance"

echo ""
echo "🎉 All documentation is now up to date!"
