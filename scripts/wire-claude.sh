#!/usr/bin/env bash
# wire-claude.sh — Recursively find AGENTS.md files and create CLAUDE.md symlinks.
# Usage: bash scripts/wire-claude.sh [directory]
# If no directory is provided, it defaults to the current working directory.

set -euo pipefail

TARGET_DIR="${1:-.}"
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

log()  { printf '\033[1;34m[wire]\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m  ✓\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m  !\033[0m %s\n' "$*"; }

log "Scanning $TARGET_DIR for AGENTS.md files..."

# Find all AGENTS.md files
while IFS= read -r -d '' agents_file; do
    dir="$(dirname "$agents_file")"
    claude_link="$dir/CLAUDE.md"

    if [ -L "$claude_link" ]; then
        # If it's already a symlink, check where it points
        current_target=$(readlink "$claude_link")
        if [ "$current_target" == "AGENTS.md" ]; then
            ok "Already linked: $claude_link -> AGENTS.md"
        else
            warn "Link exists but points elsewhere: $claude_link -> $current_target (Skipping)"
        fi
    elif [ -e "$claude_link" ]; then
        warn "File exists at $claude_link (Skipping to avoid overwrite)"
    else
        ln -s "AGENTS.md" "$claude_link"
        ok "Created link: $claude_link -> AGENTS.md"
    fi

done < <(find "$TARGET_DIR" -name "AGENTS.md" -print0)

log "Done."
