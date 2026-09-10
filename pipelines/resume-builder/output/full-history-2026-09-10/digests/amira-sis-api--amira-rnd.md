# amira-rnd/amira-sis-api

**Repo ID:** 921229668 (distinct from `AmiraLearning/amira-sis-api` — digested separately)
**Private.** Created 2025-01-23, last push 2026-09-08. 0 stars, 0 forks.
**Languages:** JavaScript (~60 KB), Shell (~31 KB), Makefile.
**Purpose:** GraphQL (AWS AppSync) interface over the Amira SIS hierarchy — districts, schools, classrooms, students, teachers — resolving across Magic, Amira SIS Cloud Directory, AtHome, and archived S3 sources. Deployed as a SAM/CloudFormation stack fronting Lambda resolvers.

## Tory's contribution

**Volume:** 6 commits (4 content + 2 merge), 0 PRs authored under the `tory37` login in this repo. Activity window: 2024-02-14 to 2024-06-18.

**Important caveat for synthesis:** this repo was created 2025-01-23 but carries pre-existing git history from `AmiraLearning/amira-sis-api` — Tory's commits here date to 2024 and their merge commits reference `AmiraLearning/...` branches (`teacher-email-modal-boolean` PR `no.46`, `hasSeenDialogFTUE-boolean` PR `no.49`). These are almost certainly the **same commits** already counted in the AmiraLearning digest, inherited via history import rather than authored twice. **Do not double-count** these 6 commits at synthesis time.

**What the diffs actually show** (all four content commits touch one file, `sis_api_schema.graphql`):

1. `3d8ad58` (2024-02-14) — added `hasSeenCaptureEmailModal: Boolean` to both the `updateStudentMetadata` mutation signature and the `StudentMetadata` type. Backs a client-side flag tracking whether a student saw the teacher email-capture modal. +2 lines.
2. `db6074e` (2024-06-18) — added `hasSeenDialogFTUE: Boolean` to the same mutation and type. Backs first-time-user-experience dialog state. Real change is +2 lines; the commit's 89/87 line count is inflated by an editor-driven tab-to-space reindent of the whole schema file.
3. `28e0dca` + `79a33cc` (2024-06-18, both "cleanup") — **pure whitespace churn.** Reverted the accidental reindent back to tabs and fixed the two stragglers. Zero semantic change. Excluded as noise per diff-sampling guidance.

## Assessment for resume purposes

**Low signal.** Net real work is two Boolean fields added to a GraphQL schema — client UI-state flags plumbed through the SIS API so the student app could persist "has seen X" across sessions. No resolver logic, no infrastructure, no tests, no design decisions. Tory is not a primary contributor to this repo; the bulk of the codebase belongs to other engineers (Chris Royce, Paul Nicksich, Rob Arseneault, David Maharry, Michael Tarleton, Derek Nicol).

**Only usable angle:** evidence of cross-boundary work — persisting frontend UX state through a shared GraphQL/AppSync schema contract consumed by multiple clients. Weak on its own; worth folding into a larger "Amira student-facing platform" cluster bullet, never its own bullet.

**Tech touched:** GraphQL schema design (AWS AppSync SDL), student-metadata data modeling.

## Quantifiable signals

- 6 commits (4 content, 2 merge); 2 net-new schema fields
- 2 feature branches merged (`teacher-email-modal-boolean`, `hasSeenDialogFTUE-boolean`)
- Contribution span: 4 months (2024-02 to 2024-06)
- Repo scale signals (stars/forks) are zero — private internal service, not meaningful
