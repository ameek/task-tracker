#!/bin/bash
FILE="$HOME/.task-tracker/tasks.json"
TMP="$HOME/.task-tracker/tmp_task.json"

# Initialize directory and file if they don't exist
init_tracker() {
  if [ ! -d "$HOME/.task-tracker" ]; then
    mkdir -p "$HOME/.task-tracker"
    echo "📁 Created directory: $HOME/.task-tracker"
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
    '. += [{"id": $id, "start": $start, "end": null, "start_desc": $desc, "end_desc": null, "details": [], "links": [], "duration": null}]' \
    "$FILE" > "$TMP" && mv "$TMP" "$FILE"
  echo "✅ Task started: $1 (id=$ID)"
}

finish_task() {
  ID="$1"
  END=$(date '+%Y-%m-%d %H:%M:%S')
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
    'map(if .id == $id then .end=$end | .end_desc=$desc | .duration=$dur else . end)' \
    "$FILE" > "$TMP" && mv "$TMP" "$FILE"
  echo "🏁 Task $ID finished: $DESC (Duration: $DURATION)"
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
    echo "❌ Task $ID not found."
    exit 1
  fi

  jq --arg id "$ID" --arg link "$LINK" \
    'map(if .id == $id then .links += [$link] else . end)' \
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
    START_DATE=$(date -d '30 days ago' '+%Y-%m-%d')
    END_DATE=$(date '+%Y-%m-%d')
  elif [ -z "$END_DATE" ]; then
    # If start date provided but no end date, default end date to today
    END_DATE=$(date '+%Y-%m-%d')
  fi

  # Set default output file
  if [ -z "$OUTPUT_FILE" ]; then
    if [ "$START_DATE" = "$END_DATE" ]; then
      # Single day report
      if [ "$FORMAT" = "csv" ]; then
        OUTPUT_FILE="daily_report_${START_DATE}.csv"
      else
        OUTPUT_FILE="daily_report_${START_DATE}.json"
      fi
    else
      # Multi-day report
      if [ "$FORMAT" = "csv" ]; then
        OUTPUT_FILE="task_report_${START_DATE}_to_${END_DATE}.csv"
      else
        OUTPUT_FILE="task_report_${START_DATE}_to_${END_DATE}.json"
      fi
    fi
  fi

  # Create export directory if it doesn't exist
  EXPORT_DIR="$HOME/task-reports"
  mkdir -p "$EXPORT_DIR"
  FULL_OUTPUT_PATH="$EXPORT_DIR/$OUTPUT_FILE"

  echo "📤 Exporting tasks from $START_DATE to $END_DATE in $FORMAT format..."

  if [ "$FORMAT" = "csv" ]; then
    # CSV Export
    echo "Date,Start Time,End Time,Duration,Task Description,What Was Learned,Links,Status" > "$FULL_OUTPUT_PATH"
    
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
          (.links | join("; ")),
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
    # JSON Export
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
            links: .links,
            status: (if .end then "completed" else "in_progress" end)
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
  echo "💡 To share with your manager:"
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
  echo "     → Start a new task"
  echo "     Example: tracker start \"Read RabbitMQ docs\""
  echo
  echo "  tracker finish <id> <desc>"
  echo "     → Finish a task and record what you learned"
  echo "     Example: tracker finish a1f3b92d \"Learned basics\""
  echo
  echo "  tracker link <id> <url>"
  echo "     → Add a link/resource to a task"
  echo "     Example: tracker link a1f3b92d https://www.rabbitmq.com/tutorials/"
  echo
  echo "  tracker show"
  echo "     → Show all tasks in JSON"
  echo
  echo "  tracker active"
  echo "     → Show only active (unfinished) tasks"
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
  echo "📂 Data stored in: $HOME/.task-tracker/"
  echo "📤 Exports saved to: $HOME/task-reports/"
  echo "🔗 Installed at: $HOME/.task-tracker/tracker.sh"
  echo "------------------------------------"
}

case "$1" in
  start) shift; start_task "$*";;
  finish) finish_task "$2" "$3";;
  link) add_link "$2" "$3";;
  show) show_tasks;;
  active) list_active;;
  summary) daily_summary "$2";;
  export) export_log "$2" "$3" "$4" "$5";;
  -h|help) helper_log;;
  *) echo "❌ Unknown command. Use -h for help.";;
esac
