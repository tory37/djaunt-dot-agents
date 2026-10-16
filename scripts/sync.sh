#!/usr/bin/env bash
# sync.sh — Install or refresh your portable AI agent setup on this machine.
# Works on macOS, Linux, and Windows (Git Bash / MSYS2).
# Run from the root of the djaunt-dot-agents repo:  bash scripts/sync.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AGENTS_DIR="$HOME/.agents"

# ──────────────────────────────────────────────
# OS detection
# ──────────────────────────────────────────────
IS_WINDOWS=false
case "${OSTYPE:-}" in
    msys*|cygwin*|win32*) IS_WINDOWS=true ;;
esac
if ! $IS_WINDOWS; then
    case "$(uname -s 2>/dev/null || true)" in
        MINGW*|MSYS*|CYGWIN*) IS_WINDOWS=true ;;
    esac
fi

log()  { printf '\033[1;34m[sync]\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m  ✓\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m  !\033[0m %s\n' "$*"; }

$IS_WINDOWS && log "Windows detected — using junctions for dirs, copies for files"

# ──────────────────────────────────────────────
# Link helpers
# ──────────────────────────────────────────────
# link_file <target> <link>  — symlink on Unix, file copy on Windows
link_file() {
    local target="$1" link="$2"
    rm -f "$link"
    if $IS_WINDOWS; then
        cp "$target" "$link"
    else
        ln -s "$target" "$link"
    fi
}

# link_dir <target> <link>  — symlink on Unix, NTFS junction on Windows
# Junctions don't require admin or Developer Mode and reflect live edits.
link_dir() {
    local target="$1" link="$2"
    if [ -L "$link" ]; then
        rm -f "$link"
    elif [ -d "$link" ]; then
        rm -rf "$link"
    fi
    if $IS_WINDOWS; then
        local win_link win_target
        win_link="$(cygpath -w "$link")"
        win_target="$(cygpath -w "$target")"
        # cmd /c mklink is unreliable in Git Bash; powershell.exe works correctly
        powershell.exe -NonInteractive -Command \
            "New-Item -ItemType Junction -Path '$win_link' -Target '$win_target'" > /dev/null
    else
        ln -s "$target" "$link"
    fi
}

# ──────────────────────────────────────────────
# Budget gate — refuse to deploy oversized instruction files
# ──────────────────────────────────────────────
bash "$REPO_ROOT/scripts/check-budget.sh" || { warn "Budget check failed — sync aborted"; exit 1; }

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

