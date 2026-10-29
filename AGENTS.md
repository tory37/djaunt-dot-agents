# djaunt-dot-agents — Working in This Repo

This is the portable AI agent config repo. It is **not** a product project — it is the source of truth for global AI instructions and skills deployed to all AI tools on this machine. Edit here; sync to propagate.

## Directory structure

```
src/
  AGENTS.md        — Global AI instructions (deployed to ~/.agents/AGENTS.md and each tool's config)
  skills/          — Shared skills (deployed to Claude Code, Gemini CLI)
scripts/
  sync.sh          — Deploys src/ to the active toolchain on this machine
tools/             — One file per outside dependency (companion repos, CLI tools). sync.sh reads these to install.
README.md          — Human-facing docs
```

## How to make changes

- **Edit global AI instructions:** `src/AGENTS.md` — re-run sync after saving
- **Edit a skill:** `src/skills/<name>/SKILL.md` — re-run sync to propagate to all tools
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
- `djt-work` and `djt-work-deep` share one flow. `djt-work-deep` adds only the teaching layer and points at `djt-work` steps by number. A change to the flow, gates, or step numbers in either skill must be made in both in the same commit. Then reread both and confirm every "djt-work step N" still names the right step.
