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
# 1. Create ~/.agents and populate it
# ──────────────────────────────────────────────
log "Setting up ~/.agents …"

mkdir -p "$AGENTS_DIR"
ok "~/.agents exists"

cp "$REPO_ROOT/AGENTS.md" "$AGENTS_DIR/AGENTS.md"
ok "Copied AGENTS.md → ~/.agents/AGENTS.md"

mkdir -p "$AGENTS_DIR/skills"
if [ -d "$REPO_ROOT/skills" ]; then
    cp -R "$REPO_ROOT/skills/." "$AGENTS_DIR/skills/"
    ok "Copied skills/ → ~/.agents/skills/"
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
        done
        # Replace placeholder with the @include lines (macOS sed -i '')
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

    mkdir -p "$HOME/.claude/skills"
    cp -R "$AGENTS_DIR/skills/." "$HOME/.claude/skills/"
    ok "Copied skills → ~/.claude/skills/"
else
    warn "~/.claude not found — skipping Claude Code setup (install Claude Code to enable)"
fi

# ──────────────────────────────────────────────
# 4. Wire up ~/.gemini (Gemini CLI)
# ──────────────────────────────────────────────
if [ -d "$HOME/.gemini" ]; then
    log "~/.gemini detected — configuring for Gemini CLI …"

    GEMINI_MD="$HOME/.gemini/GEMINI.md"
    if [ -L "$GEMINI_MD" ] || [ -f "$GEMINI_MD" ]; then
        warn "Removing existing $GEMINI_MD"
        rm -f "$GEMINI_MD"
    fi
    ln -s "$AGENTS_DIR/AGENTS.md" "$GEMINI_MD"
    ok "Symlinked ~/.agents/AGENTS.md → ~/.gemini/GEMINI.md"

    # Gemini CLI does not have a native skills system equivalent to Claude Code.
    # We copy skills here for future-proofing and in case Gemini adds support,
    # but they will not auto-load without manual Gemini CLI configuration.
    mkdir -p "$HOME/.gemini/skills"
    cp -R "$AGENTS_DIR/skills/." "$HOME/.gemini/skills/"
    ok "Copied skills → ~/.gemini/skills/ (note: Gemini CLI has no native skill auto-loading)"
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
echo "  Re-run this script any time you pull changes from the repo."
