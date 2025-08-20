# 📊 Task Tracker

A simple, lightweight command-line productivity tracker that helps you monitor your daily tasks, time spent, and learning outcomes.

## ✨ Features

### 🚀 Task Management
- **Start Tasks**: Begin tracking a new task with a description
- **Finish Tasks**: Complete tasks and record what you learned
- **Active Tasks**: View all currently running (unfinished) tasks
- **Task History**: Show all tasks in detailed JSON format

### ⏱️ Time Tracking
- **Automatic Duration**: Calculates time spent on each task
- **Human-readable Format**: Displays duration in hours and minutes (e.g., "2h 15m")
- **Precise Timestamps**: Records exact start and end times

### 📚 Learning & Resources
- **Learning Notes**: Record what you learned when finishing a task
- **Resource Links**: Add URLs and references to tasks
- **Daily Summaries**: View all tasks completed on a specific date

### 📊 Reporting & Export
- **CSV Export**: Generate spreadsheet-friendly reports for managers
- **JSON Export**: Structured data export for technical analysis
- **Date Range Filtering**: Export specific time periods
- **Multiple Formats**: Choose between CSV (recommended for managers) or JSON
- **Automatic File Naming**: Smart default naming or custom filenames

### 🔧 Data Management
- **JSON Storage**: All data stored in simple JSON format
- **Data Portability**: Easy to backup, sync, or migrate
- **Auto-initialization**: Creates necessary files and directories automatically
- **Error Recovery**: Handles corrupted files gracefully

## 🛠️ Installation

### Quick Install
```bash
# Clone or download the repository
git clone <repository-url>
cd task-tracker

# Run the installer
chmod +x install-tracker.sh
./install-tracker.sh
```

### What the installer does:
1. ✅ Creates `~/.task-tracker/` directory
2. ✅ Installs the tracker script
3. ✅ Creates system-wide `tracker` command
4. ✅ Installs `jq` dependency if needed
5. ✅ Sets up proper permissions
6. ✅ Initializes data files

### Manual Installation
```bash
# Create directory
mkdir -p ~/.task-tracker

# Copy script
cp tracker.sh ~/.task-tracker/
chmod +x ~/.task-tracker/tracker.sh

# Create system-wide link
sudo ln -s ~/.task-tracker/tracker.sh /usr/local/bin/tracker

# Install jq (if not already installed)
sudo apt install jq  # Ubuntu/Debian
# or
sudo yum install jq   # CentOS/RHEL
# or
sudo pacman -S jq     # Arch Linux
```

## 📖 Usage

### Basic Commands

#### Start a new task
```bash
tracker start "Reading React documentation"
# Output: ✅ Task started: Reading React documentation (id=a1f3b92d)
```

#### Finish a task
```bash
tracker finish a1f3b92d "Learned about hooks and state management"
# Output: 🏁 Task a1f3b92d finished: Learned about hooks and state management (Duration: 1h 25m)
```

#### Add resources/links to a task
```bash
tracker link a1f3b92d "https://react.dev/learn"
# Output: 🔗 Link added to task a1f3b92d: https://react.dev/learn
```

#### View active tasks
```bash
tracker active
# Output: Shows all unfinished tasks with IDs and descriptions
```

#### View all tasks
```bash
tracker show
# Output: Complete JSON data of all tasks
```

#### Daily summary
```bash
tracker summary
# Output: Summary of today's tasks

tracker summary 2025-08-19
# Output: Summary for specific date
```

#### Export for reporting
```bash
tracker export
# Output: CSV report for last 30 days (default)

tracker export csv 2025-08-01 2025-08-20
# Output: CSV report for specific date range

tracker export json 2025-08-15 2025-08-20 "weekly_report.json"
# Output: Named JSON report for specific date range
```

#### Get help
```bash
tracker -h
# or
tracker help
```

## 📋 Command Reference

| Command | Description | Example |
|---------|-------------|---------|
| `tracker start <description>` | Start a new task | `tracker start "Code review"` |
| `tracker finish <id> <learned>` | Complete a task | `tracker finish abc123 "Fixed bug"` |
| `tracker link <id> <url>` | Add link to task | `tracker link abc123 "https://..."` |
| `tracker active` | Show unfinished tasks | `tracker active` |
| `tracker show` | Show all tasks (JSON) | `tracker show` |
| `tracker summary [date]` | Daily summary | `tracker summary 2025-08-20` |
| `tracker export [format] [start] [end] [file]` | Export for reporting | `tracker export csv 2025-08-01 2025-08-20` |
| `tracker help` | Show help | `tracker help` |

