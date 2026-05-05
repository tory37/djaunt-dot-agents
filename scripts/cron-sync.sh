#!/usr/bin/env bash
# cron-sync.sh — Automated sync for use in crontab.
# Pulls latest changes and runs the sync script.

set -euo pipefail

REPO_ROOT="/home/toryhebert/src/djaunt-dot-agents"
LOG_FILE="$REPO_ROOT/.agents/logs/sync.log"

mkdir -p "$(dirname "$LOG_FILE")"

exec > >(awk '{ print strftime("[%Y-%m-%d %H:%M:%S]"), $0 }' >> "$LOG_FILE") 2>&1

echo "Starting automated sync..."

cd "$REPO_ROOT"

# Ensure we are on main
git checkout main

# Pull latest changes
if git pull origin main; then
    echo "Successfully pulled latest changes."
else
    echo "Error: Failed to pull changes. Check SSH keys or network."
    exit 1
fi

# Run the sync script
bash scripts/sync.sh

echo "Automated sync complete."
