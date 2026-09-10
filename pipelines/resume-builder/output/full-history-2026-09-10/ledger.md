# Ledger — full-history-2026-09-10

**Status:** IN_PROGRESS
**Started:** 2026-09-10
**Login:** tory37

## Scope decisions

- Personal repos: included (all of tory37's own repos).
- Orgs included: AmiraLearning, amira-rnd, istation-cloud, istation-hydra.
- Orgs excluded: hyperdesk-alliance (unclear relevance, not confirmed), EpicGames (not Amira-related).

## Stage 1 — Discover

- [ ] Personal repos listed (`gh repo list tory37`)
- [x] AmiraLearning scanned and filtered by authorship (280 scanned, 17 kept: amira-student-record-store, lexa-studentapp, amira-admin-reports-domo, amira-assignment-service, amira-parent-portal, content-deployment-pipeline, amira-story-editor, studentapp-AI, amira-configuration-manager, amira-intervention-library, torys-scripts, amira-sis-api, amira-intervention-selection, evaluar-blueprint-testing, network-monitoring-service-analyzer, AmiraAnimalRescue, cordova-plugin-googleplus)
- [x] amira-rnd scanned and filtered by authorship (125 scanned, 8 kept: amira-forge, assessments-data, amira-educators-client, amira-shared-models, amira-sis-api, student-shared-services, torys-script-library, assessments-item-bank-reviewer)
- [x] istation-cloud scanned and filtered by authorship (106 scanned, 1 kept: isweb)
- [x] istation-hydra scanned and filtered by authorship (26 scanned, 2 kept: olp-student-experience, olp-html-practice)
- [x] repos.json merged (personal + org fragments) — 103 total: 75 personal, 17 AmiraLearning, 8 amira-rnd, 1 istation-cloud, 2 istation-hydra
- [ ] Condensed table presented to user in chat

## Stage 2 — Scope with the user

- [x] selected-repos.json written — 28 org repos, no cuts (user confirmed "no cuts").
      Personal repos (75) not yet scoped — separate Stage 2 pass pending.

## Stage 3 — Per-repo deep analysis

Note: `amira-sis-api` exists in both AmiraLearning (id 184444296, created
2019-05-01) and amira-rnd (id 921229668, created 2025-01-23) — confirmed
via `gh api repos/<org>/amira-sis-api --jq '{id,full_name,created_at}'`
to be two distinct repos, not a mirror/duplicate. Both analyzed separately.

Commit counts (by author=tory37, via commits API Link-header pagination,
not Search — Search 404s across these orgs) determined chunking:
5 repos exceed ~60 commits and are batched by commit-API page number
(per_page=50) instead of date range — simpler and exact since the
commits endpoint paginates directly.

- lexa-studentapp: 384 commits → 8 batches (pages 1-8)
- amira-educators-client: 125 commits → 3 batches (pages 1-3)
- AmiraAnimalRescue: 102 commits → 3 batches (pages 1-3)
- torys-scripts: 93 commits → 2 batches (pages 1-2)
- amira-parent-portal: 68 commits → 2 batches (pages 1-2)

- [x] AmiraLearning/amira-student-record-store
- [ ] AmiraLearning/lexa-studentapp (384 commits, 8 batches)
  - [ ] batch 1/8 (page 1)
  - [x] batch 2/8 (page 2)
  - [ ] batch 3/8 (page 3)
  - [x] batch 4/8 (page 4)
  - [x] batch 5/8 (page 5)
  - [x] batch 6/8 (page 6)
  - [ ] batch 7/8 (page 7)
  - [x] batch 8/8 (page 8)
  - [ ] merged into digest
- [x] AmiraLearning/amira-admin-reports-domo
- [x] AmiraLearning/amira-assignment-service
- [x] AmiraLearning/amira-parent-portal (68 commits, 2 batches)
  - [x] batch 1/2 (page 1)
  - [x] batch 2/2 (page 2)
  - [x] merged into digest
- [x] AmiraLearning/content-deployment-pipeline
- [x] AmiraLearning/amira-story-editor
- [x] AmiraLearning/studentapp-AI
- [x] AmiraLearning/amira-configuration-manager
- [x] AmiraLearning/amira-intervention-library
- [x] AmiraLearning/torys-scripts (93 commits, 2 batches)
  - [x] batch 1/2 (page 1)
  - [x] batch 2/2 (page 2)
  - [x] merged into digest
- [x] AmiraLearning/amira-sis-api
- [x] AmiraLearning/amira-intervention-selection
- [x] AmiraLearning/evaluar-blueprint-testing
- [x] AmiraLearning/network-monitoring-service-analyzer
- [x] AmiraLearning/AmiraAnimalRescue (102 commits, 3 batches)
  - [x] batch 1/3 (page 1)
  - [x] batch 2/3 (page 2)
  - [x] batch 3/3 (page 3)
  - [x] merged into digest
- [x] AmiraLearning/cordova-plugin-googleplus
- [x] amira-rnd/amira-forge
- [x] amira-rnd/assessments-data
- [x] amira-rnd/amira-educators-client (125 commits, 3 batches)
  - [x] batch 1/3 (page 1)
  - [x] batch 2/3 (page 2)
  - [x] batch 3/3 (page 3)
  - [x] merged into digest
- [x] amira-rnd/amira-shared-models
- [x] amira-rnd/amira-sis-api
- [x] amira-rnd/student-shared-services
- [x] amira-rnd/torys-script-library
- [x] amira-rnd/assessments-item-bank-reviewer
- [x] istation-cloud/isweb
- [x] istation-hydra/olp-student-experience
- [x] istation-hydra/olp-html-practice

## Stage 4 — Cross-repo synthesis

- [ ] Synthesis complete

## Stage 5 — Final output

- [ ] resume-summary.md written

## Resume notes

- 2026-09-10: Run started. User confirmed org scope via AskUserQuestion:
  AmiraLearning, amira-rnd, istation-cloud + istation-hydra in; hyperdesk-alliance
  and EpicGames out. Personal-repo dry run already done separately under
  `output/dryrun/` (two low-signal repos, not part of this run).
- 2026-09-10 ~16:17 local: All 23 single-pass org repos digested and
  committed. Moved to the 5 large chunked repos — wrote repo-context.md
  for all 5 (lexa-studentapp, amira-parent-portal, torys-scripts,
  AmiraAnimalRescue, amira-educators-client), committed. Launched 4 batch
  subagents (amira-parent-portal batches 1-2, torys-scripts batches 1-2);
  all 4 failed with "session limit · resets 5:20pm America/Chicago" before
  writing any digest output. Confirmed no partial files were written —
  only repo-context.md exists in each dir, already committed. Nothing lost.
  **Resume point:** re-launch batch subagents for amira-parent-portal
  (batch 1/2, 2/2) and torys-scripts (batch 1/2, 2/2) per the Stage 3
  chunking plan above. AmiraAnimalRescue (3 batches), amira-educators-client
  (3 batches), and lexa-studentapp (8 batches) haven't been started yet.
  Personal repos (75) Stage 2 scoping also still pending — was deferred
  earlier in this run to focus on orgs first.
