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
# Prerequisites
#   ensure_prerequisite installs a missing command with the platform's package
#   manager. The recipes live in tools/prerequisites.txt.
# ──────────────────────────────────────────────
if $IS_WINDOWS; then PREREQUISITE_PLATFORM=windows
elif [ "$(uname -s)" = "Darwin" ]; then PREREQUISITE_PLATFORM=darwin
else PREREQUISITE_PLATFORM=linux
fi

# A fresh install updates the registry or a dotfile, not this shell's PATH.
refresh_path() {
    if $IS_WINDOWS; then
        local registry_path
        registry_path="$(powershell.exe -NoProfile -NonInteractive -Command \
            "[Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')" \
            | tr -d '\r')"
        PATH="$PATH:$(cygpath -u -p "$registry_path")"
    fi
    PATH="$PATH:$HOME/.bun/bin:$HOME/.local/bin"
    export PATH
}

# prerequisite_dirs <command> — folders where installers put <command>, for a PATH that misses them
prerequisite_dirs() {
    [ "$1" = gh ] || return 0
    if $IS_WINDOWS; then
        [ -z "${PROGRAMFILES:-}" ] || cygpath -u "$PROGRAMFILES\\GitHub CLI"
        echo "/c/Program Files/GitHub CLI"
        [ -z "${LOCALAPPDATA:-}" ] || cygpath -u "$LOCALAPPDATA\\Programs\\GitHub CLI"
        echo "$HOME/scoop/shims"
        echo "/c/ProgramData/chocolatey/bin"
    else
        printf '%s\n' /opt/homebrew/bin /usr/local/bin /home/linuxbrew/.linuxbrew/bin "$HOME/.local/bin"
    fi
}

# ensure_prerequisite <command> — returns 0 when the command is on PATH after the attempt
ensure_prerequisite() {
    local command_name="$1" recipe dir
    command -v "$command_name" >/dev/null 2>&1 && return 0
    # An earlier install may have landed after this shell started. Look again before installing.
    refresh_path
    if command -v "$command_name" >/dev/null 2>&1; then
        warn "$command_name is at $(command -v "$command_name") but not on this shell's PATH. Open a new terminal."
        return 0
    fi
    while IFS= read -r dir; do
        if [ -f "$dir/$command_name" ] || [ -f "$dir/$command_name.exe" ]; then
            PATH="$PATH:$dir"
            export PATH
            if $IS_WINDOWS; then dir="$(cygpath -w "$dir")"; fi
            warn "$command_name is installed in $dir, which is not on PATH. Using it for this run. Add $dir to PATH."
            return 0
        fi
    done < <(prerequisite_dirs "$command_name")
    recipe="$(sed -n "s/^$command_name\.$PREREQUISITE_PLATFORM: *//p" "$REPO_ROOT/tools/prerequisites.txt" | head -n 1)"
    if [ -z "$recipe" ]; then
        warn "$command_name not found and no install recipe for $PREREQUISITE_PLATFORM (tools/prerequisites.txt)"
        return 1
    fi
    log "Installing $command_name …"
    if ! REPO_ROOT="$REPO_ROOT" bash -c "$recipe" </dev/null; then
        warn "Could not install $command_name. Install it yourself, then re-run sync."
        return 1
    fi
    refresh_path
    if command -v "$command_name" >/dev/null 2>&1; then
        ok "Installed $command_name"
    else
        warn "$command_name installed but not on PATH yet. Open a new terminal and re-run sync."
        return 1
    fi
}

# gh_is_signed_in — gh refuses every call until the user signs in once (interactive, cannot be automated)
gh_is_signed_in() { command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; }

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
# GitHub CLI — every machine gets gh. A failed install warns and sync goes on.
# ──────────────────────────────────────────────
log "Checking GitHub CLI (gh) …"
if ensure_prerequisite gh; then
    ok "gh $(gh --version 2>/dev/null | sed -n '1s/^gh version \([^ ]*\).*/\1/p')"
    gh_is_signed_in || warn "gh is not signed in. Run: gh auth login"
else
    warn "gh is not installed. Get it from https://cli.github.com, then re-run sync."
fi

# ──────────────────────────────────────────────
# 0. Initialize counters
# ──────────────────────────────────────────────
COUNT_DOTAGENTS=0
COUNT_EXTENSIONS=0
COUNT_SKILLS=0
COUNT_AGENTS=0

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

link_dir "$REPO_ROOT/src/agents" "$AGENTS_DIR/agents"
ok "Linked $REPO_ROOT/src/agents → ~/.agents/agents"

AGENT_SOURCES_DIR="$REPO_ROOT/src/agents"
if [ -d "$AGENT_SOURCES_DIR" ]; then
    for agent in "$AGENT_SOURCES_DIR"/*/; do
        if [ -d "$agent" ]; then
            agent_name=$(basename "$agent")
            ok "  Agent: $agent_name"
            ((++COUNT_AGENTS))
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

    # ~/.claude/agents also holds other repos' agents, so link one file at a time and never replace the directory.
    CLAUDE_AGENTS_DIR="$HOME/.claude/agents"
    # Windows copies files instead of linking, so this list of copied names stands in for the link target as proof of ownership.
    COPIED_AGENTS_LIST="$AGENTS_DIR/claude-agents-copied.txt"
    mkdir -p "$CLAUDE_AGENTS_DIR"

    # is_owned_agent_file <file> — true when sync created <file> from ~/.agents/agents
    is_owned_agent_file() {
        local file="$1"
        if $IS_WINDOWS; then
            grep -qxF "$(basename "$file")" "$COPIED_AGENTS_LIST" 2>/dev/null
        elif [ -L "$file" ]; then
            case "$(readlink "$file")" in
                "$AGENTS_DIR/agents/"*) return 0 ;;
                *) return 1 ;;
            esac
        else
            return 1
        fi
    }

    for agent_link in "$CLAUDE_AGENTS_DIR"/*.md; do
        agent_name=$(basename "$agent_link" .md)
        if is_owned_agent_file "$agent_link" && [ ! -f "$AGENTS_DIR/agents/$agent_name/AGENT.md" ]; then
            rm -f "$agent_link"
            ok "Removed stale agent ~/.claude/agents/$agent_name.md"
        fi
    done

    copied_agent_names=""
    for agent_file in "$AGENTS_DIR"/agents/*/AGENT.md; do
        [ -f "$agent_file" ] || continue
        agent_name=$(basename "$(dirname "$agent_file")")
        agent_link="$CLAUDE_AGENTS_DIR/$agent_name.md"
        if { [ -e "$agent_link" ] || [ -L "$agent_link" ]; } && ! is_owned_agent_file "$agent_link"; then
            warn "~/.claude/agents/$agent_name.md belongs to something else — skipping $agent_name"
            continue
        fi
        link_file "$agent_file" "$agent_link"
        copied_agent_names="${copied_agent_names}${agent_name}.md"$'\n'
        ok "Linked ~/.agents/agents/$agent_name/AGENT.md → ~/.claude/agents/$agent_name.md"
    done
    if $IS_WINDOWS; then
        printf '%s' "$copied_agent_names" > "$COPIED_AGENTS_LIST"
    fi

    install -m 755 "$REPO_ROOT/src/statusline-command.sh" "$HOME/.claude/statusline-command.sh"
    ok "Installed src/statusline-command.sh → ~/.claude/statusline-command.sh"

    # Merge owned top-level keys from src/claude-settings.json into settings.json.
    # Owned keys are replaced whole. Every other key is left alone.
    CLAUDE_SETTINGS="$HOME/.claude/settings.json"
    ensure_prerequisite jq || true
    if ! command -v jq >/dev/null 2>&1; then
        # No jq: node does the same merge. Owned keys replace whole, other keys stay.
        if command -v node >/dev/null 2>&1; then
            [ -e "$CLAUDE_SETTINGS" ] || echo '{}' > "$CLAUDE_SETTINGS"
            node_merge_result="$(node -e '
                const fs = require("fs");
                const [settingsPath, ownedPath] = process.argv.slice(1);
                let current;
                try { current = JSON.parse(fs.readFileSync(settingsPath, "utf8")); }
                catch (error) { console.log("invalid"); process.exit(0); }
                const owned = JSON.parse(fs.readFileSync(ownedPath, "utf8"));
                const merged = { ...current, ...owned };
                if (JSON.stringify(merged) === JSON.stringify(current)) { console.log("unchanged"); process.exit(0); }
                fs.writeFileSync(settingsPath, JSON.stringify(merged, null, 2) + "\n");
                console.log("merged " + Object.keys(owned).join(", "));
            ' "$CLAUDE_SETTINGS" "$REPO_ROOT/src/claude-settings.json")"
            case "$node_merge_result" in
                invalid)   warn "$CLAUDE_SETTINGS is not valid JSON — skipping merge" ;;
                unchanged) ok "~/.claude/settings.json already up to date" ;;
                merged*)   ok "Merged src/claude-settings.json → ~/.claude/settings.json (${node_merge_result#merged })" ;;
            esac
        else
            warn "Neither jq nor node found — skipping ~/.claude/settings.json merge (see tools/README.md)"
        fi
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
# 4. Wire up ~/.gemini (Gemini CLI)
#    Assembles a single GEMINI.md by inlining all skills and agents.
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

    # inline_entries <source_dir> <entry_file> <label> — append each <source_dir>/<name>/<entry_file> that has a gemini.meta
    inline_entries() {
        local source_dir="$1" entry_file_name="$2" label="$3" entry_dir entry_file meta_file name trigger notes
        while IFS= read -r -d '' entry_dir; do
            entry_file="$entry_dir/$entry_file_name"
            meta_file="$entry_dir/gemini.meta"

            if [ -f "$entry_file" ] && [ -f "$meta_file" ]; then
                name=$(basename "$entry_dir")
                trigger=$(meta_field "$meta_file" "trigger")
                notes=$(meta_field "$meta_file" "notes")

                printf '## %s: %s\n\n%s\n\n' "$label" "$name" "$trigger" >> "$GEMINI_MD"
                if [ -n "$notes" ]; then
                    printf '> **Note:** %s\n\n' "$notes" >> "$GEMINI_MD"
                fi
                skill_body "$entry_file" >> "$GEMINI_MD"
                if [ -f "$entry_dir/reference.md" ]; then
                    printf '\n\n' >> "$GEMINI_MD"
                    cat "$entry_dir/reference.md" >> "$GEMINI_MD"
                fi
                printf '\n---\n\n' >> "$GEMINI_MD"

                ok "  Inlined $(printf '%s' "$label" | tr '[:upper:]' '[:lower:]'): $name"
            fi
        done < <(find "$source_dir" -maxdepth 1 -mindepth 1 -type d -print0 | sort -z)
    }

    # has_gemini_entries <source_dir> <entry_file> — true when any <source_dir>/<name>/ has <entry_file> and gemini.meta
    has_gemini_entries() {
        local source_dir="$1" entry_file_name="$2" entry_dir
        for entry_dir in "$source_dir"/*/; do
            [ -f "$entry_dir$entry_file_name" ] && [ -f "${entry_dir}gemini.meta" ] && return 0
        done
        return 1
    }

    inline_entries "$SKILLS_DIR" SKILL.md Skill
    if has_gemini_entries "$AGENT_SOURCES_DIR" AGENT.md; then
        printf '\n# AGENTS\n\n' >> "$GEMINI_MD"
        inline_entries "$AGENT_SOURCES_DIR" AGENT.md Agent
    fi

    ok "Gemini CLI GEMINI.md assembled"
else
    warn "~/.gemini not found — skipping Gemini CLI setup"
fi

# ──────────────────────────────────────────────
# 5. Companion tools (tools/*.md)
#    Each file in tools/ describes one repo outside this one: frontmatter
#    for sync, docs for humans. Format: tools/README.md. Each repo is cloned
#    under $DJAUNT_SRC_DIR, fast-forwarded to origin, and installed only
#    when something changed. Never aborts sync.
# ──────────────────────────────────────────────
DJAUNT_SRC_DIR="${DJAUNT_SRC_DIR:-$HOME/src}"
DJAUNT_STAMP_DIR="$HOME/.local/share/djaunt-dot-agents"

# tool_fields <file> <key> [max] — print each value of <key> in the frontmatter block
tool_fields() {
    awk -v key="$2" -v max="${3:-0}" '
        /^---[[:space:]]*$/ { fences++; if (fences == 2) exit; next }
        fences == 1 && index($0, key ":") == 1 {
            value = substr($0, length(key) + 2)
            sub(/^[[:space:]]+/, "", value)
            print value
            if (max > 0 && ++printed >= max) exit
        }
    ' "$1"
}
tool_field() { tool_fields "$1" "$2" 1; }

# clone_repo <owner/name> <dir> — gh when installed (private repos), else plain https (public repos)
clone_repo() {
    if gh_is_signed_in; then
        gh repo clone "$1" "$2" -- --quiet
    else
        git clone --quiet "https://github.com/$1.git" "$2"
    fi
}

# ensure_djaunt_repo <owner/name> [dir] — clone if missing, else fast-forward. Sets DJAUNT_REPO_DIR.
ensure_djaunt_repo() {
    local repo="$1" name="${1#*/}"
    DJAUNT_REPO_DIR="${2:-$DJAUNT_SRC_DIR/$name}"
    if [ ! -d "$DJAUNT_REPO_DIR/.git" ]; then
        clone_repo "$repo" "$DJAUNT_REPO_DIR" \
            || { warn "Could not clone $repo to $DJAUNT_REPO_DIR — skipping"; return 1; }
        ok "Cloned $name → $DJAUNT_REPO_DIR"
    elif [ -n "$(git -C "$DJAUNT_REPO_DIR" status --porcelain)" ]; then
        warn "$name has local changes — using it as is"
    elif git -C "$DJAUNT_REPO_DIR" pull --ff-only --quiet; then
        ok "$name at $(git -C "$DJAUNT_REPO_DIR" rev-parse --short HEAD)"
    else
        warn "$name could not fast-forward — using it as is"
    fi
}

