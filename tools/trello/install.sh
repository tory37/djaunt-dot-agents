#!/bin/bash

# install.sh - Generic Trello Toolset Installer for Gemini CLI Projects
# Usage: ./install.sh --target /path/to/project [--prefix custom]

set -e

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
SKILL_BACKLOG_DIR="$TARGET/.agents/skills/${PREFIX}-backlog"
MCP_DIR="$TARGET/.agents/mcp"

mkdir -p "$SKILL_TRELLO_DIR"
mkdir -p "$SKILL_BACKLOG_DIR"
mkdir -p "$MCP_DIR"

# Internal function for template replacement
expand_template() {
  local src=$1
  local dest=$2
  
  sed -e "s/{{PREFIX}}/${PREFIX}/g" \
      -e "s/{{TRELLO_API_KEY}}/${TRELLO_API_KEY}/g" \
      -e "s/{{TRELLO_TOKEN}}/${TRELLO_TOKEN}/g" \
      -e "s/{{TRELLO_BOARD_ID}}/${TRELLO_BOARD_ID}/g" \
      -e "s/{{TRELLO_LIST_BUGS}}/${TRELLO_LIST_BUGS}/g" \
      -e "s/{{TRELLO_LIST_TECHDEBT}}/${TRELLO_LIST_TECHDEBT}/g" \
      -e "s/{{TRELLO_LIST_BACKLOG}}/${TRELLO_LIST_BACKLOG}/g" \
      -e "s/{{TRELLO_LIST_DOING}}/${TRELLO_LIST_DOING}/g" \
      "$src" > "$dest"
}

# Deploy Templates
echo "Deploying templates to $TARGET..."

# 1. Copy CLEAN templates for version control (commit-safe)
cp "template/mcp-config.json.template" "$MCP_DIR/trello.json.template"
cp "template/.env.trello.example" "$TARGET/.env.trello.example"

# 2. Expand and Copy (local use, NOT for committing)
expand_template "template/djt-trello/SKILL.md" "$SKILL_TRELLO_DIR/SKILL.md"
expand_template "template/djt-backlog/SKILL.md" "$SKILL_BACKLOG_DIR/SKILL.md"
expand_template "template/mcp-config.json.template" "$MCP_DIR/trello.json"
expand_template "template/README.md.template" "$TARGET/.agents/skills/README.trello.md"

echo ""
echo "Success! Trello toolset installed."
echo "Next steps:"
echo "1. Add .agents/mcp/trello.json to your .gitignore (the .template is already there for others)."
echo "2. Review $TARGET/.env.trello.example and copy the required variables to your project's .env file."
echo "2. Ensure the 'trello' server is registered in your Gemini CLI configuration (pointing to $MCP_DIR/trello.json)."
echo "3. Try running: /${PREFIX}-trello"
