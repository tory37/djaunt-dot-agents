# Plan: Cursor CLI Support

## Scope

Support only the **Cursor CLI** (`cursor-agent`). The Cursor IDE is explicitly out of scope.

## Research Summary

- **Cursor CLI global commands:** `~/.cursor/commands/*.md` — plain Markdown, global.
- **No global rules mechanism** in the CLI — commands are the only hook.
- Command files are named by their filename (e.g. `feature.md` → `/feature` command).

---

## Approach

Copy the skill body (frontmatter stripped) into `~/.cursor/commands/<name>.md` — same pattern as Gemini. Re-run `sync.sh` after adding or editing skills.

```
~/.cursor/commands/feature.md  ←  skill_body(skills/feature/SKILL.md)
~/.cursor/commands/bug.md      ←  skill_body(skills/bug/SKILL.md)
...
```

No `cursor.meta` sidecar needed — Cursor has no trigger/notes system to populate.

---

## Implementation Steps

### Step 1 — Add Cursor CLI block to `sync.sh`

Detect `~/.cursor` or `cursor` in PATH, assemble command files using the existing `skill_body` helper:

```bash
if command -v cursor &>/dev/null || [ -d "$HOME/.cursor" ]; then
    log "Cursor CLI detected — assembling ~/.cursor/commands/ …"
    CURSOR_COMMANDS="$HOME/.cursor/commands"
    mkdir -p "$CURSOR_COMMANDS"

    for skill_file in "${SKILL_FILES[@]}"; do
        name="$(frontmatter_field "$skill_file" name)"
        skill_body "$skill_file" > "$CURSOR_COMMANDS/${name}.md"
        ok "  Wrote command: /${name} → $CURSOR_COMMANDS/${name}.md"
    done

    ok "Cursor CLI commands assembled (~/.cursor/commands/)"
else
    warn "Cursor CLI not found — skipping (install cursor to enable)"
fi
```

### Step 2 — Update README

- Add Cursor CLI to the supported agents table.
- Add it to the "How it works" diagram.
- Add row to the "Editing your setup" table (needs re-sync after edits).

### Step 3 — Commit & PR

Branch: `feat/cursor-support`

---

## Out of Scope

- Cursor IDE global rules — dropped entirely
- `cursor.meta` sidecar — not needed
- Linux paths — follow-up if needed