# stamp_matches <name> <value> / write_stamp <name> <value> — skip work when nothing changed
stamp_matches() { [ "$(cat "$DJAUNT_STAMP_DIR/$1" 2>/dev/null)" = "$2" ]; }
write_stamp()   { mkdir -p "$DJAUNT_STAMP_DIR"; printf '%s\n' "$2" > "$DJAUNT_STAMP_DIR/$1"; }

# editor_clis — print the VS Code CLI (PATH first, then the default install path on macOS or Windows)
editor_clis() {
    local bundled="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
    local windows_user_install="${LOCALAPPDATA:-}/Programs/Microsoft VS Code/bin/code"
    command -v code 2>/dev/null \
        || { [ -x "$bundled" ] && echo "$bundled"; } \
        || { [ -n "${LOCALAPPDATA:-}" ] && [ -f "$windows_user_install" ] && echo "$windows_user_install"; } \
        || true
}

# run_in_repo <command> — run a tool file's shell command inside the cloned repo
run_in_repo() { (cd "$DJAUNT_REPO_DIR" && bash -c "$1"); }

# sync_command_tool <file> <name> — kind: command
sync_command_tool() {
    local file="$1" name="$2" revision check requirement installs windows_installs cmd output note
    revision="$(git -C "$DJAUNT_REPO_DIR" rev-parse HEAD 2>/dev/null || echo unknown)"
    check="$(tool_field "$file" check)"
    if stamp_matches "$name-rev" "$revision" && { [ -z "$check" ] || run_in_repo "$check" >/dev/null 2>&1; }; then
        ok "$name up to date (${revision:0:7})"
        return 0
    fi

    requirement="$(tool_field "$file" requires)"
    if [ -n "$requirement" ] && ! command -v "$requirement" >/dev/null 2>&1; then
        warn "$requirement not found — skipping $name install ($(tool_field "$file" requires-hint))"
        return 0
    fi

    installs="$(tool_fields "$file" install)"
    if $IS_WINDOWS; then
        windows_installs="$(tool_fields "$file" install-windows)"
        [ -z "$windows_installs" ] || installs="$windows_installs"
    fi
    [ -n "$installs" ] || { warn "$name has no install line — skipping"; return 0; }
    while IFS= read -r cmd; do
        [ -n "$cmd" ] || continue
        if ! output="$(run_in_repo "$cmd" 2>&1)"; then
            warn "$name install failed: $cmd"
            printf '%s\n' "$output" >&2
            return 0
        fi
    done <<< "$installs"

    write_stamp "$name-rev" "$revision"
    ok "$name installed (${revision:0:7})"
    note="$(tool_field "$file" note)"
    [ -z "$note" ] || ok "$note"
}

