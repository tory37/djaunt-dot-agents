---
name: trailofbits-skills
repo: trailofbits/skills
platforms: darwin linux
kind: clone
note: trailofbits/skills is CC-BY-SA. Read it locally. Never copy its text into djaunt-dot-agents.
---

# trailofbits-skills

Trail of Bits agent skills for testing and secure code. The agent reads them as vendor opinion. A rule never counts as proof alone. Each claim also needs an official doc. See `src/skills/djt-harness/citations.md`.

## License

CC-BY-SA. Read the files from the clone. Never copy or paraphrase their text into this repo. Copying would put this repo under the same license.

## What sync does

1. Clones `trailofbits/skills` to `~/src/skills`. Fast-forwards it if it exists.
2. Nothing else. No install step.

The clone name is generic. Set `DJAUNT_SRC_DIR` to move all companion clones.

## What the agent reads

- `plugins/property-based-testing/skills/property-based-testing/` — when and how to write property-based tests. Adding Hypothesis or fast-check to a target repo needs Tory's OK.
- `plugins/sharp-edges/skills/sharp-edges/` — APIs and patterns that fail in non-obvious ways. `references/lang-<language>.md` holds one file per language.
