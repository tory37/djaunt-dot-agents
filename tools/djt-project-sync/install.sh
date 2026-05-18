#!/bin/bash

# install.sh - Project Agent Synchronization Installer
# Usage: ./install.sh --target /path/to/project

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET=""

show_help() {
  echo "Usage: $0 --target <project_path>"
  echo ""
  echo "Options:"
  echo "  --target       Path to the target project root (required)"
  echo "  --help         Show this help message"
}

# Parse arguments
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --target) TARGET="$2"; shift ;;
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

TARGET="$(cd "$TARGET" && pwd)"

echo "--- Project Agent Sync Installation ---"
echo "Target: $TARGET"

# Create target directory
mkdir -p "$TARGET/.agents/scripts"

# Copy scripts
cp "$SCRIPT_DIR/template/.agents/scripts/sync.sh" "$TARGET/.agents/scripts/sync.sh"
cp "$SCRIPT_DIR/template/.agents/scripts/wire-claude.sh" "$TARGET/.agents/scripts/wire-claude.sh"

# Ensure they are executable
chmod +x "$TARGET/.agents/scripts/sync.sh"
chmod +x "$TARGET/.agents/scripts/wire-claude.sh"

echo ""
echo "Success! Project synchronization scripts installed."
echo "Next steps:"
echo "1. Run the sync script: bash .agents/scripts/sync.sh"
echo "2. Add '.agents/scripts/sync.sh' to your project's onboarding instructions (e.g., README.md or AGENTS.md)."
echo "3. (Optional) Run sync.sh periodically to ensure all AGENTS.md files are linked to CLAUDE.md."
