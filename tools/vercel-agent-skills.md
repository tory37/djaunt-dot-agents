---
name: vercel-agent-skills
repo: vercel-labs/agent-skills
platforms: darwin linux
kind: clone
---

# vercel-agent-skills

Vercel's agent rule packs for React and web UI. The agent reads them as vendor opinion. A rule never counts as proof alone. Each claim also needs an official doc. See `src/skills/djt-harness/citations.md`.

## What sync does

1. Clones `vercel-labs/agent-skills` to `~/src/agent-skills`. Fast-forwards it if it exists.
2. Nothing else. No install step.

## What the agent reads

- `skills/react-best-practices/rules/` — one file per rule. The filename prefix names the category: `rerender-`, `js-`, `rendering-`, `server-`, `async-`, `bundle-`, `client-`, `advanced-`.
- `skills/composition-patterns/rules/` — component API and composition rules.
- `skills/web-design-guidelines/SKILL.md` — the review process. Its rules come from `web-interface-guidelines.md` instead of a live fetch.

The stack files in `src/skills/djt-harness/stacks/` name which rule files to load for which change.
