#!/bin/bash

# test-tracker.sh - Comprehensive test script for Task Tracker

echo "🧪 Task Tracker Comprehensive Test Suite"
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

# Test with output check
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
echo "🧹 Cleaning test environment..."
rm -rf ~/.task-tracker-test
mkdir -p ~/.task-tracker-test

# Copy tracker for isolated testing
cp ./tracker.sh ~/.task-tracker-test/
sed -i 's|\.task-tracker|.task-tracker-test|g' ~/.task-tracker-test/tracker.sh
chmod +x ~/.task-tracker-test/tracker.sh

TRACKER="$HOME/.task-tracker-test/tracker.sh"

echo ""
echo "📋 Running Tests..."
echo "==================="

# Test 1: Help command
test_output "Help command" "$TRACKER -h" "Usage:"

# Test 2: Starting a task
test_output "Start task" "$TRACKER start 'Test task 1'" "Task started"

# Test 3: Show active tasks
test_output "Show active tasks" "$TRACKER active" "Test task 1"

# Test 4: Add link to task
TASK_ID=$(jq -r '.[0].id' ~/.task-tracker-test/tasks.json)
test_output "Add link to task" "$TRACKER link $TASK_ID 'https://example.com'" "Link added"

# Test 5: Finish task
test_output "Finish task" "$TRACKER finish $TASK_ID 'Task completed'" "finished"

# Test 6: Show all tasks
test_output "Show all tasks" "$TRACKER show" "end_desc"

# Test 7: Daily summary
test_output "Daily summary" "$TRACKER summary" "Summary for"

# Test 8: Error handling - missing task ID for finish
test_command "Error: Missing task ID for finish" "$TRACKER finish" 1

# Test 9: Error handling - missing task ID for link
test_command "Error: Missing task ID for link" "$TRACKER link" 1

# Test 10: Error handling - nonexistent task
test_command "Error: Nonexistent task" "$TRACKER finish nonexistent 'test'" 1

# Test 11: JSON corruption recovery
echo "corrupted json" > ~/.task-tracker-test/tasks.json
test_output "JSON corruption recovery" "$TRACKER start 'Recovery test'" "Task started"

# Test 12: Multiple tasks workflow
test_output "Start second task" "$TRACKER start 'Task 2'" "Task started"
TASK2_ID=$(jq -r '.[-1].id' ~/.task-tracker-test/tasks.json)
test_output "Finish second task" "$TRACKER finish $TASK2_ID 'Done'" "finished"

# Test 13: Empty active tasks (all finished)
output=$($TRACKER active 2>&1)
if echo "$output" | grep -q "\[\]"; then
    echo "Testing: Empty active tasks... ✅ PASS"
    ((PASSED_TESTS++))
else
    echo "Testing: Empty active tasks... ❌ FAIL"
    ((FAILED_TESTS++))
fi

# Test 14: Date-specific summary
test_output "Date-specific summary" "$TRACKER summary 2025-08-20" "Summary for 2025-08-20"

# Test 15: Invalid command
test_command "Invalid command" "$TRACKER invalid_command" 0  # Should show help, not error

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
    echo "🧹 Cleaning up test files..."
    rm -rf ~/.task-tracker-test
    exit 0
else
    echo ""
    echo "⚠️  Some tests failed. Please review the issues above."
    echo "📁 Test files preserved in: ~/.task-tracker-test"
    exit 1
fi
