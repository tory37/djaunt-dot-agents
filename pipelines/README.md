# pipelines/

Standalone, multi-stage workflows that don't belong in `src/skills/` (globally
synced, agent-agnostic) or `tools/` (per-project opt-in installs). A pipeline
here is personal automation that lives and runs from this repo directly.

## What makes something a pipeline instead of a skill or tool

- It's driven by external data (GitHub, an API, a large pull) rather than
  pure codebase reasoning.
- The data volume is too large to hold in context at once — a pipeline
  writes intermediate state to disk in stages and only re-reads the small,
  digested output of each stage, not the raw pull.
- It's not something every project needs synced in (`src/skills/`) or a
  specific project opts into (`tools/`) — it's run directly against this
  repo checkout, on demand.

## Layout convention

```
pipelines/<name>/
  PIPELINE.md          — entry point: stage-by-stage instructions for the agent
  references/          — static reference material the pipeline consults
                          (avoids re-deriving the same guidance, or a live
                          web search, on every run)
  output/               — gitignored run data (raw pulls, digests, final result)
    .gitkeep
  .gitignore
```

## Running a pipeline

There's no slash command. Point the agent at the entry doc directly, e.g.:

> Run the pipeline in `pipelines/resume-builder/PIPELINE.md`

The agent reads `PIPELINE.md` and executes it stage by stage.

## Available pipelines

- **`resume-builder/`** — pulls your GitHub repo/commit/PR history and
  synthesizes one consolidated, copy-paste-ready resume section.
