# content-deployment-pipeline (AmiraLearning)

**Repo purpose:** Processes newly published reading stories and words for the Amira
literacy platform — writes story metadata and word psychometrics, and generates
story-recommendation theta artifacts. Python-dominant (~1.29 MB Python, plus Rust
IRT, R, Docker, Make). Created 2022-03; still actively pushed as of 2026-09.
Private org repo, 1 star, 0 forks — scale signal is not stars, it's that it feeds
production content for a K-5 reading product.

## Tory's role and contribution window

- 21 commits authored, all between **2023-09-14 and 2023-10-18** (~5 weeks).
- 9 PRs authored, **all 9 merged**.
- Scope was tightly bounded: he owned one vertical — the **word "default
  intervention" nightly job** — from greenfield to production-deployed cron.
  Every commit touches `default_intervention/` or its entrypoint; he did not
  work in the older story-processing side of the repo.
- Work pattern visible in the history: build the whole job in one large commit,
  then a rapid tail of small production-tuning commits (date bumps, logging
  upgrades, breakpoint removal, a revert) as it was pushed through stage into prod.

## What he actually built (verified from diffs, not commit messages)

### 1. Greenfield nightly batch job — AWS Lambda + SAM (`17b864eb`, +917/-0 across 21 files)

Commit message says only "Initial setup of lambda cron job." The diff is the
entire service:

- **Handler architecture:** `event_handler.py` with a `handler_factory(kind)`
  dispatch, an abstract `Handler` base class, and `NightlyJobHandler` — a
  pluggable pattern sized for more handlers than the one that existed.
- **DynamoDB full-table export** (`word_db_to_csv.py`): paginates the
  `PsycholinguisticsStore` table with `LastEvaluatedKey`, deserializes marshalled
  DynamoDB types via `TypeDeserializer`, and streams to locale-split CSVs
  (`en_US` / `es_MX`) with progress logging every 5,000 words.
- **Bulk DynamoDB writes with backpressure handling**
  (`upload_to_intervention_selection_db.py`): batches rows into
  `transact_write_items` calls of 15, catches
  `ProvisionedThroughputExceededException`, and retries with exponential backoff
  (0.5 s base, 5 max retries). This is the non-obvious engineering in the repo —
  the naive version of this job would have throttled itself out of production.
- **Lambda-compatible filesystem rewrite:** took a data-scientist script that
  read and wrote to `~/Desktop/intervention_test_data/...` with `os.system("aws
  s3 sync ...")` and hardcoded local paths, and converted it to boto3
  `s3.download_file` against explicit keys writing into Lambda's `/tmp`, with the
  functions returning output paths instead of side-effecting to disk.
- **Thread-safe singleton logger** (`logger.py`) with separate local vs. cloud
  formats, driven by `LOG_FMT` / `LOGLEVEL`.
- **Deploy tooling:** `Makefile` wrapping `sam build --use-container`, `sam
  package`, and env-gated `sam deploy` (guards against a missing/invalid
  `env=`, refuses anything but `stage`/`production`), plus `sam local invoke`
  targets for running handlers in a near-real Lambda runtime locally.
- **Docs:** rewrote a large chunk of README covering the dev environment, the
  build/package/deploy flow, and local functional testing.

### 2. Re-platformed Lambda → containerized EC2 cron (`ddc4b6cd`, +650/-... across 19 files)

Commit message: "update to a cron job to be run on ec2." The diff is a full
migration:

- Deleted the SAM/CloudFormation deploy path (`template.yml` -136,
  `Makefile` -61, handler classes, `scripts/func-envs.json`) and replaced it with
  a `Dockerfile` (python:3.9) plus a `NightlyJob` class entrypoint
  (`default_intervention_nightly_job.py`, +78) invoked as `CMD python3 ...
  --env $env`.
