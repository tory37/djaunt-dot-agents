#!/usr/bin/env bash
# .agents/scripts/wire-claude.sh — Recursively find AGENTS.md files and create CLAUDE.md symlinks.
set -euo pipefail

TARGET_DIR="${1:-.}"
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

echo "Scanning $TARGET_DIR for AGENTS.md files..."

# Find all AGENTS.md files
while IFS= read -r -d '' agents_file; do
    dir="$(dirname "$agents_file")"
    claude_link="$dir/CLAUDE.md"

    if [ -L "$claude_link" ]; then
        # If it's already a symlink, check where it points
        current_target=$(readlink "$claude_link")
        if [ "$current_target" == "AGENTS.md" ]; then
            continue
        fi
    fi
    
    if [ -e "$claude_link" ] && [ ! -L "$claude_link" ]; then
        echo "  ! File exists at $claude_link (Skipping)"
        continue
    fi

    ln -sf "AGENTS.md" "$claude_link"
    echo "  ✓ Linked: $claude_link -> AGENTS.md"

done < <(find "$TARGET_DIR" -name "AGENTS.md" -print0)
