#!/bin/bash

# install.sh - djt-kanban local kanban system installer
# Usage: ./install.sh --target /path/to/project

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TARGET=""

show_help() {
  echo "Usage: $0 --target <project_path>"
  echo ""
  echo "Options:"
  echo "  --target   Path to the target project root (required)"
  echo "  --help     Show this help message"
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

echo "--- djt-kanban Installation ---"

# Create kanban folder structure
KANBAN_DIR="$TARGET/.agents/.kanban"
mkdir -p "$KANBAN_DIR"/{0_backlog,1_bugs,2_techdebt,3_doing,4_done}

echo "✓ Created kanban folder structure at $KANBAN_DIR"

# Create skill directory
SKILL_DIR="$TARGET/.agents/skills/djt-kanban"
mkdir -p "$SKILL_DIR"

# Copy skill files
cp "$SCRIPT_DIR/SKILL.md" "$SKILL_DIR/SKILL.md"
cp "$SCRIPT_DIR/gemini.meta" "$SKILL_DIR/gemini.meta"
mkdir -p "$SKILL_DIR/template"
cp "$SCRIPT_DIR/template/ticket.md" "$SKILL_DIR/template/"

echo "✓ Installed djt-kanban skill to $SKILL_DIR"

# Copy example template to kanban folder for reference
cp "$SCRIPT_DIR/template/ticket.md" "$KANBAN_DIR/.template.md"

echo "✓ Added ticket template to $KANBAN_DIR/.template.md"

echo ""
echo "Success! djt-kanban is installed."
echo ""
echo "Folder structure:"
echo "  $KANBAN_DIR/0_backlog/   — features waiting"
echo "  $KANBAN_DIR/1_bugs/      — bug tickets"
echo "  $KANBAN_DIR/2_techdebt/  — refactoring items"
echo "  $KANBAN_DIR/3_doing/     — active work"
echo "  $KANBAN_DIR/4_done/      — completed"
echo ""
echo "Quick start:"
echo "  1. Copy .template.md to create your first ticket: 0_backlog/epic.ticket.md"
echo "  2. Run: /djt-kanban"
echo "  3. Select a ticket to start working on it"
echo ""
echo "See documentation at:"
echo "  $SKILL_DIR/SKILL.md"
