#!/bin/bash

# install.sh - djt-test-coverage skill installer
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

echo "--- djt-test-coverage Installation ---"

SKILL_DIR="$TARGET/.agents/skills/djt-test-coverage"
mkdir -p "$SKILL_DIR"

cp "$SCRIPT_DIR/SKILL.md" "$SKILL_DIR/SKILL.md"
cp "$SCRIPT_DIR/gemini.meta" "$SKILL_DIR/gemini.meta"

echo "✓ Installed djt-test-coverage skill to $SKILL_DIR"

OUTPUT_DIR="$TARGET/.agents/output/coverage"
mkdir -p "$OUTPUT_DIR"

echo "✓ Created output directory at $OUTPUT_DIR"

echo ""
echo "Success! djt-test-coverage is installed."
echo ""
echo "Usage:"
echo "  /djt-test-coverage                    # audit entire project"
echo "  /djt-test-coverage src/               # audit a specific directory"
echo "  /djt-test-coverage src/auth/login.ts  # audit a specific file"
echo ""
echo "After reviewing the report, check the boxes for gaps you want fixed, then:"
echo "  /djt-test-coverage --apply .agents/output/coverage/<report>.md"
echo ""
echo "Reports are written to:"
echo "  $OUTPUT_DIR/"
echo ""
echo "See full documentation at:"
echo "  $SKILL_DIR/SKILL.md"