- Reason is legible in the code he'd written days earlier: a comment reads
  "Uncomment this line if lambda storage is too high" — the job dumps an entire
  DynamoDB word table to disk, which does not fit Lambda's `/tmp` or its runtime
  ceiling. He recognized the platform mismatch and moved it rather than fighting it.
- **Replaced scattered `os.getenv` reads with a central `ENV_VARS` config map**
  (`environment_data.py`) keyed by `prod` / `stage`, holding table names, S3
  bucket, file paths, and per-env `test_mode` / `verbose_log` flags. Config is
  now one file to read instead of eight env vars spread across four modules.
- Converted the pipeline's `print()` calls to structured logger calls throughout.

### 3. Production hardening and operability tail (~19 small commits)

- Swapped `print` → `logger` in `word_cluster_assignment.py`, and added logging
  specifically "to help notify if file names are wrong" — i.e. turned a silent
  wrong-file failure into a diagnosable one.
- Removed a `breakpoint()` twice (caught before/around prod runs).
- Shipped a revert (`4370e29b` "Revert to 26") when a date bump misfired —
  evidence of iterating live against a production data pipeline.
- **Final structural cleanup (`acd8e066`/`b930c4dc`):** eliminated the
  `ENG_LATEST_DATE` / `SPA_LATEST_DATE` config variables entirely by moving S3
  artifacts to stable, undated filenames (`word_default_intervention.csv` instead
  of `word_default_intervention_26Sep2023_deploy.csv`). This deleted a whole class
  of recurring toil: before, every content drop required a code change + deploy to
  bump the date strings; after, the job just picks up the current file. That churn
  is literally what most of his preceding commits were.
- Also wrote `csv_to_json.py`, a small utility to convert cluster-assignment CSVs
  (plus overrides) to JSON for testing.

## Domain

Word-level reading-intervention selection: clustering words by psycholinguistic
features (euclidean/mahalanobis distance over feature vectors), assigning
default intervention types per word, applying manual override files, and
publishing the result to a DynamoDB table the live product reads. Bilingual —
English (`en-US`) and Spanish (`es-MX`) run through the same pipeline with
locale-specific feature sets. Handed off from data science: the code he
industrialized still carries data-science-era artifacts (a function named
`mock_usage` doing the real work) that he wired into a production job.

## Quantifiable signals

- 21 commits, 9 PRs, 9/9 merged, ~5-week focused engagement (Sep–Oct 2023).
- Two substantial architecture commits: +917 lines / 21 files (build), and a
  19-file platform migration.
- Bulk write path: 15-item DynamoDB transactions, 5-retry exponential backoff.
- Full-table scan/export of the platform's word psychometrics store
  (`PsycholinguisticsStore`), locale-split, run nightly.
- Two languages, two environments (stage/production), two deployment platforms
  built (Lambda/SAM, then Docker/EC2).

## Resume-usable framing

- Took a data scientist's local-only clustering script and productionized it into
  a nightly bilingual batch job serving a K-5 reading platform's intervention
  selection — including throttle-aware bulk DynamoDB writes and a stage/prod
  deploy path.
- Diagnosed a platform mismatch (Lambda storage/runtime limits vs. a full-table
  DynamoDB export) and re-platformed the job to a containerized EC2 cron, keeping
  the business logic intact while swapping the entire deploy surface.
- Removed recurring release toil by moving versioned-by-date S3 artifacts to
  stable filenames, eliminating a code-change-and-deploy step from every content drop.

## Notes for synthesis

- Tech surfaced here: Python, boto3, AWS Lambda, AWS SAM/CloudFormation, DynamoDB
  (transactions, pagination, type deserialization), S3, EC2 cron, Docker,
  Make, pandas, scipy, GitHub PR workflow.
- The repo's Rust/R components predate him and are not his work — don't credit them.
- Contribution is narrow but complete: one service, end to end, greenfield to prod,
  including the decision to change platforms mid-flight. Good "ownership of a
  vertical" example; not a good "long-tenure repo" example.
