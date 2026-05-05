# djaunt-dot-agents

Your portable AI agent setup. Clone this repo on any machine, run one script, and your AI tools (Claude Code, Gemini CLI) are instantly configured with a shared system prompt, shared skills, and machine-specific extensions.

## What's in this repo

```
AGENTS.md          — The shared system prompt / global instructions for all AI agents
skills/            — Claude Code skills (slash commands) shared across all machines
  bug/SKILL.md
  feature/SKILL.md
  resume/SKILL.md
  suspend/SKILL.md
scripts/
  sync.sh          — The install/refresh script
```

## How it works

```
djaunt-dot-agents/
  AGENTS.md  ──(copy)──▶  ~/.agents/AGENTS.md
  skills/    ──(copy)──▶  ~/.agents/skills/
                                │
                    ┌───────────┴────────────┐
                    ▼                        ▼
          ~/.claude/CLAUDE.md        ~/.gemini/GEMINI.md
          (symlink)                  (symlink)
          ~/.claude/skills/          ~/.gemini/skills/
          (copy)                     (copy)
```

`~/.agents/AGENTS.md` is the single source of truth loaded by all agents. The symlinks in `~/.claude` and `~/.gemini` point back to it, so each AI tool sees the same instructions.

### Machine-specific extensions

Drop `.md` files in `~/.agents/extensions/` on any machine before (or after) running `sync.sh`. The script detects them and appends `@<path>` references into the local `~/.agents/AGENTS.md` above the end of the file, replacing the `PROJECT_EXTENSIONS_PLACEHOLDER` comment.

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

That's it. The script:
- Creates `~/.agents/` and copies `AGENTS.md` + `skills/` into it
- Injects `@` references to any files in `~/.agents/extensions/`
- Symlinks `~/.agents/AGENTS.md` → `~/.claude/CLAUDE.md` (if `~/.claude` exists)
- Copies skills into `~/.claude/skills/` (if `~/.claude` exists)
- Symlinks `~/.agents/AGENTS.md` → `~/.gemini/GEMINI.md` (if `~/.gemini` exists)
- Copies skills into `~/.gemini/skills/` (if `~/.gemini` exists)

## Keeping it up to date

Pull changes and re-run the sync script:

```bash
cd ~/src/djaunt-dot-agents
git pull
bash scripts/sync.sh
```

## Editing your setup

| What you want to change | Where to edit |
|---|---|
| Global AI instructions / persona | `AGENTS.md` in this repo |
| Shared skills (slash commands) | `skills/<name>/SKILL.md` in this repo |
| Machine-specific context | `~/.agents/extensions/<name>.md` on that machine |

After editing files in this repo, commit, push, then re-run `sync.sh` on each machine where you want the changes.

## A note on Gemini CLI skills

Claude Code has a native skill system: drop a `SKILL.md` into `~/.claude/skills/<name>/` and it becomes a `/name` slash command. Gemini CLI does not have an equivalent feature at this time. The sync script copies skills to `~/.gemini/skills/` for future-proofing, but they will not auto-load in Gemini without additional configuration.

## Extensions folder structure

Each extension file is a plain Markdown file. It can contain anything you'd put in `AGENTS.md` — coding standards, internal URLs, tool preferences, team conventions, etc.

```
~/.agents/
  extensions/
    work.md        ─ injected on your work laptop
    personal.md    ─ injected on your personal machine
    homelab.md     ─ injected on your home server
```

These files live only on the machine where they're relevant and are never committed to this repo.
