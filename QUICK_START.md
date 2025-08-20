# 🚀 Task Tracker - Quick Start Guide

A simple, powerful command-line productivity tracker for developers and self-improvement enthusiasts.

## ⚡ Quick Installation

```bash
# 1. Download or clone this directory
# 2. Run the installer
chmod +x install-tracker.sh
./install-tracker.sh
```

## 🎯 Quick Usage

```bash
# Start tracking a task
tracker start "Working on authentication module"

# Add resources and notes
tracker link <task-id> "https://jwt.io/introduction"
tracker details <task-id> "Key insight; Important discovery; Next steps"

# Finish the task
tracker finish <task-id> "Successfully implemented JWT authentication"

# Export daily report for self-review
tracker export csv $(date +%Y-%m-%d)
```

## 📊 Key Features

- ✅ **Simple CLI interface** - Easy to use from anywhere
- ✅ **Time tracking** - Automatic duration calculation
- ✅ **Rich details** - Add links, notes, and learning outcomes
- ✅ **Export reports** - CSV for self-reviews, JSON for detailed analysis
- ✅ **Daily summaries** - Track your daily productivity
- ✅ **Self-improvement focused** - Perfect for personal development

## 📁 File Structure

```
task-tracker/
├── tracker.sh          # Main tracker script
├── install-tracker.sh  # Installation script
├── uninstall-tracker.sh # Uninstallation script
├── README.md           # Detailed documentation
└── QUICK_START.md      # This file
```

## 🔧 What Gets Installed

- **Script**: `~/.task-tracker/tracker.sh`
- **Data**: `~/.task-tracker/tasks.json`
- **Command**: `tracker` (system-wide access)
- **Exports**: `~/task-reports/` (CSV/JSON reports)

## 🗑️ Uninstallation

```bash
./uninstall-tracker.sh
```

Choose whether to keep or remove your task data.

## 📈 Example Workflow

```bash
# Start your day
tracker start "Morning standup preparation"
tracker finish abc123 "Prepared agenda and status update"

# Work session
tracker start "Database optimization task"
tracker link def456 "https://postgresql.org/docs/performance"
tracker details def456 "Found slow query; Added index; 50% faster"
tracker finish def456 "Query optimization completed successfully"

# Export for self-review
tracker export csv $(date +%Y-%m-%d)
# Creates: ~/task-reports/my_daily_report_2025-08-20.csv
```

## 📋 Report Format

**CSV (Self-Review-friendly):**
- Date, Start Time, End Time, Duration
- Task Description, What Was Learned, Status
- Clean, opens in Excel/Google Sheets

**JSON (Detailed):**
- All fields including links and detailed notes
- Perfect for personal analysis and review

## 🆘 Need Help?

```bash
tracker help  # Full command reference
```

Or check the detailed `README.md` for complete documentation.

---

**Happy tracking! 📊✨**
