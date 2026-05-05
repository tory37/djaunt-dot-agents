#!/usr/bin/env bash
# sync.sh — Install or refresh your portable AI agent setup on this machine.
# Run from the root of the djaunt-dot-agents repo:  bash scripts/sync.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AGENTS_DIR="$HOME/.agents"

log()  { printf '\033[1;34m[sync]\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m  ✓\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m  !\033[0m %s\n' "$*"; }

# Read a single field from a SKILL.md YAML frontmatter block.
# Usage: frontmatter_field <file> <field>
frontmatter_field() {
    local file="$1" field="$2"
    awk -v field="$field" '
        /^---$/ { count++; next }
        count == 1 && $0 ~ "^" field ":" {
            sub("^" field ": *", ""); gsub(/^"|"$/, ""); print; exit
        }
        count >= 2 { exit }
    ' "$file"
}

# Read a field from a gemini.meta file (simple "key: value" lines).
# Usage: meta_field <file> <field>
meta_field() {
    local file="$1" field="$2"
    awk -v field="$field" '$0 ~ "^" field ":" { sub("^" field ": *", ""); print; exit }' "$file"
}

# Return the body of a SKILL.md — everything after the closing --- of frontmatter.
skill_body() {
    local file="$1"
    awk '/^---$/{if(++n==2){found=1;next}} found{print}' "$file"
}

# ──────────────────────────────────────────────
# 1. Create ~/.agents and populate it
# ──────────────────────────────────────────────
log "Setting up ~/.agents …"

mkdir -p "$AGENTS_DIR"
ok "~/.agents exists"

cp "$REPO_ROOT/AGENTS.md" "$AGENTS_DIR/AGENTS.md"
ok "Copied AGENTS.md → ~/.agents/AGENTS.md"

if [ -L "$AGENTS_DIR/skills" ] || [ -d "$AGENTS_DIR/skills" ]; then
    rm -rf "$AGENTS_DIR/skills"
fi
ln -s "$REPO_ROOT/skills" "$AGENTS_DIR/skills"
ok "Symlinked $REPO_ROOT/skills → ~/.agents/skills"

# ──────────────────────────────────────────────
# 2. Inject extension references into AGENTS.md
# ──────────────────────────────────────────────
PLACEHOLDER="<!-- PROJECT_EXTENSIONS_PLACEHOLDER:.*-->"

if [ -d "$AGENTS_DIR/extensions" ]; then
    EXT_FILES=("$AGENTS_DIR/extensions/"*.md)
    if [ -e "${EXT_FILES[0]}" ]; then
        log "Found extensions — injecting references into ~/.agents/AGENTS.md …"
        INJECTION=""
        for ext_file in "${EXT_FILES[@]}"; do
            INJECTION="${INJECTION}@${ext_file}"$'\n'
            ok "  Extension: $ext_file"
        done
        perl -i -0pe "s|${PLACEHOLDER}|${INJECTION}|" "$AGENTS_DIR/AGENTS.md"
        ok "Extensions injected"
    else
        warn "~/.agents/extensions/ exists but contains no .md files — skipping extension injection"
    fi
else
    ok "No ~/.agents/extensions/ folder — skipping extension injection (create it later for machine-specific config)"
fi

# ──────────────────────────────────────────────
# 3. Wire up ~/.claude (Claude Code)
# ──────────────────────────────────────────────
if [ -d "$HOME/.claude" ]; then
    log "~/.claude detected — configuring for Claude Code …"

    CLAUDE_MD="$HOME/.claude/CLAUDE.md"
    if [ -L "$CLAUDE_MD" ] || [ -f "$CLAUDE_MD" ]; then
        warn "Removing existing $CLAUDE_MD"
        rm -f "$CLAUDE_MD"
    fi
    ln -s "$AGENTS_DIR/AGENTS.md" "$CLAUDE_MD"
    ok "Symlinked ~/.agents/AGENTS.md → ~/.claude/CLAUDE.md"

    if [ -L "$HOME/.claude/skills" ] || [ -d "$HOME/.claude/skills" ]; then
        rm -rf "$HOME/.claude/skills"
    fi
    ln -s "$AGENTS_DIR/skills" "$HOME/.claude/skills"
    ok "Symlinked ~/.agents/skills → ~/.claude/skills"
