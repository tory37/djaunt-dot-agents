# djaunt-dot-agents

Your portable AI agent setup. Clone this repo on any machine, run one script, and your AI tools (Claude Code, Gemini CLI, Cursor CLI) are instantly configured with a shared system prompt, shared skills, and machine-specific extensions.

## Supported agents

| Agent | Status |
|-------|--------|
| [Claude Code](https://claude.ai/code) | Supported |
| [Gemini CLI](https://github.com/google-gemini/gemini-cli) | Supported |
| [Cursor CLI](https://cursor.com/docs/cli/overview) | Supported |

Other AI tools (Copilot, etc.) are not currently supported. The Cursor IDE (as distinct from the CLI) is also not supported.

## What's in this repo

```
CLAUDE.md          — Context for Claude Code when working in this repo
AGENTS.md          — Context for other agents (Codex, etc.) when working in this repo
GEMINI.md          — Context for Gemini CLI when working in this repo
src/
  AGENTS.md        — The shared system prompt / global instructions (deployed to all tools)
  skills/          — Shared skills (slash commands for Claude, inlined into Gemini)
    djt-bug/
      SKILL.md     — Claude Code loads this
      gemini.meta  — Gemini-specific trigger/notes (invisible to Claude)
    djt-feature/
      SKILL.md
      gemini.meta
    djt-resume/
      SKILL.md
      gemini.meta
    djt-suspend/
      SKILL.md
      gemini.meta
scripts/
  sync.sh          — The install/refresh script
```

## How it works

```
djaunt-dot-agents/
  src/AGENTS.md  ──(copy)──▶  ~/.agents/AGENTS.md  ──(symlink)──▶  ~/.claude/CLAUDE.md
  src/skills/    ──(symlink)─▶ ~/.agents/skills/   ──(symlink)──▶  ~/.claude/skills/
                                    │
                                    ├──(assembled)──▶  ~/.gemini/GEMINI.md
                                    │                  (AGENTS.md + all skills inlined)
                                    │
                                    └──(assembled)──▶  ~/.cursor/commands/<name>.md
                                                       (one file per skill, body only)
```

**Claude Code** gets skills natively — `~/.claude/skills/` is a symlink chain back to the repo, so edits are live immediately.

**Gemini CLI** has no native skill system. Instead, `sync.sh` assembles `~/.gemini/GEMINI.md` by taking `AGENTS.md` and inlining every skill after it, with natural-language trigger instructions. When you type `/feature` in Gemini, it reads the trigger from the inlined skill and follows the workflow. Re-run `sync.sh` after adding or editing skills to rebuild `GEMINI.md`.

**Cursor CLI** has a native commands system — `~/.cursor/commands/*.md`. `sync.sh` copies each skill body (frontmatter stripped) into a file there. When you type `/feature` in Cursor, it loads that file as the command prompt. Re-run `sync.sh` after adding or editing skills.

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

The script handles everything: creates `~/.agents/`, wires up Claude Code, Gemini CLI, and Cursor CLI, injects extensions, and assembles output files for each tool.

## Keeping it up to date

```bash
cd ~/src/djaunt-dot-agents
git pull
bash scripts/sync.sh
```

## Editing your setup

| What you want to change | Where to edit | Needs re-sync? |
|---|---|---|
| Global AI instructions | `src/AGENTS.md` | Yes |
| Skill workflow (all tools) | `src/skills/<name>/SKILL.md` | Claude: no — Gemini/Cursor: yes |
| Gemini trigger / notes for a skill | `src/skills/<name>/gemini.meta` | Yes |
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