mkdir -p "$AGENTS_DIR/assets"
cp "$REPO_ROOT/src/assets/style.css" "$AGENTS_DIR/assets/style.css"
ok "Copied src/assets/style.css → ~/.agents/assets/style.css"
for asset_file in "$REPO_ROOT"/src/assets/*.md; do
    cp "$asset_file" "$AGENTS_DIR/assets/$(basename "$asset_file")"
    ok "Copied src/assets/$(basename "$asset_file") → ~/.agents/assets/"
done

link_dir "$REPO_ROOT/src/skills" "$AGENTS_DIR/skills"
ok "Linked $REPO_ROOT/src/skills → ~/.agents/skills"

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

        # Pure-bash placeholder replacement (avoids perl/python dependency)
        TMP_FILE=$(mktemp)
        while IFS= read -r line; do
            if printf '%s' "$line" | grep -q 'PROJECT_EXTENSIONS_PLACEHOLDER'; then
                printf '%s' "$INJECTION"
            else
                printf '%s\n' "$line"
            fi
        done < "$AGENTS_DIR/AGENTS.md" > "$TMP_FILE"
        mv "$TMP_FILE" "$AGENTS_DIR/AGENTS.md"
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

    link_file "$AGENTS_DIR/AGENTS.md" "$HOME/.claude/CLAUDE.md"
    ok "Linked ~/.agents/AGENTS.md → ~/.claude/CLAUDE.md"

    link_dir "$AGENTS_DIR/skills" "$HOME/.claude/skills"
    ok "Linked ~/.agents/skills → ~/.claude/skills"

    # Merge owned top-level keys from src/claude-settings.json into settings.json.
    # Owned keys are replaced whole. Every other key is left alone.
    CLAUDE_SETTINGS="$HOME/.claude/settings.json"
    if ! command -v jq >/dev/null 2>&1; then
        warn "jq not found — skipping ~/.claude/settings.json merge (see setup/tools.md)"
    elif [ -e "$CLAUDE_SETTINGS" ] && ! jq empty "$CLAUDE_SETTINGS" 2>/dev/null; then
        warn "$CLAUDE_SETTINGS is not valid JSON — skipping merge"
    else
        [ -e "$CLAUDE_SETTINGS" ] || echo '{}' > "$CLAUDE_SETTINGS"
        merged="$(mktemp)"
        jq --slurpfile owned "$REPO_ROOT/src/claude-settings.json" '. + $owned[0]' "$CLAUDE_SETTINGS" > "$merged"
        if cmp -s <(jq -S . "$merged") <(jq -S . "$CLAUDE_SETTINGS"); then
            ok "~/.claude/settings.json already up to date"
            rm -f "$merged"
        else
            mv "$merged" "$CLAUDE_SETTINGS"
            ok "Merged src/claude-settings.json → ~/.claude/settings.json ($(jq -r 'keys | join(", ")' "$REPO_ROOT/src/claude-settings.json"))"
        fi
    fi
else
    warn "~/.claude not found — skipping Claude Code setup (install Claude Code to enable)"
fi

# ──────────────────────────────────────────────
# 4. Wire up ~/.cursor (Cursor)
#    Commands are assembled (not linked): each skill body is
#    written to ~/.cursor/commands/<name>.md (frontmatter stripped).
# ──────────────────────────────────────────────
CURSOR_FOUND=false
if command -v cursor &>/dev/null; then
    CURSOR_FOUND=true
elif [ -d "$HOME/.cursor" ]; then
    # On Windows, cursor may not be in PATH but the config dir still exists
    CURSOR_FOUND=true
fi

if $CURSOR_FOUND; then
    log "Cursor detected — assembling ~/.cursor/commands/ …"

    CURSOR_COMMANDS="$HOME/.cursor/commands"
    mkdir -p "$CURSOR_COMMANDS"

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

    skill_body() {
        local file="$1"
        awk '/^---$/{if(++n==2){found=1;next}} found{print}' "$file"
    }

    while IFS= read -r -d '' skill_file; do
        name="$(frontmatter_field "$skill_file" name)"
        skill_body "$skill_file" > "$CURSOR_COMMANDS/${name}.md"
        if [ -f "$(dirname "$skill_file")/reference.md" ]; then
            printf '\n\n' >> "$CURSOR_COMMANDS/${name}.md"
            cat "$(dirname "$skill_file")/reference.md" >> "$CURSOR_COMMANDS/${name}.md"
        fi
        ok "  Wrote command: /${name} → $CURSOR_COMMANDS/${name}.md"
    done < <(find "$SKILLS_DIR" -name "SKILL.md" -print0 | sort -z)

    ok "Cursor commands assembled (~/.cursor/commands/)"
else
    warn "Cursor not found — skipping (install Cursor to enable)"
fi

# ──────────────────────────────────────────────
# 5. Wire up ~/.gemini (Gemini CLI)
#    Assembles a single GEMINI.md by inlining all skills.
# ──────────────────────────────────────────────
if [ -d "$HOME/.gemini" ]; then
    log "Gemini CLI detected — assembling ~/.gemini/GEMINI.md …"

    GEMINI_MD="$HOME/.gemini/GEMINI.md"
    cp "$REPO_ROOT/src/AGENTS.md" "$GEMINI_MD"
    printf '\n\n---\n\n# SKILLS\n\n' >> "$GEMINI_MD"

    meta_field() {
        local file="$1" field="$2"
        grep "^$field:" "$file" | cut -d':' -f2- | sed 's/^ *//' || true
    }

    skill_body() {
        local file="$1"
        awk '/^---$/{if(++n==2){found=1;next}} found{print}' "$file"
    }

    while IFS= read -r -d '' skill_dir; do
        skill_file="$skill_dir/SKILL.md"
        meta_file="$skill_dir/gemini.meta"

        if [ -f "$skill_file" ] && [ -f "$meta_file" ]; then
            name=$(basename "$skill_dir")
            trigger=$(meta_field "$meta_file" "trigger")
            notes=$(meta_field "$meta_file" "notes")

            printf '## Skill: %s\n\n%s\n\n' "$name" "$trigger" >> "$GEMINI_MD"
            if [ -n "$notes" ]; then
                printf '> **Note:** %s\n\n' "$notes" >> "$GEMINI_MD"
            fi
            skill_body "$skill_file" >> "$GEMINI_MD"
            if [ -f "$skill_dir/reference.md" ]; then
                printf '\n\n' >> "$GEMINI_MD"
                cat "$skill_dir/reference.md" >> "$GEMINI_MD"
            fi
            printf '\n---\n\n' >> "$GEMINI_MD"

            ok "  Inlined skill: $name"
        fi
    done < <(find "$SKILLS_DIR" -maxdepth 1 -mindepth 1 -type d -print0 | sort -z)

    ok "Gemini CLI GEMINI.md assembled"