else
    warn "~/.claude not found — skipping Claude Code setup (install Claude Code to enable)"
fi

# ──────────────────────────────────────────────
# 4. Wire up ~/.gemini (Gemini CLI)
#    GEMINI.md is assembled (not symlinked): AGENTS.md content +
#    all skills inlined with their Gemini-specific trigger lines.
# ──────────────────────────────────────────────
if [ -d "$HOME/.gemini" ]; then
    log "~/.gemini detected — assembling GEMINI.md for Gemini CLI …"

    GEMINI_MD="$HOME/.gemini/GEMINI.md"
    rm -f "$GEMINI_MD"

    # Start with the AGENTS.md content (already has extensions injected)
    cat "$AGENTS_DIR/AGENTS.md" >> "$GEMINI_MD"

    # Collect skills
    SKILLS_DIR="$REPO_ROOT/skills"
    SKILL_FILES=()
    while IFS= read -r -d '' f; do
        SKILL_FILES+=("$f")
    done < <(find "$SKILLS_DIR" -name "SKILL.md" -print0 | sort -z)

    if [ ${#SKILL_FILES[@]} -gt 0 ]; then
        # Append skills preamble
        cat >> "$GEMINI_MD" <<'PREAMBLE'


---

## Skills

The following skills are available. When the user types a slash command or matches a trigger description below, execute the corresponding workflow **exactly as written** — do not skip or reorder steps, and do not proceed past a gate without user confirmation.

PREAMBLE

        # Build index table
        printf '| Command | Description |\n' >> "$GEMINI_MD"
        printf '|---------|-------------|\n' >> "$GEMINI_MD"
        for skill_file in "${SKILL_FILES[@]}"; do
            name="$(frontmatter_field "$skill_file" name)"
            desc="$(frontmatter_field "$skill_file" description)"
            printf '| /%s | %s |\n' "$name" "$desc" >> "$GEMINI_MD"
            ok "  Indexed skill: /$name"
        done
        printf '\n---\n' >> "$GEMINI_MD"

        # Inline each skill
        for skill_file in "${SKILL_FILES[@]}"; do
            name="$(frontmatter_field "$skill_file" name)"
            meta_file="$(dirname "$skill_file")/gemini.meta"
            trigger=""
            notes=""
            if [ -f "$meta_file" ]; then
                trigger="$(meta_field "$meta_file" trigger)"
                notes="$(meta_field "$meta_file" notes)"
            fi

            printf '\n### /%s\n\n' "$name" >> "$GEMINI_MD"

            if [ -n "$trigger" ]; then
                printf '%s\n\n' "$trigger" >> "$GEMINI_MD"
            fi

            if [ -n "$notes" ]; then
                printf '> **Note:** %s\n\n' "$notes" >> "$GEMINI_MD"
            fi

            skill_body "$skill_file" >> "$GEMINI_MD"
            printf '\n---\n' >> "$GEMINI_MD"
            ok "  Inlined skill: /$name"
        done
    fi

    ok "Assembled ~/.gemini/GEMINI.md"

    # Symlink skills directory for future-proofing
    if [ -L "$HOME/.gemini/skills" ] || [ -d "$HOME/.gemini/skills" ]; then
        rm -rf "$HOME/.gemini/skills"
    fi
    ln -s "$AGENTS_DIR/skills" "$HOME/.gemini/skills"
    ok "Symlinked ~/.agents/skills → ~/.gemini/skills"
else
    warn "~/.gemini not found — skipping Gemini CLI setup (install Gemini CLI to enable)"
fi

echo ""
log "Done. Your portable AI setup is live on this machine."
echo ""
echo "  Edit your config:    $REPO_ROOT/AGENTS.md"
echo "  Add/edit skills:     $REPO_ROOT/skills/<skill-name>/SKILL.md"
echo "  Machine extensions:  $AGENTS_DIR/extensions/<name>.md"
echo ""
echo "  Re-run sync.sh after pulling changes to rebuild GEMINI.md."
