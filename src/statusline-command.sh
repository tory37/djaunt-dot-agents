#!/bin/bash
# Claude Code status line: model | cwd | context % | git branch

input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name')
cwd=$(echo "$input" | jq -r '.workspace.current_dir')
dir_name=$(basename "$cwd")

used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
context_part=""
[ -n "$used_pct" ] && context_part=$(printf "ctx:%.0f%%" "$used_pct")

branch=""
if git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
  branch=$(git --no-optional-locks -C "$cwd" branch --show-current 2>/dev/null)
fi

# Colors (dimmed-friendly)
COLOR_MODEL='\033[2;36m'   # dim cyan
COLOR_DIR='\033[2;34m'     # dim blue
COLOR_CTX='\033[2;33m'     # dim yellow
COLOR_GIT='\033[2;32m'     # dim green
RESET='\033[0m'

line=$(printf "${COLOR_MODEL}%s${RESET} ${COLOR_DIR}%s${RESET}" "$model" "$dir_name")
[ -n "$context_part" ] && line="$line $(printf "${COLOR_CTX}%s${RESET}" "$context_part")"
[ -n "$branch" ] && line="$line $(printf "${COLOR_GIT}(%s)${RESET}" "$branch")"

printf "%s" "$line"
