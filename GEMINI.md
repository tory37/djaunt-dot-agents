# djaunt-dot-agents — Working in This Repo

This is the portable AI agent config repo. It is **not** a product project — it is the source of truth for global AI instructions and skills deployed to all AI tools on this machine. Edit here; sync to propagate.

## Directory structure

```
src/
  AGENTS.md        — Global AI instructions (deployed to ~/.agents/AGENTS.md and each tool's config)
  skills/          — Shared skills (deployed to Claude Code, Cursor CLI, Gemini CLI)
scripts/
  sync.sh          — Deploys src/ to the active toolchain on this machine
setup/
  tools.md         — Bootstrap guide for CLI tools on a new machine
tools/             — Optional add-on integrations (djt-trello, djt-project-sync, etc.)
README.md          — Human-facing docs
```

## How to make changes

- **Edit global AI instructions:** `src/AGENTS.md` — re-run sync after saving
- **Edit a skill:** `src/skills/<name>/SKILL.md` — re-run sync to propagate
- **Add a skill:** create `src/skills/<name>/SKILL.md` + `gemini.meta` — re-run sync

```bash
bash scripts/sync.sh
```

## Output

Files produced while working on this repo (plans, analysis, session snapshots) go in `.agents/output/` with the appropriate subfolder:

```
.agents/output/
  features/<name>/plan.md
  bugs/<name>/fix-plan.md
  techdebt/<name>/plan.md
  research/<topic>-<date>.md
  sessions/<slug>.md
```

## Rules

- Never manually edit deployed files in tool config dirs — always edit `src/` and sync
- Never commit machine-specific extensions (those live in `~/.agents/extensions/` only)
- Skills in `src/skills/` are loaded by all supported agents — keep them agent-agnostic
