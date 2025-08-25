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
  # Generate readable ID format: DDMMtXX (e.g., 2408t01)
  TODAY=$($DATE_CMD '+%d%m')
  
  # Count existing tasks for today to get next sequence number
  EXISTING_COUNT=$(jq --arg today "$TODAY" '[.[] | select(.id | startswith($today + "t"))] | length' "$FILE" 2>/dev/null || echo "0")
  NEXT_NUM=$(printf "%02d" $((EXISTING_COUNT + 1)))
  
  echo "${TODAY}t${NEXT_NUM}"
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

start_task() {
  ID=$(generate_id)
  START=$($DATE_CMD '+%Y-%m-%d %H:%M:%S')
  
  # Check if JSON file is valid
  if ! jq empty "$FILE" 2>/dev/null; then
    echo "⚠️  JSON file corrupted, reinitializing..."
    echo "[]" > "$FILE"
  fi
  
  # Pause any currently active task and show message
  pause_current_active
  
  jq --arg id "$ID" --arg start "$START" --arg desc "$1" \
    '. += [{"id": $id, "start": $start, "end": null, "start_desc": $desc, "end_desc": null, "details": null, "links": [], "duration": null, "pause_time": null, "total_paused_seconds": 0}]' \
    "$FILE" > "$TMP" && mv "$TMP" "$FILE"
  
  # Set this task as active
  echo "$ID" > "$ACTIVE_FILE"
  echo "✅ Task started and set as active: $1 id= $ID"
}

set_active_task() {
  ID="$1"
  
  # Check if task ID is provided
  if [ -z "$ID" ]; then
    echo "❌ Task ID is required. Usage: tracker setActive <id>"
    exit 1
  fi

  # Check if task exists and is not finished
  TASK_DATA=$(jq -r --arg id "$ID" '.[] | select(.id==$id)' "$FILE")
  if [ -z "$TASK_DATA" ]; then
    echo "❌ Task id= $ID not found."
    exit 1
  fi
  
  TASK_END=$(echo "$TASK_DATA" | jq -r '.end // empty')
  if [ -n "$TASK_END" ] && [ "$TASK_END" != "null" ]; then
    echo "❌ Cannot set finished task as active."
    exit 1
  fi
  
  # Pause current active task if any and show message
  pause_current_active
  
  # Resume the new active task
  resume_task "$ID"
  
  # Set new active task
  echo "$ID" > "$ACTIVE_FILE"
  
  TASK_DESC=$(echo "$TASK_DATA" | jq -r '.start_desc')
  echo "🎯 Task id= $ID is now active: $TASK_DESC"
}

finish_task() {
  ID="$1"
  END=$($DATE_CMD '+%Y-%m-%d %H:%M:%S')
  DESC="$2"

  # Check if task ID is provided
  if [ -z "$ID" ]; then
    echo "❌ Task ID is required. Usage: tracker finish <id> <description>"
    exit 1
  fi

  # Check if description is provided
  if [ -z "$DESC" ]; then
    echo "❌ Description is required. Usage: tracker finish <id> <description>"
    exit 1
  fi

  TASK_DATA=$(jq -r --arg id "$ID" '.[] | select(.id==$id)' "$FILE")
  if [ -z "$TASK_DATA" ]; then
    echo "❌ Task id= $ID not found."
    exit 1
  fi

  START=$(echo "$TASK_DATA" | jq -r '.start')
  TOTAL_PAUSED=$(echo "$TASK_DATA" | jq -r '.total_paused_seconds // 0')
  
  # If this task is currently active and paused, add final pause duration
  CURRENT_ACTIVE=$(get_active_task)
  if [ "$CURRENT_ACTIVE" = "$ID" ]; then
    PAUSE_TIME=$(echo "$TASK_DATA" | jq -r '.pause_time // empty')
    if [ -n "$PAUSE_TIME" ] && [ "$PAUSE_TIME" != "null" ]; then
      PAUSE_EPOCH=$($DATE_CMD -j -f "%Y-%m-%d %H:%M:%S" "$PAUSE_TIME" +%s 2>/dev/null || $DATE_CMD -d "$PAUSE_TIME" +%s)
      END_EPOCH=$($DATE_CMD -j -f "%Y-%m-%d %H:%M:%S" "$END" +%s 2>/dev/null || $DATE_CMD -d "$END" +%s)
      FINAL_PAUSE=$((END_EPOCH - PAUSE_EPOCH))
      TOTAL_PAUSED=$((TOTAL_PAUSED + FINAL_PAUSE))
    fi
    # Clear active task
    echo "" > "$ACTIVE_FILE"
  fi

  DURATION=$(calculate_working_duration "$START" "$END" "$TOTAL_PAUSED")

  jq --arg id "$ID" --arg end "$END" --arg desc "$DESC" --arg dur "$DURATION" --arg total_paused "$TOTAL_PAUSED" \
    'map(if .id == $id then .end=$end | .end_desc=$desc | .duration=$dur | .total_paused_seconds=($total_paused | tonumber) | .pause_time=null else . end)' \
    "$FILE" > "$TMP" && mv "$TMP" "$FILE"
  echo "🏁 Task id= $ID finished: $DESC (Working Duration: $DURATION)"
}

