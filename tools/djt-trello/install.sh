#!/bin/bash

# install.sh - Generic Trello Toolset Installer for Gemini CLI Projects
# Usage: ./install.sh --target /path/to/project [--prefix custom]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default values
PREFIX="djt"
TARGET=""

# Trello Variables
TRELLO_API_KEY=""
TRELLO_TOKEN=""
TRELLO_BOARD_ID=""
TRELLO_LIST_BUGS=""
TRELLO_LIST_TECHDEBT=""
TRELLO_LIST_BACKLOG=""
TRELLO_LIST_DOING=""

show_help() {
  echo "Usage: $0 --target <project_path> [options]"
  echo ""
  echo "Options:"
  echo "  --target       Path to the target project root (required)"
  echo "  --prefix       Prefix for the skills (default: djt)"
  echo "  --api-key      Trello API Key"
  echo "  --token        Trello Token"
  echo "  --board        Trello Board ID"
  echo "  --list-bugs    Trello List ID for BUGS"
  echo "  --list-tech    Trello List ID for TECH DEBT"
  echo "  --list-backlog Trello List ID for BACKLOG"
  echo "  --list-doing   Trello List ID for DOING"
  echo "  --help         Show this help message"
}

# Parse arguments
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --target) TARGET="$2"; shift ;;
    --prefix) PREFIX="$2"; shift ;;
    --api-key) TRELLO_API_KEY="$2"; shift ;;
    --token) TRELLO_TOKEN="$2"; shift ;;
    --board) TRELLO_BOARD_ID="$2"; shift ;;
    --list-bugs) TRELLO_LIST_BUGS="$2"; shift ;;
    --list-tech) TRELLO_LIST_TECHDEBT="$2"; shift ;;
    --list-backlog) TRELLO_LIST_BACKLOG="$2"; shift ;;
    --list-doing) TRELLO_LIST_DOING="$2"; shift ;;
    --help) show_help; exit 0 ;;
    *) echo "Unknown parameter passed: $1"; show_help; exit 1 ;;
  esac
  shift
done

if [ -z "$TARGET" ]; then
  echo "Error: --target is required."
  show_help
  exit 1
fi

# Function to prompt for a variable if empty
prompt_var() {
  local var_name=$1
  local prompt_text=$2
  local current_val=${!var_name}
  
  if [ -z "$current_val" ]; then
    # Only prompt if we are in an interactive terminal
    if [ -t 0 ]; then
      read -p "$prompt_text: " input_val
      eval "$var_name=\"$input_val\""
    else
      echo "Error: $prompt_text (--${var_name,,/_/-}) is required in non-interactive mode."
      exit 1
    fi
  fi
}

echo "--- Trello Toolset Installation ---"
prompt_var "TRELLO_API_KEY" "Trello API Key"
prompt_var "TRELLO_TOKEN" "Trello Token"
prompt_var "TRELLO_BOARD_ID" "Trello Board ID (8-char short ID or full ID)"
prompt_var "TRELLO_LIST_BUGS" "List ID for BUGS"
prompt_var "TRELLO_LIST_TECHDEBT" "List ID for TECH DEBT"
prompt_var "TRELLO_LIST_BACKLOG" "List ID for BACKLOG"
prompt_var "TRELLO_LIST_DOING" "List ID for DOING"

# Create target directories
SKILL_TRELLO_DIR="$TARGET/.agents/skills/${PREFIX}-trello"
MCP_DIR="$TARGET/.agents/mcp"

mkdir -p "$SKILL_TRELLO_DIR"
mkdir -p "$MCP_DIR"

# Paths to prompt templates (resolved relative to this script)
BUG_TEMPLATE_PATH="$SCRIPT_DIR/../../skills/djt-bug/template.md"
FEATURE_TEMPLATE_PATH="$SCRIPT_DIR/../../skills/djt-feature/template.md"

