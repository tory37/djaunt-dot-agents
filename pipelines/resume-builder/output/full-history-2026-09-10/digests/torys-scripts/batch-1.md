# torys-scripts — batch 1 digest

- Repo: AmiraLearning/torys-scripts
- Author: tory37
- Date range covered: **2024-01-22 → 2025-09-24** (50 commits, commits-API page 1)
- Stack seen in this batch: Node.js (CommonJS), AWS SDK v2 and v3 (DynamoDB DocumentClient, S3), AWS AppSync/GraphQL, OpenAI chat-completions API, Google Sheets API (`google-spreadsheet` + JWT service account), Express, csv-parser/json2csv, inquirer CLI, Python (small helper)

## What this repo actually is

Framed in its description as a personal script dump, but the diffs show it is a **content-engineering and data-migration toolbox for Amira's assessment/story platform**. Most commits build real multi-stage pipelines that read and write production content stores (DynamoDB `amira-story-db`, AOS `ItemServiceStore`, Student Record Store AppSync). Commit messages are near-useless ("stuff", "idk", "MMMbop") — the diffs carry all the signal.

## Major work in this batch

### 1. LLM-driven homonym metadata pipeline (Jan–Mar 2024, the dominant thread)

A staged pipeline (`node/homonyms/s1…s11`) that generates and deploys pronunciation/definition metadata for homonyms across the whole story corpus, so the reading engine scores the right pronunciation of a word in context.

- **Stage design.** Numbered, resumable steps with per-stage phase files (`phase_1_homonymMetadata.csv` → `phase_2_…`) and per-stage log directories. Each stage reads the prior stage's CSV, so a failed run restarts at the failing stage instead of the top.
- **GPT prompt engineering as code.** `s2GenerateDefinitions.js` builds a structured multi-turn chat prompt (system role establishing an "English language expert", few-shot input/output example pairs, explicit JSON-only output instruction) and batches 10 words per request. Response parsing validates every returned object and assigns per-word `HOMONYM_ID` counters. Sibling stages generate name metadata (`s3`), fun facts (`s4`), and download generated images (`s5/s6`).
- **Story-level disambiguation.** `s7DetermineCorrectHomonyms.js` scans the entire DynamoDB story table, finds each homonym occurrence down to `chapterIndex/phraseIndex/wordIndex`, and asks the model which sense applies in that phrase. Added idempotency: reads the already-processed CSV on startup and skips those story IDs, plus `IDS_TO_REPROCESS`, `FORCED_STORIES`, and `STORIES_TO_IGNORE` escape hatches for reruns.
- **Reliability work on the AWS layer** (`node/aws/stories.js`): rewrote `fetchMultipleStories` to chunk IDs into batches of 90 (DynamoDB `BatchGetItem` limit), fan the chunks out with `Promise.all`, and wrap each chunk in a recursive retry with linear backoff. Also fixed a real bug where `ExclusiveStartKey` was being reconstructed as `{storyid: key}` instead of passed through, which broke scan pagination.
- **Validation stages before deploy.** `validateHomonymMetadataFile.js` / `validateStoryAssignmentFile.js` enforce non-null `HOMONYM_ID`, uniqueness of `HOMONYM_ID` per word, and uniqueness of definition per word, then print an aggregated error summary by row number — a guard against pushing bad metadata overrides to production content.
- **Refactor into one runnable app** (Mar 2024, `92b81c5a`, `06366825`, `432eeddd`): collapsed ~15 loose step scripts into a single `inquirer`-driven CLI (`homonyms.js`) that lists available scripts, shows each script's declared `requirements` (description + instructions) and asks for confirmation before running it. Scripts were reorganized into `MetadataGeneration/`, `StoryProcessing/`, `Validation/`, and `MetadataInspection/` namespaces.
- **Analysis one-offs** built on the same corpus: finding stories where two different senses of one homonym appear in a single phrase, and finding plurals/possessives colliding in a phrase — i.e. hunting the cases most likely to break scoring.

### 2. Comprehension item migration to a standalone store (Apr–May 2024)

`migrateComprehensionItems.js` / `migrateComprehensionFromStoryToStandaloneDB.js`: full paginated DynamoDB scan of the story table, walking `chapters → items → interactions`, and pushing each interactive comprehension item into the Student Record Store via a `setQuestionMetadata` AppSync mutation. Tracks modified vs failed story IDs separately and supports a `processOnlyTheseIDs` allowlist for targeted reruns. Ships a hand-rolled `GraphQLClient` over Node `https` (endpoint + `x-api-key` header) rather than pulling in Amplify.

### 3. 2025 assessment calibration content pipeline (Dec 2024 – Feb 2025)

Builds MOY-2025 ISIP calibration forms from a Google Sheets master sheet into story records, then uploads them.