## 📁 File Structure

```
~/.task-tracker/
├── tracker.sh           # Main script
├── tasks.json           # Task data storage
└── tmp_task.json        # Temporary file for atomic updates

~/task-reports/
└── *.csv, *.json        # Exported reports for sharing
```

## 📊 Data Format

Tasks are stored in JSON format with the following structure:

```json
[
  {
    "id": "a1f3b92d",
    "start": "2025-08-20 09:30:00",
    "end": "2025-08-20 11:15:00",
    "duration": "1h 45m",
    "start_desc": "Reading React documentation",
    "end_desc": "Learned about hooks and state management",
    "links": [
      "https://react.dev/learn",
      "https://react.dev/reference/react"
    ]
  }
]
```

## 🔍 Examples

### Typical Workflow
```bash
# Start working on something
tracker start "Implementing user authentication"

# Check what you're working on
tracker active

# Add useful resources
tracker link a1f3b92d "https://auth0.com/docs"
tracker link a1f3b92d "https://jwt.io/introduction"

# Finish the task
tracker finish a1f3b92d "Successfully implemented JWT-based auth with refresh tokens"

# View today's progress
tracker summary

# Review all completed work
tracker show
```

### Daily Review
```bash
# See what you accomplished today
tracker summary

# Check yesterday's work
tracker summary 2025-08-19

# See all active tasks that need attention
tracker active
```

### Exporting for Manager Reports
```bash
# Quick daily report (CSV format - best for managers)
tracker export csv

# Today's report with single date
tracker export csv $(date +%Y-%m-%d)

# Specific day report  
tracker export csv 2025-08-20

# Weekly report with date range
tracker export csv 2025-08-14 2025-08-20

# Custom filename for daily report
tracker export csv 2025-08-20 "" "daily_standup_report.csv"

# Monthly report in JSON format for detailed analysis
tracker export json 2025-08-01 2025-08-31 "august_detailed_report.json"
```

**💡 Recommendation for Manager Reports:**
- **Use CSV format** - Opens directly in Excel/Google Sheets
- **Include date ranges** - Be specific about the reporting period
- **Use descriptive filenames** - Make it easy for your manager to understand
- The CSV includes: Date, Times, Duration, Task Description, Learning outcomes, Links, and Status
- **Files are saved to:** `~/task-reports/` (easy to find and share)

## ⚙️ Requirements

- **Operating System**: Linux, macOS, or WSL on Windows
- **Shell**: Bash (compatible with zsh)
- **Dependencies**: 
  - `jq` (JSON processor) - installed automatically by installer
  - `date` command with GNU date features
  - Standard Unix tools: `grep`, `sed`, `cut`, `sha1sum`

## 🔧 Configuration

### Data Location
- All data is stored in `~/.task-tracker/`
- To change location, edit the `FILE` and `TMP` variables in the script

### Backup Your Data
```bash
# Backup tasks
cp ~/.task-tracker/tasks.json ~/backup-tasks-$(date +%Y%m%d).json

# Restore from backup
cp ~/backup-tasks-20250820.json ~/.task-tracker/tasks.json
```

## 🚨 Troubleshooting

### Command not found
```bash
# Check if tracker is in PATH
which tracker

# Add to PATH if needed
echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### jq not found
```bash
# Install jq manually
sudo apt install jq        # Ubuntu/Debian
sudo yum install jq         # CentOS/RHEL
sudo dnf install jq         # Fedora
sudo pacman -S jq           # Arch Linux
brew install jq             # macOS
```

### Permission denied
```bash
# Fix permissions
chmod +x ~/.task-tracker/tracker.sh
sudo chmod +x /usr/local/bin/tracker
```

### Corrupted JSON file
The tracker automatically detects and fixes corrupted JSON files by reinitializing them with an empty array.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is open source. Feel free to use, modify, and distribute as needed.

## 💡 Tips

- Use descriptive task names for better tracking
- Add learning notes to build a knowledge base
- Include relevant links for future reference
- Review your daily summaries to track productivity patterns
- Keep task descriptions concise but informative

---

**Happy tracking! 📈✨**