add_link() {
  ID="$1"
  LINK="$2"
  
  # Check if task ID is provided
  if [ -z "$ID" ]; then
    echo "❌ Task ID is required. Usage: tracker link <id> <url>"
    exit 1
  fi

  # Check if link is provided
  if [ -z "$LINK" ]; then
    echo "❌ Link is required. Usage: tracker link <id> <url>"
    exit 1
  fi

  # Check if task exists
  TASK_EXISTS=$(jq -r --arg id "$ID" '.[] | select(.id==$id) | .id' "$FILE")
  if [ -z "$TASK_EXISTS" ]; then
    echo "❌ Task id= $ID not found."
    exit 1
  fi

  jq --arg id "$ID" --arg link "$LINK" \
    'map(if .id == $id then .links += [$link] else . end)' \
    "$FILE" > "$TMP" && mv "$TMP" "$FILE"
  echo "🔗 Link added to task id= $ID: $LINK"
}

add_details() {
  ID="$1"
  shift
  DETAILS="$*"
  
  # Check if task ID is provided
  if [ -z "$ID" ]; then
    echo "❌ Task ID is required. Usage: tracker details <id> <details>"
    exit 1
  fi

  # Check if details are provided
  if [ -z "$DETAILS" ]; then
    echo "❌ Details are required. Usage: tracker details <id> <details>"
    exit 1
  fi

  # Check if task exists
  TASK_EXISTS=$(jq -r --arg id "$ID" '.[] | select(.id==$id) | .id' "$FILE")
  if [ -z "$TASK_EXISTS" ]; then
    echo "❌ Task id= $ID not found."
    exit 1
  fi

  # Get existing details
  EXISTING_DETAILS=$(jq -r --arg id "$ID" '.[] | select(.id==$id) | .details // ""' "$FILE")
  
  # Append new details to existing ones
  if [ -n "$EXISTING_DETAILS" ] && [ "$EXISTING_DETAILS" != "null" ]; then
    COMBINED_DETAILS="$EXISTING_DETAILS; $DETAILS"
  else
    COMBINED_DETAILS="$DETAILS"
  fi

  jq --arg id "$ID" --arg details "$COMBINED_DETAILS" \
    'map(if .id == $id then .details = $details else . end)' \
    "$FILE" > "$TMP" && mv "$TMP" "$FILE"
  echo "📝 Details appended to task id= $ID: $DETAILS"
}

show_tasks() {
  jq '.' "$FILE"
}

list_active() {
  echo "🔄 Active Tasks (not finished)"
  echo "------------------------------------"
  CURRENT_ACTIVE=$(get_active_task)
  
  jq --arg active_id "$CURRENT_ACTIVE" '
    map(select(.end == null)) 
    | map({
        id: .id, 
        started: .start, 
        task: .start_desc,
        status: (if .id == $active_id then "🎯 ACTIVE" else "⏸️  PAUSED" end)
      })
  ' "$FILE"
  
  if [ -n "$CURRENT_ACTIVE" ]; then
    echo ""
    echo "🎯 Currently focused on: $CURRENT_ACTIVE"
  else
    echo ""
    echo "⏸️  No task currently active"
  fi
}

