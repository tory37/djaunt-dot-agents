#!/usr/bin/env bash
# sync.sh — Install or refresh your portable AI agent setup on this machine.
# Run from the root of the djaunt-dot-agents repo:  bash scripts/sync.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AGENTS_DIR="$HOME/.agents"

log()  { printf '\033[1;34m[sync]\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m  ✓\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m  !\033[0m %s\n' "$*"; }

# ──────────────────────────────────────────────
# 0. Initialize counters
# ──────────────────────────────────────────────
COUNT_DOTAGENTS=0
COUNT_EXTENSIONS=0
COUNT_SKILLS=0

# ──────────────────────────────────────────────
# 1. Create ~/.agents and populate it
# ──────────────────────────────────────────────
log "Setting up ~/.agents …"

mkdir -p "$AGENTS_DIR"
ok "~/.agents exists"

cp "$REPO_ROOT/src/AGENTS.md" "$AGENTS_DIR/AGENTS.md"
((++COUNT_DOTAGENTS))
ok "Copied src/AGENTS.md → ~/.agents/AGENTS.md"

if [ -L "$AGENTS_DIR/skills" ] || [ -d "$AGENTS_DIR/skills" ]; then
    rm -rf "$AGENTS_DIR/skills"
fi
ln -s "$REPO_ROOT/src/skills" "$AGENTS_DIR/skills"
ok "Symlinked $REPO_ROOT/src/skills → ~/.agents/skills"

# Log individual skills
SKILLS_DIR="$REPO_ROOT/src/skills"
if [ -d "$SKILLS_DIR" ]; then
    for skill in "$SKILLS_DIR"/*/; do
        if [ -d "$skill" ]; then
            skill_name=$(basename "$skill")
            ok "  Skill: $skill_name"
            ((++COUNT_SKILLS))
        fi
    done
fi

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
            ((++COUNT_EXTENSIONS))
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
# 4. Wire up ~/.cursor (Cursor CLI)
#    Commands are assembled (not symlinked): each skill body is
#    copied to ~/.cursor/commands/<name>.md (frontmatter stripped).
# ──────────────────────────────────────────────
if command -v cursor &>/dev/null || [ -d "$HOME/.cursor" ]; then
    log "Cursor CLI detected — assembling ~/.cursor/commands/ …"

    CURSOR_COMMANDS="$HOME/.cursor/commands"
    mkdir -p "$CURSOR_COMMANDS"

    # Read a single field from a SKILL.md YAML frontmatter block.
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

    # Return the body of a SKILL.md — everything after the closing --- of frontmatter.
    skill_body() {
        local file="$1"
        awk '/^---$/{if(++n==2){found=1;next}} found{print}' "$file"
    }

    SKILLS_DIR="$REPO_ROOT/src/skills"
    while IFS= read -r -d '' skill_file; do
        name="$(frontmatter_field "$skill_file" name)"
        skill_body "$skill_file" > "$CURSOR_COMMANDS/${name}.md"
        ok "  Wrote command: /${name} → $CURSOR_COMMANDS/${name}.md"
    done < <(find "$SKILLS_DIR" -name "SKILL.md" -print0 | sort -z)

    ok "Cursor CLI commands assembled (~/.cursor/commands/)"
else
    warn "Cursor CLI not found — skipping (install cursor to enable)"
fi

# ──────────────────────────────────────────────
# 5. Wire up ~/.gemini (Gemini CLI)
#    Assembles a single GEMINI.md by inlining all skills.
# ──────────────────────────────────────────────
if [ -d "$HOME/.gemini" ]; then
    log "Gemini CLI detected — assembling ~/.gemini/GEMINI.md …"

    GEMINI_MD="$HOME/.gemini/GEMINI.md"
    
    # Initialize with AGENTS.md content
    cp "$REPO_ROOT/src/AGENTS.md" "$GEMINI_MD"
    
    # Append a separator
    echo -e "\n\n---\n\n# SKILLS\n" >> "$GEMINI_MD"

    # Helper to read gemini.meta fields
    meta_field() {
        local file="$1" field="$2"
        grep "^$field:" "$file" | cut -d':' -f2- | sed 's/^ *//' || true
    }

    # Return the body of a SKILL.md — everything after the closing --- of frontmatter.
    # (Shared with Cursor logic above, but redefined here for clarity)
    skill_body() {
        local file="$1"
        awk '/^---$/{if(++n==2){found=1;next}} found{print}' "$file"
    }

    SKILLS_DIR="$REPO_ROOT/src/skills"
    while IFS= read -r -d '' skill_dir; do
        skill_file="$skill_dir/SKILL.md"
        meta_file="$skill_dir/gemini.meta"
        
        if [ -f "$skill_file" ] && [ -f "$meta_file" ]; then
            name=$(basename "$skill_dir")
            trigger=$(meta_field "$meta_file" "trigger")
            notes=$(meta_field "$meta_file" "notes")
            
            echo -e "## Skill: $name\n" >> "$GEMINI_MD"
            echo -e "$trigger\n" >> "$GEMINI_MD"
            if [ -n "$notes" ]; then
                echo -e "> **Note:** $notes\n" >> "$GEMINI_MD"
            fi
            skill_body "$skill_file" >> "$GEMINI_MD"
            echo -e "\n---\n" >> "$GEMINI_MD"
            
            ok "  Inlined skill: $name"
        fi
    done < <(find "$SKILLS_DIR" -maxdepth 1 -mindepth 1 -type d -print0 | sort -z)

    ok "Gemini CLI GEMINI.md assembled"
else
    warn "~/.gemini not found — skipping Gemini CLI setup"
fi

echo ""
log "Summary: $COUNT_DOTAGENTS dotagents, $COUNT_EXTENSIONS extensions, $COUNT_SKILLS skills"
echo ""
log "Done. Your portable AI setup is live on this machine."
echo ""
echo "  Edit your config:    $REPO_ROOT/src/AGENTS.md"
echo "  Add/edit skills:     $REPO_ROOT/src/skills/djt-<name>/SKILL.md"
echo "  Machine extensions:  $AGENTS_DIR/extensions/<name>.md"
echo ""
echo "  Re-run sync.sh after pulling or making changes to this repo"
echo ""
echo "  Bootstrap tools:     $REPO_ROOT/setup/tools.md"
echo "    (share with an agent to install your preferred CLI tools)"
