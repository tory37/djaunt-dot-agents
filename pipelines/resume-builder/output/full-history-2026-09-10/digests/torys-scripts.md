# torys-scripts

**Repo:** `AmiraLearning/torys-scripts` — "Scripts that Tory may need to do stuff, and doesn't want
to lose if his computer blows up" (JavaScript/Node.js, 673KB, private).
**Created:** 2023-09-20 · **Last push:** 2026-08-08 · **PRs by tory37:** 1 · **Commits by tory37:** 93
(2023-09-20 → 2025-09-24, ~2 years).

## Role and contribution

Despite the self-deprecating description, this is a **content-engineering and production-forensics
toolbox for Amira's assessment/story platform**, built and owned solo. Direct-to-main almost
throughout (1 PR total). Commit messages are near-useless ("stuff", "idk", "MMMbop") — all the
signal is in the diffs.

## What was actually built

### Network Monitoring Service (NMS) forensics (Sep–Dec 2023)
Built a log-forensics toolchain over the `amira-logging` S3 bucket to diagnose why student
tutoring sessions failed mid-activity when network quality degraded. Paginated S3 ingestion at
scale, event-timeline reconstruction from raw logs, and a set of hypothesis-targeted failure
finders (e.g. "did the activity end on a Disconnected/Critical event," "bad network in the first
second," "comprehension step started but no cleanup event ever followed"). Iterated concurrency
handling under memory pressure — went from an in-memory load-everything-then-write pattern
(flagged as a hazard in a code comment) to a disk-cached, pool-bounded pipeline, raising worker
concurrency 20→100 once memory was under control. Pulled data from GraphQL (Student Record Store),
Cognito (district user export), and Athena (a documented runbook query against the datalake).
Correlated a `struggle_monitor_disabled` feature-flag state with the failure signal.

### LLM-driven homonym metadata pipeline (Dec 2023 – Mar 2024)
A staged, resumable pipeline finding every homonym in Amira's story corpus and attaching the
correct sense-specific metadata (definition, phonetics, rhyme, fun fact, illustration) per
occurrence, so the reading tutor shows the right meaning of a word in the sentence a student is
reading. Full corpus scan over DynamoDB; three metadata-sourcing strategies tried in sequence
(dictionary API → internal word DB → GPT-4, batched and prompted as a "science-of-reading
expert"); defensive parsing that drops malformed LLM output rather than corrupting the pipeline;
sense disambiguation via a second GPT pass reading full story context; DALL·E-3 illustration
generation; a human-in-the-loop `inquirer` review step; and diff-only writes back to production
DynamoDB (only fields that differ from the default are written, minimizing blast radius). In
March 2024, collapsed ~15 loose step scripts into a single CLI app with declared per-script
requirements and confirmation prompts.

### Comprehension item migration (Apr–May 2024)
Full paginated scan of the story table, migrating interactive comprehension items into a
standalone Student Record Store via AppSync mutations, with modified/failed tracking and a
targeted-reprocess allowlist.

### 2025 assessment calibration content pipeline (Dec 2024 – Feb 2025)
Built MOY-2025 ISIP calibration forms from a Google Sheets master sheet into story records.
Migrated off Amplify to direct AppSync calls, batched single-story mutations into 25-per-request
calls with true exponential backoff, and removed a hardcoded API key in favor of an env var.
Generalized two bespoke per-type processors into one config-driven "master script" — a single
engine driven by per-run config modules declaring item type, sheet source, target fields, and
update mode (append/override/patch).

### AOS Item Service validation suite (2025, merged via the repo's one PR)
A rules-engine validator for a DynamoDB item store: declarative JSON schemas per item type with a
JavaScript escape hatch for rules that can't be expressed declaratively, template-interpolated
error messages, and timestamped HTML/JSON reports. Shipped alongside an assignment-status manager
letting QA force a specific activity to play next, with a full README.

### Smaller tooling
A duplicate-comprehension-question analyzer (normalize, cross-match, preview, remove
back-to-front to avoid index shifts), S3 activity-log fetch/order tooling, and a shared utility
layer (logging, CSV, Google Sheets auth, GraphQL client, S3, null-purging) built up incrementally
across the whole repo.

## Problems solved

- Diagnosed whether network degradation was actually killing student sessions, from raw event
  logs across thousands of activities — not a guess, a built forensics pipeline.
- Fixed a `DynamoDB.BatchGetItem` pagination bug where `ExclusiveStartKey` was reconstructed
  wrong, silently breaking scan resumption.
- Made GPT-4 usable as a metadata source for production content by treating it as an unreliable
  data source: strict CSV field-count validation, reject-and-log instead of silent corruption.
- Idempotency was a first-class concern throughout — nearly every long-running script re-reads
  its own output on startup to skip completed work, because these jobs run for hours against
  production content tables.

## Design decisions worth naming

- **Config-over-code generalization, twice.** Both the calibration pipeline and the homonym CLI
  went from a family of near-duplicate scripts to one engine plus declarative config — each
  refactor deleted more code than it added.
- **Dry-run by default.** Destructive writes gated behind explicit `--upload`/confirm flags, with
  file output written first for inspection.
- **Diff-only writes to production.** The homonym deploy step computes and writes only the delta
  from default values, not full-record overwrites.
- **Retry/backoff added reactively at AWS service boundaries** as real limits were hit (DynamoDB
  batch-get chunking, AppSync exponential backoff).

## Quantifiable signals

| Signal | Value |
|---|---|
| Commits (tory37) | 93 |
| PRs (tory37) | 1 |
| Active span | 2023-09-20 → 2025-09-24 (~2 years) |
| Largest single diff | ~4.2k changed lines across 23 code files |
| Backing stores touched | DynamoDB (story DB, AOS item store), AppSync, S3, Athena, Cognito |
| External APIs integrated | OpenAI GPT-4 chat, DALL·E-3, Google Sheets |

## Recommended resume use

Two distinct, strong bullet candidates hiding under a throwaway repo name:

1. **Production incident forensics** — built log-analysis tooling from raw S3 event data across
   thousands of activities to diagnose network-related session failures, with concurrency/memory
   engineering to make repeated large-scale sweeps feasible.
2. **LLM-assisted content pipeline, early-2024** — designed and shipped a GPT-4 + DALL·E-3 content
   pipeline for a children's reading product, with schema-validated LLM output parsing, a
   human review gate, and diff-only production writes — ahead of when LLM pipelines were routine.

Caveat: frame as "built internal tooling / pipelines," not "shipped a service" — this is
operator/content tooling, not customer-facing product code, and several scripts show
mid-experiment rough edges (commented-out alternate entry points, hardcoded bounds).