# sync_vsix_tool <file> <name> <owner/name> — kind: vsix (latest GitHub release into each editor CLI)
sync_vsix_tool() {
    local file="$1" name="$2" repo="$3" extension asset latest cli installed tmp_dir vsix_file=""
    extension="$(tool_field "$file" vsix-extension)"
    asset="$(tool_field "$file" vsix-asset)"
    [ -n "$extension" ] && [ -n "$asset" ] || { warn "$name needs vsix-extension and vsix-asset — skipping"; return 0; }
    gh_is_signed_in || { warn "gh missing or not signed in (gh auth login) — skipping $name release check"; return 0; }

    latest="$(gh release view -R "$repo" --json tagName -q .tagName 2>/dev/null | sed 's/^v//' || true)"
    [ -n "$latest" ] || { warn "Could not read latest $name release — skipping"; return 0; }

    tmp_dir="$(mktemp -d)"
    while IFS= read -r cli; do
        [ -n "$cli" ] || continue
        installed="$("$cli" --list-extensions --show-versions 2>/dev/null | awk -F@ -v ext="$extension" '$1 == ext { print $2 }')"
        if [ "$installed" = "$latest" ]; then
            ok "$name $latest already installed in $(basename "$cli")"
            continue
        fi
        if [ -z "$vsix_file" ]; then
            gh release download "v$latest" -R "$repo" -p "$asset" -D "$tmp_dir" --clobber \
                || { warn "Could not download $name v$latest"; break; }
            vsix_file="$(find "$tmp_dir" -maxdepth 1 -type f | head -n 1)"
        fi
        if "$cli" --install-extension "$vsix_file" --force >/dev/null; then
            ok "$name ${installed:-none} → $latest in $(basename "$cli")"
        else
            warn "$name install failed in $(basename "$cli")"
        fi
    done < <(editor_clis)
    rm -rf "$tmp_dir"
    [ -n "$(editor_clis)" ] || warn "No VS Code CLI found — $name not installed"
}

