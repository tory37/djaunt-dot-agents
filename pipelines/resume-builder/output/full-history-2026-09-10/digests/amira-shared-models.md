# amira-shared-models (amira-rnd)

**Verdict: trivial contribution — not resume-worthy on its own.**

## Repo context
- Python-only library (~1.59 MB Python, 100% of codebase). Created 2025-11-16, actively pushed through 2026-09-09. 1 star, 0 forks.
- Purpose: unified data-access layer for the Amira Learning platform — schema-driven Pydantic models with CRUD, multi-source access, auto-configured AWS client management via Secrets Manager. Every service reads/writes Amira resources through it instead of direct AWS/API calls.
- Covers SRS (Student Record Store), AOS (Assessment Orchestration), Assignment Service, SIS, EPS (EDM Pipeline Supervisor), Voice Ingestion, Calendar Service, and DataLake (Athena queries over `activities_v` / `assignments_v`).
- Code is GraphQL-schema-driven: `codegen/schemas/*.graphql` generates `src/amira_models/generated/**`.

## Tory's contribution
- **1 commit, 1 merged PR** — PR #138, "Rename beginningSoundConfig_ES to beginningLetterSoundConfig_ES", merged 2026-05-13.
- Diff: 6 additions / 6 deletions across 2 files — `codegen/schemas/srs-schema.graphql` and the corresponding generated `src/amira_models/generated/srs/__init__.py`.
- Substance: a field rename in the SRS GraphQL schema, propagated to generated Python models. Correctly touched both the source schema and the regenerated output, so the rename stayed consistent with the codegen pipeline. That is the only signal of note.
- No commits found under any other author-name/email variant ("Tory Hebert", tory*) — the single commit is the complete contribution.

## Quantifiable signals
| Signal | Value |
|---|---|
| Commits by tory37 | 1 |
| Merged PRs | 1 (#138) |
| Lines changed | 12 (6+ / 6−) |
| Files touched | 2 |
| Contribution span | single day, 2026-05-13 |

## Recommendation for synthesis
Do not give this repo its own resume bullet. At most, it is weak supporting evidence that Tory worked inside a shared, schema-generated Python data-access library for a multi-service education platform — usable only as a passing mention if a cluster bullet about the Amira platform's shared Python tooling needs one more repo name. It carries no ownership, design, or scope signal.
