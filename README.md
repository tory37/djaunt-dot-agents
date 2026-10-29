# djaunt-dot-agents

Your portable AI agent setup. Clone this repo on any machine, run one script, and your AI tools (Claude Code, Gemini CLI) are configured with a shared system prompt, shared skills, and machine-specific extensions.

## Supported agents

| Agent | Status |
|-------|--------|
| [Claude Code](https://claude.ai/code) | Supported |
| [Gemini CLI](https://github.com/google-gemini/gemini-cli) | Supported |

Other AI tools are not supported.

## What's in this repo

```
CLAUDE.md          — Context for Claude Code when working in this repo
AGENTS.md          — Context for other agents (Codex, etc.) when working in this repo
GEMINI.md          — Context for Gemini CLI when working in this repo
src/
  AGENTS.md        — The shared system prompt / global instructions (deployed to all tools)
  assets/          — Reference files the instructions point to (copied to ~/.agents/assets/)
  claude-settings.json — Owned keys merged into ~/.claude/settings.json by sync
  statusline-command.sh — Claude Code status line (installed to ~/.claude/)
  skills/          — Shared skills (slash commands for Claude, inlined into Gemini)
    djt-work/
      SKILL.md     — Claude Code loads this
      gemini.meta  — Gemini-specific trigger/notes (invisible to Claude)
    djt-harness/   — Shared layer for djt-work and djt-work-deep (not a slash command)
scripts/
  sync.sh          — The install/refresh script
  check-budget.sh  — Token budget check for AGENTS.md and each SKILL.md (sync runs it)
tools/             — One file per outside dependency. sync.sh reads these to install them.
```

## Skills

| Skill | What it does |
|---|---|
| [`djt-work`](src/skills/djt-work/) | Workflow for a feature, bug, or refactor. Phases, tests, user gate, commit. |
| [`djt-work-deep`](src/skills/djt-work-deep/) | The `djt-work` flow with a teaching layer. |
| [`djt-test-plan`](src/skills/djt-test-plan/) | Change-scoped manual test plan. One plan for the author and QA. Generates mitmweb fault-injection scripts. |
| [`djt-frontend-design`](src/skills/djt-frontend-design/) | UI design and build. Declares design reasoning before code. Bans the default AI look. |

### djt-work vs djt-work-deep

Both skills run the same flow and the same gates. Both hold the same correctness bar: the repo's own lints pass, and each design choice cites an official source.

`djt-work-deep` adds a learning layer:

- **Recon** — a first pass over the codebase before the plan.
- **Micro-phases** — smaller phases than `djt-work`.
- **A cited brief per phase** — an HTML page that teaches what changed and why.

A change to the flow, gates, or step numbers goes into both skills in the same commit.

### The harness

[`src/skills/djt-harness/`](src/skills/djt-harness/) is a shared layer for both work skills. It has no `SKILL.md`, so it is not a slash command.

- [`citations.md`](src/skills/djt-harness/citations.md) — evidence rules. Every design choice cites a source.
- [`stacks/`](src/skills/djt-harness/stacks/) — one file per stack (`react`, `js-ts`, `python`, `html-css`, `aws`). Each says how to detect the stack and find the repo's lint commands.
- [`scripts/docs-mcp`](src/skills/djt-harness/scripts/docs-mcp) — queries a remote MCP docs server (AWS, MDN) without registering it. No accounts needed.

The skills load each file just in time: `citations.md` before the plan, a stack file only at the step that names it.

## Outside dependencies

[`tools/README.md`](tools/README.md) lists every dependency outside this repo: companion repos that sync installs, and rule packs that sync only clones. It also gives the tool file format.

## How it works

```
djaunt-dot-agents/
  src/AGENTS.md  ──(copy)──▶  ~/.agents/AGENTS.md  ──(symlink)──▶  ~/.claude/CLAUDE.md
  src/skills/    ──(symlink)─▶ ~/.agents/skills/   ──(symlink)──▶  ~/.claude/skills/
                                    │
                                    └──(assembled)──▶  ~/.gemini/GEMINI.md
                                                       (AGENTS.md + all skills inlined)
  src/assets/    ──(copy)──▶  ~/.agents/assets/
  tools/*.md     ──(clone/install)──▶  companion repos under $DJAUNT_SRC_DIR (default ~/src)
```

**Claude Code** gets skills natively — `~/.claude/skills/` is a symlink chain back to the repo, so edits are live immediately.

**Gemini CLI** has no native skill system. Instead, `sync.sh` assembles `~/.gemini/GEMINI.md` by taking `AGENTS.md` and inlining every skill after it, with natural-language trigger instructions. When you type `/djt-work` in Gemini, it reads the trigger from the inlined skill and follows the workflow. Re-run `sync.sh` after adding or editing skills to rebuild `GEMINI.md`.

Gemini gets only skill folders that have both `SKILL.md` and `gemini.meta`. A `reference.md` beside the skill is appended after the body.

Before it deploys anything, `sync.sh` runs `scripts/check-budget.sh`. It aborts if `src/AGENTS.md` or a `SKILL.md` is over budget.

### The gemini.meta file

Each skill folder contains a `gemini.meta` file with Gemini-specific metadata that `sync.sh` uses when assembling `GEMINI.md`. Claude Code never loads this file, so it costs zero context.

```
trigger: When the user types /djt-work or asks to build a feature, fix a bug, or refactor, ...
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

The script creates `~/.agents/`, wires up Claude Code and Gemini CLI, injects extensions, and installs the tools in `tools/`. It skips Claude Code or Gemini CLI when its config folder (`~/.claude`, `~/.gemini`) is missing.

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
| Skill workflow (all tools) | `src/skills/<name>/SKILL.md` | Claude: no — Gemini: yes |
| Gemini trigger / notes for a skill | `src/skills/<name>/gemini.meta` | Yes |
| Shared layer for the work skills | `src/skills/djt-harness/` | No (symlinked) |
| Reference assets | `src/assets/<name>.md` | Yes |
| Claude Code settings keys | `src/claude-settings.json` | Yes |
| Outside dependency | `tools/<name>.md` | Yes |
| Machine-specific context | `~/.agents/extensions/<name>.md` | Yes |

## Context compaction

Claude's `/compact` and Gemini's `/compress` take free-text steering, but neither auto-applies a saved rule. Paste this as the argument each time:

```text
Compact aggressively. Drop: file contents, code snippets, resolved debugging steps, dead-end exploration, prior conversational turns. Keep: a 1-2 sentence summary of the overarching feature/mission, what phase just finished and the specific objective for the next phase, file paths as pointers only (do not re-summarize their contents), and any open question blocking the next step.
```

## Extensions folder structure

```
~/.agents/
  extensions/
    work.md        ─ injected on your work laptop
    personal.md    ─ injected on your personal machine
    homelab.md     ─ injected on your home server
```

These files live only on the machine where they're relevant and are never committed to this repo.