else
    warn "~/.gemini not found — skipping Gemini CLI setup"
fi

# ──────────────────────────────────────────────
# 6. djt-hub (live browser hubs for agents)
#    Builds from $DJT_HUB_REPO and keeps the launchd daemon running.
#    Rebuilds only when the repo's HEAD changed or the daemon is down,
#    so cron syncs don't restart it. Never aborts sync.
# ──────────────────────────────────────────────
DJT_HUB_REPO="${DJT_HUB_REPO:-$HOME/src/djaunt-agent-hubs}"
DJT_HUB_BIN="$HOME/.local/bin/djt-hub"
DJT_HUB_STAMP="$HOME/.local/share/djt-hub/installed-rev"

sync_djt_hub() {
    log "Setting up djt-hub …"
    if $IS_WINDOWS; then
        warn "djt-hub is not supported on Windows — skipping"
        return
    fi
    if [ ! -d "$DJT_HUB_REPO/.git" ]; then
        if command -v gh >/dev/null 2>&1 && gh repo clone tory37/djaunt-agent-hubs "$DJT_HUB_REPO" -- --quiet; then
            ok "Cloned djaunt-agent-hubs → $DJT_HUB_REPO"
        else
            warn "Could not clone djaunt-agent-hubs to $DJT_HUB_REPO — skipping (set DJT_HUB_REPO or clone it)"
            return
        fi
    fi

    local revision
    revision="$(git -C "$DJT_HUB_REPO" rev-parse HEAD 2>/dev/null || echo unknown)"
    if [ -x "$DJT_HUB_BIN" ] && [ "$(cat "$DJT_HUB_STAMP" 2>/dev/null)" = "$revision" ] \
        && { [ "$(uname -s)" != "Darwin" ] || "$DJT_HUB_BIN" status >/dev/null 2>&1; }; then
        ok "djt-hub up to date (${revision:0:7})"
    elif ! command -v go >/dev/null 2>&1; then
        warn "go not found — skipping djt-hub build (see setup/tools.md)"
    elif bash "$DJT_HUB_REPO/install.sh"; then
        mkdir -p "$(dirname "$DJT_HUB_STAMP")"
        printf '%s\n' "$revision" > "$DJT_HUB_STAMP"
        ok "djt-hub built and running (${revision:0:7})"
    else
        warn "djt-hub install failed — see output above"
    fi

    if [ -x "$DJT_HUB_BIN" ] && "$DJT_HUB_BIN" docs > "$AGENTS_DIR/assets/djt-hub.md"; then
        ok "Wrote djt-hub docs → ~/.agents/assets/djt-hub.md"
    elif cp "$DJT_HUB_REPO/docs/agent-guide.md" "$AGENTS_DIR/assets/djt-hub.md" 2>/dev/null; then
        ok "Copied djt-hub agent guide → ~/.agents/assets/djt-hub.md"
    else
        warn "No djt-hub agent guide found — ~/.agents/assets/djt-hub.md not written"
    fi
}
sync_djt_hub

echo ""
log "Summary: $COUNT_DOTAGENTS dotagents, $COUNT_EXTENSIONS extensions, $COUNT_SKILLS skills"
echo ""
log "Done. Your portable AI setup is live on this machine."
echo ""
echo "  Edit your config:    $REPO_ROOT/src/AGENTS.md"
echo "  Add/edit skills:     $REPO_ROOT/src/skills/djt-<name>/SKILL.md"
echo "  Machine extensions:  $AGENTS_DIR/extensions/<name>.md"
echo ""
if $IS_WINDOWS; then
    echo "  Windows notes:"
    echo "    - Config files are copied (re-run sync after editing src/AGENTS.md)"
    echo "    - Skill dirs use NTFS junctions — edits to src/skills/ reflect live"
    echo ""
fi
echo "  Re-run sync.sh after pulling or making changes to this repo"
echo ""
echo "  Bootstrap tools:     $REPO_ROOT/setup/tools.md"
echo "    (share with an agent to install your preferred CLI tools)"