daily_summary() {
  DATE="$1"
  if [ -z "$DATE" ]; then
    DATE=$($DATE_CMD '+%Y-%m-%d')
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

export_log() {
  FORMAT="$1"
  START_DATE="$2"
  END_DATE="$3"
  OUTPUT_FILE="$4"

  # Set default format to CSV if not specified
  if [ -z "$FORMAT" ]; then
    FORMAT="csv"
  fi

  # Handle single date parameter for daily reports
  if [ -n "$START_DATE" ] && [ -z "$END_DATE" ]; then
    # If only one date is provided, use it for both start and end (daily report)
    END_DATE="$START_DATE"
  elif [ -z "$START_DATE" ]; then
    # Set default date range (last 30 days if not specified)
    START_DATE=$($DATE_CMD -j -v-30d +%Y-%m-%d 2>/dev/null || $DATE_CMD -d '30 days ago' '+%Y-%m-%d')
    END_DATE=$($DATE_CMD '+%Y-%m-%d')
  elif [ -z "$END_DATE" ]; then
    # If start date provided but no end date, default end date to today
    END_DATE=$($DATE_CMD '+%Y-%m-%d')
  fi

  # Set default output file
  if [ -z "$OUTPUT_FILE" ]; then
    if [ "$START_DATE" = "$END_DATE" ]; then
      # Single day report
      if [ "$FORMAT" = "csv" ]; then
        OUTPUT_FILE="my_daily_report_${START_DATE}.csv"
      else
        OUTPUT_FILE="my_daily_report_${START_DATE}.json"
      fi
    else
      # Multi-day report
      if [ "$FORMAT" = "csv" ]; then
        OUTPUT_FILE="my_task_report_${START_DATE}_to_${END_DATE}.csv"
      else
        OUTPUT_FILE="my_task_report_${START_DATE}_to_${END_DATE}.json"
      fi
    fi
  fi

  # Create export directory if it doesn't exist
  EXPORT_DIR="$HOME/task-reports"
  mkdir -p "$EXPORT_DIR"
  FULL_OUTPUT_PATH="$EXPORT_DIR/$OUTPUT_FILE"

  echo "📤 Exporting tasks from $START_DATE to $END_DATE in $FORMAT format..."

  if [ "$FORMAT" = "csv" ]; then
    # CSV Export - Clean and simple format for sharing
    echo "Date,Start Time,End Time,Duration,Task Description,What Was Learned,Status" > "$FULL_OUTPUT_PATH"
    
    jq -r --arg start "$START_DATE" --arg end "$END_DATE" '
      map(select(.start >= $start and .start <= ($end + " 23:59:59"))) 
      | .[]
      | [
          (.start | split(" ")[0]),
          (.start | split(" ")[1]),
          (if .end then (.end | split(" ")[1]) else "In Progress" end),
          (if .duration then .duration else "In Progress" end),
          .start_desc,
          (if .end_desc then .end_desc else "Not completed" end),
          (if .end then "Completed" else "In Progress" end)
        ] | @csv
    ' "$FILE" >> "$FULL_OUTPUT_PATH"

    echo "✅ CSV report exported to: $FULL_OUTPUT_PATH"
    echo "📊 Report Summary:"
    TOTAL_TASKS=$(jq --arg start "$START_DATE" --arg end "$END_DATE" 'map(select(.start >= $start and .start <= ($end + " 23:59:59"))) | length' "$FILE")
    COMPLETED_TASKS=$(jq --arg start "$START_DATE" --arg end "$END_DATE" 'map(select(.start >= $start and .start <= ($end + " 23:59:59") and .end != null)) | length' "$FILE")
    echo "   📋 Total tasks: $TOTAL_TASKS"
    echo "   ✅ Completed: $COMPLETED_TASKS"
    echo "   🔄 In progress: $((TOTAL_TASKS - COMPLETED_TASKS))"

  elif [ "$FORMAT" = "json" ]; then
    # JSON Export - Complete detailed export with all fields
    jq --arg start "$START_DATE" --arg end "$END_DATE" '
      {
        "export_info": {
          "date_range": {
            "start": $start,
            "end": $end
          },
          "exported_at": now | strftime("%Y-%m-%d %H:%M:%S"),
          "total_tasks": (map(select(.start >= $start and .start <= ($end + " 23:59:59"))) | length)
        },
        "tasks": map(select(.start >= $start and .start <= ($end + " 23:59:59"))) 
        | map({
            id: .id,
            date: (.start | split(" ")[0]),
            start_time: (.start | split(" ")[1]),
            end_time: (if .end then (.end | split(" ")[1]) else null end),
            duration: .duration,
            task_description: .start_desc,
            what_learned: .end_desc,
            details: (if .details then (.details | gsub("\\n"; "\n") | split(";") | map(split("\n")) | flatten | map(select(length > 0) | ltrimstr(" ") | rtrimstr(" ")) | join("\n")) else null end),
            links: .links,
            status: (if .end then "completed" else "in_progress" end),
            total_paused_minutes: (if .total_paused_seconds then (.total_paused_seconds / 60 | floor) else 0 end)
          })
      }
    ' "$FILE" > "$FULL_OUTPUT_PATH"

    echo "✅ JSON report exported to: $FULL_OUTPUT_PATH"
    echo "📊 Report Summary:"
    TOTAL_TASKS=$(jq '.export_info.total_tasks' "$FULL_OUTPUT_PATH")
    COMPLETED_TASKS=$(jq '.tasks | map(select(.status == "completed")) | length' "$FULL_OUTPUT_PATH")
    echo "   📋 Total tasks: $TOTAL_TASKS"
    echo "   ✅ Completed: $COMPLETED_TASKS"
    echo "   🔄 In progress: $((TOTAL_TASKS - COMPLETED_TASKS))"

  else
    echo "❌ Unsupported format: $FORMAT. Use 'csv' or 'json'"
    exit 1
  fi

  echo ""
  echo "💡 For sharing or review:"
  echo "   📁 File location: $FULL_OUTPUT_PATH"
  if [ "$FORMAT" = "csv" ]; then
    echo "   📊 Open with: Excel, Google Sheets, or any spreadsheet app"
  else
    echo "   📄 Open with: Any text editor or JSON viewer"
  fi
}

helper_log() {
  echo "📖 Productivity Tracker Helper"
  echo "------------------------------------"
  echo "Usage:"
  echo "  tracker start <desc>"
  echo "     → Start a new task and set it as active"
  echo "     Example: tracker start \"Read RabbitMQ docs\""
  echo
  echo "  tracker setActive <id>"
  echo "     → Set an existing task as active (pauses current active task)"
  echo "     Example: tracker setActive 2408t01"
  echo
  echo "  tracker finish <id> <desc>"
  echo "     → Finish a task and record what you learned"
  echo "     Example: tracker finish 2408t01 \"Learned basics\""
  echo
  echo "  tracker link <id> <url>"
  echo "     → Add a link/resource to a task"
  echo "     Example: tracker link 2408t01 https://www.rabbitmq.com/tutorials/"
  echo
  echo "  tracker details <id> <details>"
  echo "     → Add detailed notes to a task (use ';' or newlines for line breaks in JSON)"
  echo "     Example: tracker details 2408t01 \"Key insight; Important finding; Next steps\""
  echo
  echo "  tracker show"
  echo "     → Show all tasks in JSON"
  echo
  echo "  tracker active"
  echo "     → Show only active (unfinished) tasks with focus status"
  echo
  echo "  tracker summary [date]"
  echo "     → Show daily summary (default: today)"
  echo "     Example: tracker summary 2025-08-20"
  echo
  echo "  tracker export [format] [start_date] [end_date] [filename]"
  echo "     → Export tasks for reporting (default: CSV, last 30 days)"
  echo "     Formats: csv, json"
  echo "     Example: tracker export csv 2025-08-20  (single day)"
  echo "     Example: tracker export csv 2025-08-01 2025-08-20  (date range)"
  echo "     Example: tracker export json 2025-08-20 \"\" my_daily.json  (custom filename)"
  echo
  echo "  tracker -h | help"
  echo "     → Show this helper log"
  echo ""
  echo "🎯 Focus Features:"
  echo "   • Only one task can be active at a time"
  echo "   • Switching tasks automatically pauses the current one"
  echo "   • Duration calculation excludes paused time"
  echo ""
  echo "📂 Data stored in: $HOME/.task-tracker/"
  echo "📤 Exports saved to: $HOME/task-reports/"
  echo "🔗 Installed at: $HOME/.task-tracker/tracker.sh"
  echo "------------------------------------"
}

case "$1" in
  start) shift; start_task "$*";;
  setActive) set_active_task "$2";;
  finish) finish_task "$2" "$3";;
  link) add_link "$2" "$3";;
  details) shift; add_details "$@";;
  show) show_tasks;;
  active) list_active;;
  summary) daily_summary "$2";;
  export) export_log "$2" "$3" "$4" "$5";;
  -h|help) helper_log;;
  *) echo "❌ Unknown command. Use -h for help.";;
esac
