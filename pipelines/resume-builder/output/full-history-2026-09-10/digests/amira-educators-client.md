# amira-educators-client

**Repo:** `amira-rnd/amira-educators-client` — "The Amira teacher's app, reports, admin configurations
and dashboards." (React + TypeScript, Redux Toolkit, ~17MB, private).
**Created:** 2024-10-15 · **Last push:** 2026-09-10 · **PRs by tory37:** 9 · **Commits by tory37:** 125
(2025-04-16 → 2026-08-25, ~16 months).

## Role and contribution

Sole/primary frontend engineer across the district-admin and teacher configuration surfaces of
Amira's educator suite — assessment configuration, screening-window scheduling, assignment
management, and reporting. Ticket-driven (JIRA `ASSMNT-*`, `CR-*`, `WOM-*`), feature-flag-gated,
multi-environment (dev/prod/Canada) delivery, with heavy automated (Bugbot, Claude review) and
human PR review absorbed as real correctness fixes, not rubber-stamping.

## What was actually built

### Spanish (Evaluar) bilingual assessment program — the dominant body of work
Designed and built the full district-facing configuration and scheduling story for a
Spanish-language reading assessment, staged behind feature flags through a pilot rollout across
dev → prod → Canada. Authored a 12-task Spanish blueprint config model with per-grade defaults
across K-8 + Pre-K, three cell states (on/editable/locked) per task-grade pair, mapped to 14 new
license fields across the GraphQL contract. Added language-aware screening windows (EN/ES/BOTH),
a "Split by Language" action, language-aware date/grade-overlap validation, and a manifest-building
rewrite that infers locale from license + grade instead of naively swapping strings in place.
Restricted the whole app for Spanish-pilot districts via a dedicated entitlement selector and
route/nav filters. This work continued for months, evolving into a full BTS (Back-To-School,
independent per-locale windows) mode running side-by-side with legacy scheduling — nearly every
downstream change had to behave correctly in both modes, for four admin role tiers, across
district- vs school-scoped selection.

### Entitlement/licensing correctness — a recurring class of bug hunted and fixed systematically
Repeatedly found and fixed cases where three distinct states (loading / error / empty-because-
unsubscribed) collapsed into one misleading message: an `isLoading` flag initialized from a
`null` value that flashed an empty state for one render; a roster-load failure that looked
identical to "no subscription"; a license fetch that swallowed network errors and resolved
`undefined` instead of rejecting. Fixed each at the signal level (extracted hooks like
`useScreeningWindowSubscriptions`) rather than patching the symptom, with tests pinning the fix.

### Screening-window scheduling engine
Built duplicate-window detection (with an async-race hardening pass after review caught a stale
dedup key), a three-phase "window now spans multiple calendar months" detector with a blocking
confirmation modal, and fixes for an inclusive/exclusive date-boundary bug, a grade-only overlap
filter that ignored language and clamped the wrong window's dates, and a spurious unsaved-changes
warning caused by derived-field effects mutating state without updating the change-detection
baseline.

### IRIP (Individualized Reading Intervention Plan) DOCX generator — built solo from zero in under 4 weeks
A full client-side Word-document export pipeline: one button produces a ZIP of per-student
intervention-plan documents. The hard problem solved was rendering the app's live interactive
React/D3 report components (no static export path) into a Word document — mounted the real report
components offscreen, waited for explicit data-ready promise resolvers (after two earlier
timing-based approaches proved unreliable), then rasterized the DOM into a docx image. Refactored
mid-build to drive the export through the app's actual report data path and Redux selectors
instead of a duplicated fetch, so the exported document matches what the teacher sees on screen.
Config-gated every document section behind a boolean flag for incremental stakeholder delivery,
and isolated per-student failures so one bad record doesn't kill a class-wide export.

### School-year scoping and assignment-date correctness
Threaded a `schoolYear` parameter through the entire assignment GraphQL surface (queries and
mutations) with an explicit precedence chain for resolving it, fixing a TypeScript typing gap
along the way that had silently stripped thunk typing from the dispatch type. Fixed
Progress-Monitoring/Benchmark assignments expiring at the wrong time by deriving `dateTo` from the
school-year end date consistently across every call site.

### Other shipped features
An "Adaptive SODA" district assessment setting; a timer-accommodation feature (1.25x-1.75x time
extensions) shipped DEV-gated first then released; a required backdated "date of assessment"
picker for paper-and-pencil score entry, ordered so a backdate failure never forces re-entry of
already-saved scores; a Comprehension Report Card UI/audio rewrite (CSS restructure, hotlinked
avatar replacement, playback-error debugging with a ready-to-paste curl repro).

## Problems solved

- Rendering interactive React chart components into a static Word document — no existing export
  path, solved with offscreen mounting + explicit ready signals + DOM rasterization.
- Multiple "which state is this really in" bugs where licensing/subscription status collapsed
  loading, error, and empty into an indistinguishable UI message.
- A language-overlap validator gap letting an English window's date-conflict rule clamp a Spanish
  window's dates, and a picker/validator mismatch it introduced for BTS-off districts.
- A duplicate local role-mapping function that silently overwrote the correct admin-permission
  dispatch, locking Campus Managers out of settings they should have had.

## Design decisions worth naming

- Config/flag-gated feature delivery throughout, with explicit flag-off behavior preservation
  tested and reviewed as its own concern — not an afterthought.
- Fixed root-cause signals rather than symptoms as standard practice: repeatedly traced a UI glitch
  back to two conflated states and separated them, rather than patching the visible symptom.
- Tests ship with fixes at high ratio — several commits are majority test lines by count.
- Staged rollout discipline: dev → prod → Canada, with named districts driving specific
  entitlement-bypass work.

## Quantifiable signals

| Signal | Value |
|---|---|
| Commits (tory37) | 125 |
| PRs (tory37) | 9 |
| Active span | 2025-04-16 → 2026-08-25 (~16 months) |
| Tracked tickets closed | 40+ distinct JIRA keys (ASSMNT-*, CR-*, WOM-*) across the window |
| Largest single PR | ~2,700 lines across 31 files (Spanish assessment config) |
| Stack | React, TypeScript, Redux Toolkit, GraphQL, SCSS, i18next (4-language), docx/JSZip |

## Recommended resume use

One of the strongest repos in this run — a sustained, ~16-month feature-owner role on a
production admin/teacher app, with a clear headline feature (bilingual assessment program, built
end to end) and a distinctive built-from-scratch technical story (the DOCX report generator) to
anchor a second bullet if needed. Root-cause debugging discipline and staged-rollout ownership are
strong supporting evidence, not just feature-shipping.