# sync_agent_doc <file> <name> — write the tool's agent guide into ~/.agents/
sync_agent_doc() {
    local file="$1" name="$2" dest cmd fallback output
    dest="$(tool_field "$file" agent-doc-dest)"
    [ -n "$dest" ] || return 0
    cmd="$(tool_field "$file" agent-doc-cmd)"
    fallback="$(tool_field "$file" agent-doc-fallback)"
    if [ -n "$cmd" ] && output="$(run_in_repo "$cmd" 2>/dev/null)"; then
        printf '%s\n' "$output" > "$AGENTS_DIR/$dest"
        ok "Wrote $name agent guide → ~/.agents/$dest"
    elif [ -n "$fallback" ] && cp "$DJAUNT_REPO_DIR/$fallback" "$AGENTS_DIR/$dest" 2>/dev/null; then
        ok "Copied $name agent guide → ~/.agents/$dest"
    else
        warn "No $name agent guide found — ~/.agents/$dest not written"
    fi
}

# sync_tool <file> — read one tools/*.md file and install what it describes
sync_tool() {
    local file="$1" name repo platforms kind dir_env clone_name dir="" platform requirement
    name="$(tool_field "$file" name)"
    repo="$(tool_field "$file" repo)"
    platforms="$(tool_field "$file" platforms)"
    kind="$(tool_field "$file" kind)"
    dir_env="$(tool_field "$file" dir-env)"
    clone_name="$(tool_field "$file" clone-name)"
    if [ -z "$name" ] || [ -z "$repo" ] || [ -z "$platforms" ] || [ -z "$kind" ]; then
        warn "$(basename "$file") is missing name, repo, platforms, or kind — skipping"
        return 0
    fi

    log "Setting up $name …"
    platform="$(uname -s | tr '[:upper:]' '[:lower:]')"
    ! $IS_WINDOWS || platform="windows"
    case " $platforms " in
        *" $platform "*) ;;
        *) warn "$name supports $platforms only — skipping"; return 0 ;;
    esac

    requirement="$(tool_field "$file" requires)"
    [ -z "$requirement" ] || ensure_prerequisite "$requirement" || true

    [ -z "$dir_env" ] || dir="${!dir_env:-}"
    [ -n "$dir" ] || [ -z "$clone_name" ] || dir="$DJAUNT_SRC_DIR/$clone_name"
    ensure_djaunt_repo "$repo" "$dir" || return 0
    case "$kind" in
        command) sync_command_tool "$file" "$name" ;;
        clone)   ;;
        vsix)    sync_vsix_tool "$file" "$name" "$repo" ;;
        *)       warn "$name has unknown kind '$kind' — skipping" ;;
    esac
    sync_agent_doc "$file" "$name"
}

for tool_file in "$REPO_ROOT"/tools/*.md; do
    if [ -f "$tool_file" ] && [ "$(basename "$tool_file")" != "README.md" ]; then
        sync_tool "$tool_file"
    fi
done

echo ""
log "Summary: $COUNT_DOTAGENTS dotagents, $COUNT_EXTENSIONS extensions, $COUNT_SKILLS skills, $COUNT_AGENTS agents"
echo ""
log "Done. Your portable AI setup is live on this machine."
echo ""
echo "  Edit your config:    $REPO_ROOT/src/AGENTS.md"
echo "  Add/edit skills:     $REPO_ROOT/src/skills/djt-<name>/SKILL.md"
echo "  Add/edit agents:     $REPO_ROOT/src/agents/djt-<name>/AGENT.md"
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
echo "  Companion tools:     $REPO_ROOT/tools/README.md"
echo "    (share with an agent to install your preferred CLI tools)"