- `processCalibrationForms.js` reads a service-account-authenticated Google Sheet, groups rows into stories by `formId`+`grade`, generates UUID story IDs, parses embedded-JSON columns (`instructions`, `options`, `localization`), writes each story to disk plus a `manifest.csv`, and bulk-uploads behind a `--upload` flag.
- **Migrated off Amplify to a direct AppSync call** and swapped single-story `createAmiraStoryDb` mutations for a batched `batchAddAmiraStoryDb` mutation at 25 stories per request — with retry and true exponential backoff (`baseDelay * 2^attempt`, 5 attempts). Also removed a hardcoded AppSync API key in favor of `process.env.STORY_APPSYNC_API_KEY`.
- **Generalized into a config-driven "master script"** (`f9ef3954`): deleted the two bespoke per-type processors and replaced them with `updateStoriesFromMasterSheet.js` driven by per-run config modules (`configs/spellingV2UpdateInstructions.js`, `addRetellToDyslexia.js`, …). The config declares item type, sheet IDs/tabs, which item and story fields to update, which fields are JSON-encoded, and the update mode — append new items, override items/phrases wholesale, or patch fields in place. Adds `--debug`, `--limit`, and `--upload` flags and a `purgeNulls` pass before write. Sibling tools: `updateAllInstancesOfType.js`, `updateFirstInstanceOfType.js`, `updateDistractors.js`, `updateStringsWithRegex.js`, `validateItemMetadatas.js`.

### 4. AOS Item Service validation suite (2025, merged via PR `#1`)

A rules-engine validator for the AOS `ItemServiceStore` DynamoDB table.

- Paginated table scan with configurable batch size, optional filter expressions, and a `--limit` for sampling, built on AWS SDK v3 (`@aws-sdk/client-dynamodb` + `lib-dynamodb`).
- **Two-tier validation architecture**: declarative JSON schemas per item type (rule types `requiredFields`, `exactValue`, `fieldEquality`, `pattern` with startsWith/endsWith/contains/regex, `nonEmpty`), with a JavaScript validator escape hatch for rules that can't be expressed declaratively. Error messages support template variables and field interpolation (`{{fieldName|capitalize}}`).
- Emits timestamped HTML and JSON validation reports.
- Ships an **assignment status manager** alongside it: creates a test assignment covering all 13 activity types, or reorders an existing assignment's activity statuses (everything before the target → `DONE`, target and after → `IN_PROGRESS`) so a QA engineer can force a specific activity to play next. Written up with a full README.

### 5. Smaller but real tooling

- **Duplicate comprehension question analyzer** (`analyzeDuplicateQuestions.js`, ~430 lines): normalizes question text/correct answer/sorted distractors, cross-matches end-of-story questions against phrase-level questions, prints a preview report of proposed removals, then removes duplicates back-to-front to avoid index shifting. Has an interactive confirm mode and an `--auto-update` batch mode.
- **S3 activity-log tooling** (`fetch_s3_logs.js`, `cleanup_and_order_logs.js`, `downloadActivityLogs.js`): pulls a session's per-event JSON logs out of S3 and orders them chronologically for debugging a single student activity.
- **Mock delay server** (`mock-servers/delay-server`): tiny Express service exposing `/delay/:seconds` for exercising client timeout/latency handling.
- Story-DB query utilities: find Spanish NWF stories, find comprehension/interactive stories, find stories by content, extract words, CSV→JSON, story-ID formatting, text-to-speech MP3 generation.
- Shared utility layer built up across the batch: `Logger` (file + console, per-script log dirs), `serialization`, `csvUtils`, `googleSheets`, `storyDbApi`, `graphQLClient`, `s3`, `purgeNulls`.

## Notable design decisions

- **Idempotent, resumable batch jobs.** Nearly every long-running script re-reads its own output file on startup to skip completed work, and exposes reprocess/ignore/force lists. This is deliberate — these jobs run against production content tables and take hours.
- **Config-over-code generalization.** Twice in this batch he collapsed a family of near-duplicate scripts into one engine plus declarative config (calibration configs; homonym CLI). Both refactors deleted more bespoke code than they added.
- **Dry-run by default.** Uploads and destructive writes are consistently gated behind an explicit `--upload` / confirm prompt, with file + manifest output written first for inspection.
- **Retry/backoff added reactively at the AWS boundary** — chunking to service limits, exponential backoff on AppSync, linear backoff on DynamoDB batch gets.
- **Credentials moved to env vars** mid-batch (hardcoded AppSync API key removed).

## Quantifiable signals (this batch only)

- 50 commits, 2024-01-22 → 2025-09-24
- 1 PR (`#1`, the AOS validation suite) — this repo is otherwise direct-to-main solo work
- Largest code-only diffs: `4eb72ca6` (~4.2k changed lines, 23 code files), `f9ef3954` (~1.7k), `06366825` (~1.1k), `fbe1ad12` (~1.0k)
- Pipelines operate across at least 4 backing stores: `amira-story-db` (DynamoDB), AOS `ItemServiceStore` (DynamoDB), Student Record Store (AppSync), S3 activity logs

## Noise excluded

`.json`/`.csv`/`.xlsx`/`.log` data dumps and generated HTML validation reports were excluded before ranking by diff size — several commits (`186a57dd`, `47ddf436`, `fbe1ad12`, `36b181f5`) are 4–7k total lines but only 200–1000 lines of actual code. `cleanup_and_order_logs.js` is mostly a pasted console listing, not logic. No merge commits and no reformat-only commits in this batch.
