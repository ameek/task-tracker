#!/bin/bash
# macOS compatible documentation test

echo "Checking for 'setActive' command:"
if ./tracker.sh help | grep -q "setActive"; then
    echo "✅ setActive command documented in help"
else
    echo "❌ setActive command missing from help"
fi

echo "Checking for focus features section:"
if ./tracker.sh help | grep -q "Focus Features"; then
    echo "✅ Focus features section found in help"
else
    echo "❌ Focus features section missing from help"
fi
