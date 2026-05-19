#!/bin/bash

# install.sh - Godot 4 best-practices review skill installer
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

echo "--- djt-godot-review Installation ---"

SKILL_DIR="$TARGET/.agents/skills/djt-godot-review"
mkdir -p "$SKILL_DIR"

cp "$SCRIPT_DIR/SKILL.md" "$SKILL_DIR/SKILL.md"
cp "$SCRIPT_DIR/gemini.meta" "$SKILL_DIR/gemini.meta"

echo "✓ Installed djt-godot-review skill to $SKILL_DIR"

echo ""
echo "Success! djt-godot-review is installed."
echo ""
echo "Usage:"
echo "  /djt-godot-review                    # review unstaged changes"
echo "  /djt-godot-review origin/main..HEAD  # review branch diff"
echo "  /djt-godot-review path/to/file.gd    # review a specific file"
echo ""
echo "Reports are written to:"
echo "  $TARGET/.agents/output/reviews/"
echo ""
echo "See full documentation at:"
echo "  $SKILL_DIR/SKILL.md"
