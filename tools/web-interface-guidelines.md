---
name: web-interface-guidelines
repo: vercel-labs/web-interface-guidelines
platforms: darwin linux
kind: clone
---

# web-interface-guidelines

Vercel's web interface rules: accessibility, forms, focus, motion, layout, and copy. The agent reads them as vendor opinion. A rule never counts as proof alone. Each claim also needs an official doc. See `src/skills/djt-harness/citations.md`.

## What sync does

1. Clones `vercel-labs/web-interface-guidelines` to `~/src/web-interface-guidelines`. Fast-forwards it if it exists.
2. Nothing else. No install step.

## What the agent reads

- `command.md` — the full rule list.

Vercel's `web-design-guidelines` skill fetches this file live from `main`. The agent reads the local clone instead, so the text only changes when sync runs.
