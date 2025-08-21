#!/bin/bash
FILE="$HOME/.task-tracker/tasks.json"
TMP="$HOME/.task-tracker/tmp_task.json"
ACTIVE_FILE="$HOME/.task-tracker/active_task.txt"

# macOS compatibility: use gdate if available, fallback to BSD date
if command -v gdate &> /dev/null; then
  DATE_CMD="gdate"
else
  DATE_CMD="date"
fi
# Use shasum for macOS
SHASUM_CMD="shasum"

# Check for jq
if ! command -v jq &> /dev/null; then
  echo "jq is required. Install with: brew install jq"
  exit 1
fi

init_tracker() {
  if [ ! -d "$HOME/.task-tracker" ]; then
    mkdir -p "$HOME/.task-tracker"
    echo "📁 Created directory: $HOME/.task-tracker"
  fi
  if [ ! -f "$FILE" ]; then
    echo "[]" > "$FILE"
    echo "📄 Initialized tasks file: $FILE"
  fi
  if [ ! -f "$ACTIVE_FILE" ]; then
    echo "" > "$ACTIVE_FILE"
  fi
}

init_tracker

generate_id() {
  echo $($DATE_CMD +%s%N | $SHASUM_CMD | cut -c1-8)
}

get_active_task() {
  cat "$ACTIVE_FILE" 2>/dev/null || echo ""
}

pause_current_active() {
  CURRENT_ACTIVE=$(get_active_task)
  if [ -n "$CURRENT_ACTIVE" ]; then
    PAUSE_TIME=$($DATE_CMD '+%Y-%m-%d %H:%M:%S')
    PAUSED_TASK_DESC=$(jq -r --arg id "$CURRENT_ACTIVE" '.[] | select(.id==$id) | .start_desc' "$FILE")
    jq --arg id "$CURRENT_ACTIVE" --arg pause "$PAUSE_TIME" \
      'map(if .id == $id then .pause_time = $pause else . end)' \
      "$FILE" > "$TMP" && mv "$TMP" "$FILE"
    echo "⏸️  Paused: $PAUSED_TASK_DESC (id= $CURRENT_ACTIVE)"
    return 0
  fi
  return 1
}

resume_task() {
  ID="$1"
  RESUME_TIME=$($DATE_CMD '+%Y-%m-%d %H:%M:%S')
  TASK_DATA=$(jq -r --arg id "$ID" '.[] | select(.id==$id)' "$FILE")
  PAUSE_TIME=$(echo "$TASK_DATA" | jq -r '.pause_time // empty')
  TOTAL_PAUSED=$(echo "$TASK_DATA" | jq -r '.total_paused_seconds // 0')
  if [ -n "$PAUSE_TIME" ] && [ "$PAUSE_TIME" != "null" ]; then
    # Try gdate first, fallback to BSD date
    PAUSE_EPOCH=$($DATE_CMD -j -f "%Y-%m-%d %H:%M:%S" "$PAUSE_TIME" +%s 2>/dev/null || $DATE_CMD -d "$PAUSE_TIME" +%s)
    RESUME_EPOCH=$($DATE_CMD -j -f "%Y-%m-%d %H:%M:%S" "$RESUME_TIME" +%s 2>/dev/null || $DATE_CMD -d "$RESUME_TIME" +%s)
    PAUSED_DURATION=$((RESUME_EPOCH - PAUSE_EPOCH))
    NEW_TOTAL_PAUSED=$((TOTAL_PAUSED + PAUSED_DURATION))
    jq --arg id "$ID" --arg total_paused "$NEW_TOTAL_PAUSED" \
      'map(if .id == $id then .total_paused_seconds = ($total_paused | tonumber) | .pause_time = null else . end)' \
      "$FILE" > "$TMP" && mv "$TMP" "$FILE"
  fi
}

calculate_working_duration() {
  START="$1"
  END="$2"
  TOTAL_PAUSED="$3"
  START_EPOCH=$($DATE_CMD -j -f "%Y-%m-%d %H:%M:%S" "$START" +%s 2>/dev/null || $DATE_CMD -d "$START" +%s)
  END_EPOCH=$($DATE_CMD -j -f "%Y-%m-%d %H:%M:%S" "$END" +%s 2>/dev/null || $DATE_CMD -d "$END" +%s)
  TOTAL_ELAPSED=$((END_EPOCH - START_EPOCH))
  WORKING_TIME=$((TOTAL_ELAPSED - TOTAL_PAUSED))
  if [ $WORKING_TIME -lt 0 ]; then
    WORKING_TIME=0
  fi
  HOURS=$((WORKING_TIME / 3600))
  MINS=$(( (WORKING_TIME % 3600) / 60 ))
  SECS=$((WORKING_TIME % 60))
  if [ $HOURS -gt 0 ]; then
    if [ $SECS -gt 0 ]; then
      echo "${HOURS}h ${MINS}m ${SECS}s"
    else
      echo "${HOURS}h ${MINS}m"
    fi
  elif [ $MINS -gt 0 ]; then
    if [ $SECS -gt 0 ]; then
      echo "${MINS}m ${SECS}s"
    else
      echo "${MINS}m"
    fi
  else
    echo "${SECS}s"
  fi
}

# ...existing code...
# (Copy all other functions and case statement from tracker.sh, replacing date/sha1sum as above)
