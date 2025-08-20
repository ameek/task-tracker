#!/bin/bash
FILE="$HOME/prod-tracker/tasks.json"
TMP="$HOME/prod-tracker/tmp_task.json"

# Initialize directory and file if they don't exist
init_tracker() {
  if [ ! -d "$HOME/prod-tracker" ]; then
    mkdir -p "$HOME/prod-tracker"
    echo "📁 Created directory: $HOME/prod-tracker"
  fi
  
  if [ ! -f "$FILE" ]; then
    echo "[]" > "$FILE"
    echo "📄 Initialized tasks file: $FILE"
  fi
}

# Initialize on script start
init_tracker

generate_id() {
  # Short unique ID from current timestamp
  echo $(date +%s | sha1sum | cut -c1-8)
}

start_task() {
  ID=$(generate_id)
  START=$(date '+%Y-%m-%d %H:%M:%S')
  
  # Check if JSON file is valid
  if ! jq empty "$FILE" 2>/dev/null; then
    echo "⚠️  JSON file corrupted, reinitializing..."
    echo "[]" > "$FILE"
  fi
  
  jq --arg id "$ID" --arg start "$START" --arg desc "$1" \
    '. += [{"id": $id, "start": $start, "end": null, "start_desc": $desc, "end_desc": null, "links": [], "duration": null}]' \
    "$FILE" > "$TMP" && mv "$TMP" "$FILE"
  echo "✅ Task started: $1 (id=$ID)"
}

finish_task() {
  ID="$1"
  END=$(date '+%Y-%m-%d %H:%M:%S')
  DESC="$2"

  # Check if task ID is provided
  if [ -z "$ID" ]; then
    echo "❌ Task ID is required. Usage: ./tracker.sh finish <id> <description>"
    exit 1
  fi

  # Check if description is provided
  if [ -z "$DESC" ]; then
    echo "❌ Description is required. Usage: ./tracker.sh finish <id> <description>"
    exit 1
  fi

  START=$(jq -r --arg id "$ID" '.[] | select(.id==$id) | .start' "$FILE")
  if [ "$START" = "null" ] || [ -z "$START" ]; then
    echo "❌ Task $ID not found."
    exit 1
  fi

  START_EPOCH=$(date -d "$START" +%s)
  END_EPOCH=$(date -d "$END" +%s)
  DIFF=$((END_EPOCH - START_EPOCH))

  HOURS=$((DIFF / 3600))
  MINS=$(( (DIFF % 3600) / 60 ))
  if [ $HOURS -gt 0 ]; then
    DURATION="${HOURS}h ${MINS}m"
  else
    DURATION="${MINS}m"
  fi

  jq --arg id "$ID" --arg end "$END" --arg desc "$DESC" --arg dur "$DURATION" \
    'map(if .id == $id then .end=$end | .end_desc=$desc | .duration=$dur else . end) end' \
    "$FILE" > "$TMP" && mv "$TMP" "$FILE"
  echo "🏁 Task $ID finished: $DESC (Duration: $DURATION)"
}

add_link() {
  ID="$1"
  LINK="$2"
  
  # Check if task ID is provided
  if [ -z "$ID" ]; then
    echo "❌ Task ID is required. Usage: ./tracker.sh link <id> <url>"
    exit 1
  fi

  # Check if link is provided
  if [ -z "$LINK" ]; then
    echo "❌ Link is required. Usage: ./tracker.sh link <id> <url>"
    exit 1
  fi

  # Check if task exists
  TASK_EXISTS=$(jq -r --arg id "$ID" '.[] | select(.id==$id) | .id' "$FILE")
  if [ -z "$TASK_EXISTS" ]; then
    echo "❌ Task $ID not found."
    exit 1
  fi

  jq --arg id "$ID" --arg link "$LINK" \
    'map(if .id == $id then .links += [$link] else . end) end' \
    "$FILE" > "$TMP" && mv "$TMP" "$FILE"
  echo "🔗 Link added to task $ID: $LINK"
}

show_tasks() {
  jq '.' "$FILE"
}

list_active() {
  echo "🔄 Active Tasks (not finished)"
  echo "------------------------------------"
  jq 'map(select(.end == null)) | map({id: .id, started: .start, task: .start_desc})' "$FILE"
}

daily_summary() {
  DATE="$1"
  if [ -z "$DATE" ]; then
    DATE=$(date '+%Y-%m-%d')
  fi

  echo "📅 Summary for $DATE"
  echo "------------------------------------"
  jq --arg d "$DATE" '
    map(select(.start | startswith($d))) 
    | map({
        id: .id,
        start: .start,
        end: .end,
        duration: .duration,
        task: .start_desc,
        learned: .end_desc,
        links: .links
      })
  ' "$FILE"
}

helper_log() {
  echo "📖 Productivity Tracker Helper"
  echo "------------------------------------"
  echo "Usage:"
  echo "  ./tracker.sh start <desc>"
  echo "     → Start a new task"
  echo "     Example: ./tracker.sh start \"Read RabbitMQ docs\""
  echo
  echo "  ./tracker.sh finish <id> <desc>"
  echo "     → Finish a task and record what you learned"
  echo "     Example: ./tracker.sh finish a1f3b92d \"Learned basics\""
  echo
  echo "  ./tracker.sh link <id> <url>"
  echo "     → Add a link/resource to a task"
  echo "     Example: ./tracker.sh link a1f3b92d https://www.rabbitmq.com/tutorials/"
  echo
  echo "  ./tracker.sh show"
  echo "     → Show all tasks in JSON"
  echo
  echo "  ./tracker.sh active"
  echo "     → Show only active (unfinished) tasks"
  echo
  echo "  ./tracker.sh summary [date]"
  echo "     → Show daily summary (default: today)"
  echo "     Example: ./tracker.sh summary 2025-08-20"
  echo
  echo "  ./tracker.sh -h | help"
  echo "     → Show this helper log"
  echo "------------------------------------"
}

case "$1" in
  start) shift; start_task "$*";;
  finish) finish_task "$2" "$3";;
  link) add_link "$2" "$3";;
  show) show_tasks;;
  active) list_active;;
  summary) daily_summary "$2";;
  -h|help) helper_log;;
  *) echo "❌ Unknown command. Use -h for help.";;
esac