# Internal function for template replacement (supports multi-line {{BUG_TEMPLATE}} / {{FEATURE_TEMPLATE}} injection)
expand_template() {
  local src=$1
  local dest=$2

  python3 << PYEOF
import os

content = open("$src").read()

subs = {
    "{{PREFIX}}":              "$PREFIX",
    "{{TRELLO_API_KEY}}":      "$TRELLO_API_KEY",
    "{{TRELLO_TOKEN}}":        "$TRELLO_TOKEN",
    "{{TRELLO_BOARD_ID}}":     "$TRELLO_BOARD_ID",
    "{{TRELLO_LIST_BUGS}}":    "$TRELLO_LIST_BUGS",
    "{{TRELLO_LIST_TECHDEBT}}":"$TRELLO_LIST_TECHDEBT",
    "{{TRELLO_LIST_BACKLOG}}": "$TRELLO_LIST_BACKLOG",
    "{{TRELLO_LIST_DOING}}":   "$TRELLO_LIST_DOING",
    "{{BUG_TEMPLATE}}":        open("$BUG_TEMPLATE_PATH").read() if os.path.exists("$BUG_TEMPLATE_PATH") else "{{BUG_TEMPLATE}}",
    "{{FEATURE_TEMPLATE}}":    open("$FEATURE_TEMPLATE_PATH").read() if os.path.exists("$FEATURE_TEMPLATE_PATH") else "{{FEATURE_TEMPLATE}}",
}

for key, val in subs.items():
    content = content.replace(key, val)

open("$dest", "w").write(content)
PYEOF
}

# Deploy Templates
echo "Deploying templates to $TARGET..."

# 1. Copy CLEAN templates for version control (commit-safe)
cp "template/mcp-config.json.template" "$MCP_DIR/trello.json.template"

# 2. Create/Update local secrets file (.agents/trello.env)
# This file is intentionally NOT a template and NOT for committing.
TRELLO_ENV="$TARGET/.agents/trello.env"
if [ ! -f "$TRELLO_ENV" ]; then
  echo "Creating $TRELLO_ENV..."
  {
    echo "# Trello Secrets - DO NOT COMMIT"
    echo "TRELLO_API_KEY=\"$TRELLO_API_KEY\""
    echo "TRELLO_TOKEN=\"$TRELLO_TOKEN\""
  } > "$TRELLO_ENV"
else
  echo "$TRELLO_ENV already exists. Skipping secret overwrite to preserve existing keys."
fi

# 3. Ensure .gitignore excludes the secrets file
GITIGNORE="$TARGET/.gitignore"
if [ -f "$GITIGNORE" ]; then
  if ! grep -q ".agents/trello.env" "$GITIGNORE"; then
    echo "Adding .agents/trello.env to .gitignore..."
    echo "" >> "$GITIGNORE"
    echo "# Trello Toolset" >> "$GITIGNORE"
    echo ".agents/trello.env" >> "$GITIGNORE"
  fi
fi

# 4. Expand and Copy remaining files
expand_template "template/trello/SKILL.md" "$SKILL_TRELLO_DIR/SKILL.md"
expand_template "template/mcp-config.json.template" "$MCP_DIR/trello.json"
expand_template "template/README.md.template" "$TARGET/.agents/skills/README.trello.md"

echo ""
echo "Success! Trello toolset installed."
echo "Configuration:"
echo "  Skills:  $SKILL_TRELLO_DIR"
echo "  Secrets: $TRELLO_ENV (Added to .gitignore)"
echo "  Docs:    $TARGET/.agents/skills/README.trello.md"
echo ""
echo "--- IMPORTANT: COMPLETE THE SETUP ---"
echo "You MUST register the 'trello' MCP server in your Gemini CLI configuration."
echo "See the exact JSON snippet to copy-paste in:"
echo "  $TARGET/.agents/skills/README.trello.md"
echo ""
echo "After registering, try running: /${PREFIX}-trello"
