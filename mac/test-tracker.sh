#!/bin/bash

# test-tracker.sh - Comprehensive test script for Task Tracker (macOS compatible)

echo "🧪 Task Tracker Comprehensive Test Suite (macOS)"
echo "========================================"

FAILED_TESTS=0
PASSED_TESTS=0

# Test function
test_command() {
    local description="$1"
    local command="$2"
    local expected_exit_code="${3:-0}"
    echo -n "Testing: $description... "
    eval "$command" >/dev/null 2>&1
    actual_exit_code=$?
    if [ "$actual_exit_code" -eq "$expected_exit_code" ]; then
        echo "✅ PASS"
        ((PASSED_TESTS++))
    else
        echo "❌ FAIL (expected exit code $expected_exit_code, got $actual_exit_code)"
        ((FAILED_TESTS++))
    fi
}

test_output() {
    local description="$1"
    local command="$2"
    local expected_pattern="$3"
    echo -n "Testing: $description... "
    output=$(eval "$command" 2>&1)
    if echo "$output" | grep -q "$expected_pattern"; then
        echo "✅ PASS"
        ((PASSED_TESTS++))
    else
        echo "❌ FAIL (pattern '$expected_pattern' not found)"
        echo "   Output: $output"
        ((FAILED_TESTS++))
    fi
}

# Clean environment for testing
rm -rf ~/.task-tracker-test
mkdir -p ~/.task-tracker-test
cp ./tracker.sh ~/.task-tracker-test/
sed -i '' 's|\.task-tracker|.task-tracker-test|g' ~/.task-tracker-test/tracker.sh
chmod +x ~/.task-tracker-test/tracker.sh

TRACKER="$HOME/.task-tracker-test/tracker.sh"

echo ""
echo "📋 Running Tests..."
echo "==================="

test_output "Help command" "$TRACKER -h" "Usage:"
test_output "Start task" "$TRACKER start 'Test task 1'" "Task started"
test_output "Show active tasks" "$TRACKER active" "Test task 1"
TASK_ID=$(jq -r '.[0].id' ~/.task-tracker-test/tasks.json)
test_output "Add link to task" "$TRACKER link $TASK_ID 'https://example.com'" "Link added"
test_output "Finish task" "$TRACKER finish $TASK_ID 'Task completed'" "finished"
test_output "Show all tasks" "$TRACKER show" "end_desc"
test_output "Daily summary" "$TRACKER summary" "Summary for"
test_command "Error: Missing task ID for finish" "$TRACKER finish" 1
test_command "Error: Missing task ID for link" "$TRACKER link" 1
test_command "Error: Nonexistent task" "$TRACKER finish nonexistent 'test'" 1
echo "corrupted json" > ~/.task-tracker-test/tasks.json
test_output "JSON corruption recovery" "$TRACKER start 'Recovery test'" "Task started"
test_output "Start second task" "$TRACKER start 'Task 2'" "Task started"
TASK2_ID=$(jq -r '.[-1].id' ~/.task-tracker-test/tasks.json)
test_output "Finish second task" "$TRACKER finish $TASK2_ID 'Done'" "finished"
output=$($TRACKER active 2>&1)
if echo "$output" | grep -q "\[\]"; then
    echo "Testing: Empty active tasks... ✅ PASS"
    ((PASSED_TESTS++))
else
    echo "Testing: Empty active tasks... ❌ FAIL"
    ((FAILED_TESTS++))
fi
test_output "Date-specific summary" "$TRACKER summary 2025-08-20" "Summary for 2025-08-20"
test_command "Invalid command" "$TRACKER invalid_command" 0

echo ""
echo "📊 Test Results:"
echo "================"
echo "✅ Passed: $PASSED_TESTS"
echo "❌ Failed: $FAILED_TESTS"
echo "📈 Total:  $((PASSED_TESTS + FAILED_TESTS))"

if [ $FAILED_TESTS -eq 0 ]; then
    echo ""
    echo "🎉 All tests passed! The tracker is working correctly."
    echo ""
    rm -rf ~/.task-tracker-test
    exit 0
else
    echo ""
    echo "⚠️  Some tests failed. Please review the issues above."
    echo "📁 Test files preserved in: ~/.task-tracker-test"
    exit 1
fi
