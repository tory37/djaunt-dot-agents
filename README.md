# djaunt-dot-agents

Your portable AI agent setup. Clone this repo on any machine, run one script, and your AI tools (Claude Code, Gemini CLI) are instantly configured with a shared system prompt, shared skills, and machine-specific extensions.

## What's in this repo

```
AGENTS.md          — The shared system prompt / global instructions for all AI agents
skills/            — Shared skills (slash commands for Claude, inlined into Gemini)
  bug/
    SKILL.md       — Claude Code loads this
    gemini.meta    — Gemini-specific trigger/notes (invisible to Claude)
  feature/
    SKILL.md
    gemini.meta
  resume/
    SKILL.md
    gemini.meta
  suspend/
    SKILL.md
    gemini.meta
scripts/
  sync.sh          — The install/refresh script
```

## How it works

```
djaunt-dot-agents/
  AGENTS.md  ──(copy)──▶  ~/.agents/AGENTS.md  ──(symlink)──▶  ~/.claude/CLAUDE.md
  skills/    ──(symlink)─▶ ~/.agents/skills/   ──(symlink)──▶  ~/.claude/skills/
                                │
                                └──(assembled)──▶  ~/.gemini/GEMINI.md
                                                   (AGENTS.md + all skills inlined)
```

**Claude Code** gets skills natively — `~/.claude/skills/` is a symlink chain back to the repo, so edits are live immediately.

**Gemini CLI** has no native skill system. Instead, `sync.sh` assembles `~/.gemini/GEMINI.md` by taking `AGENTS.md` and inlining every skill after it, with natural-language trigger instructions. When you type `/feature` in Gemini, it reads the trigger from the inlined skill and follows the workflow. Re-run `sync.sh` after adding or editing skills to rebuild `GEMINI.md`.

### The gemini.meta file

Each skill folder contains a `gemini.meta` file with Gemini-specific metadata that `sync.sh` uses when assembling `GEMINI.md`. Claude Code never loads this file, so it costs zero context.

```
trigger: When the user types /feature or asks to implement a new feature, ...
notes:   File argument: instead of @path syntax, provide the path as plain text.
```

- `trigger` — the natural-language "when to use this" line prepended before the skill body in GEMINI.md
- `notes` — optional Gemini-specific caveat rendered as a blockquote (omit the line if not needed)

### Machine-specific extensions

Drop `.md` files in `~/.agents/extensions/` on any machine. The script detects them and injects `@<path>` references into the local `~/.agents/AGENTS.md`, replacing the `PROJECT_EXTENSIONS_PLACEHOLDER` comment.

Example: `~/.agents/extensions/work.md` might contain your company's coding standards, internal tool references, or anything else that belongs on your work laptop but not your personal machine.

## Getting started on a new machine

```bash
# 1. Clone the repo
git clone https://github.com/toryhebert/djaunt-dot-agents.git ~/src/djaunt-dot-agents
cd ~/src/djaunt-dot-agents

# 2. (Optional) Add machine-specific extensions before syncing
mkdir -p ~/.agents/extensions
# e.g.: cp ~/my-work-context.md ~/.agents/extensions/work.md

# 3. Run the sync script
bash scripts/sync.sh
```

The script handles everything: creates `~/.agents/`, wires up Claude Code and Gemini CLI, injects extensions, and assembles `GEMINI.md`.

## Keeping it up to date

```bash
cd ~/src/djaunt-dot-agents
git pull
bash scripts/sync.sh
```

## Editing your setup

| What you want to change | Where to edit | Needs re-sync? |
|---|---|---|
| Global AI instructions | `AGENTS.md` in this repo | Yes |
| Skill workflow (both tools) | `skills/<name>/SKILL.md` | Claude: no — Gemini: yes |
| Gemini trigger / notes for a skill | `skills/<name>/gemini.meta` | Yes |
| Machine-specific context | `~/.agents/extensions/<name>.md` | Yes |

## Extensions folder structure

```
~/.agents/
  extensions/
    work.md        ─ injected on your work laptop
    personal.md    ─ injected on your personal machine
    homelab.md     ─ injected on your home server
```

These files live only on the machine where they're relevant and are never committed to this repo.
