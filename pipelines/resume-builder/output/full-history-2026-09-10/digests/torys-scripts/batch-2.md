# torys-scripts — batch 2 of 2 (oldest)

Date range: 2023-09-20 → 2024-01-19 (43 commits by tory37, commits API page 2)
Repo metadata/languages/PR counts live in `repo-context.md` — not repeated here.

## What this batch is

The repo's founding period. Two distinct bodies of work, both internal tooling built to
answer production questions that no existing dashboard could answer:

1. **Network Monitoring Service (NMS) forensics** — Sep 2023 to Dec 2023
2. **Homonym metadata pipeline for reading stories** — Dec 2023 to Jan 2024

Language is Node.js (CommonJS) throughout, plus one Python teardown script and an Athena
SQL runbook. Not product code — operator tooling against live AWS production data.

## 1. Network monitoring forensics (Sep–Dec 2023)

Built a log-forensics toolchain over the `amira-logging` S3 bucket to diagnose why student
tutoring sessions were failing mid-activity when network quality degraded.

Technical work found in the diffs:

- **S3 log ingestion at scale.** `listAllContents` paginates `ListObjectsV2Command` via
  `NextContinuationToken` until exhausted, then streams each object body and JSON-parses it.
  Log keys are classified by substring into four NMS event families:
  `network_monitoring_service_initialized`, `network_status_changed`,
  `network_monitoring_service_cleanup`, `network_monitoring_service_audio_queue_dump`.
  (`node/activities/networkMonitor/analyzeStudentNetworkEvents.js`, later
  `node/utils/s3Getters.js`)
- **Event-timeline reconstruction.** Sorts events by timestamp, converts epoch ms to
  human-readable H:M:S.ms, and computes `timeSince` deltas between consecutive events —
  built specifically to check whether Slow/Disconnected/Critical events were firing too
  close together relative to the client's hardcoded thresholds. Counters per activity for
  Normal/Slow/Disconnected/Critical. (`analyzeEventCounts.js`, `analyzeTimestamps.js`)
- **Failure-mode hunting scripts**, each targeting one hypothesis:
  - `findFatalNetworkActivities.js` — did the activity end on a Disconnected/Critical event?
  - `findActivitiesThatFailWithBadNetworkAtStart.js` — bad network in the first second.
  - `findActivitiesWithComprehensionThatDontFinish.js` — activities where a
    `selectIntervention`/`comprehension` log lands within 1000 ms of the first log and no
    NMS cleanup event ever follows, i.e. the student never got past the opening phrase.
  - `analyzeSurroundingNetworkEvents.js`, `getBadNetworkActivities.js` — context windows
    around a bad event.
- **Concurrency and memory management.** Used `@supercharge/promise-pool`; the first
  version loaded every activity in memory then wrote once (explicitly flagged in a code
  comment as a hazard). Later commits raised pool concurrency 20 → 100 and switched to a
  disk-first pattern: `getActivityLogs` checks `output/activities/<id>.json` on disk before
  hitting S3, so reruns are cached and memory stays bounded. One commit is specifically
  "Subvert memory overload in PromisePool.for".
- **Data-source plumbing.** GraphQL queries against the Student Record Store API to pull
  activities by district and date range (`fetchActivitiesWithStatus.js`,
  `fetchActivitesForLast7Days.js` — a rolling 7-day sweep that chains fetch → analyze).
  Cognito `ListUsersCommand` with a `custom:districtId` filter and recursive
  `PaginationToken` walking to export a district's users to CSV (`getUsersForDistrict.js`).
  An Athena runbook (`athena/studentsForDistrict`) documenting the `amira_datalake`
  `activities_v` query used to source student IDs, including the
  `status = 'scored' OR displaystatus = 'rescored'` convention.
- **Correlating a feature flag with failures.** Added detection of a
  `struggle_monitor_disabled` log key so each analyzed activity reports whether the struggle
  monitor was on — tying a config state to the network-failure signal.
- **Refactoring over the batch.** Flat one-off scripts → `utils/`, `aws/`, `fetch/`,
  `parse/`, `serialize/` modules with shared `s3Getters`, `setupDir`, `csvUtils`,
  `jsonUtils`, and a central `constants.js`. Every script uses the
  `if (require.main === module)` dual-mode idiom so it works both as a CLI and as an
  importable step in a chained pipeline.

## 2. Homonym metadata pipeline (Dec 2023 – Jan 2024)

A four-stage pipeline to find every homonym in Amira's story corpus and attach the *correct*
sense-specific metadata (definition, phonetics, rhyme, fun fact, illustration) per occurrence
— so a reading tutor shows the right meaning of "bear" for the sentence the student is on.

- **Corpus scan.** `ScanCommand` over the `amira-story-db` DynamoDB table with
  `ExclusiveStartKey` paging, walking every story → chapter → phrase → word, matching against
  a curated homonym word list, and emitting each hit with `storyId`, `chapterIndex`,
  `phraseIndex`, `wordIndex`, plus the phrase with the target word bracketed
  (`[BEAR]`) for later prompt context. CSV escaping handled for embedded quotes.
- **Metadata generation, three sourcing strategies tried in sequence:**
  1. `dictionaryapi.dev` per word — one row per dictionary "meaning", the rest of the
     columns marked `(inherited)` so a human only fills in what differs from the default.
  2. The internal `PsycholinguisticsStore` word DB (`WORD`, `PHON`, `DEFINITION`) as the
     baseline row (`homonymId: 0`).
  3. GPT-4 (`gpt-4-1106-preview`) batched 10 words at a time, prompted as a
     science-of-reading expert, to enumerate *all* senses of each word and produce a
     third-grade-readable definition, a ≤20-word fun fact, IPA, a rhyming word, and — for
     names — meaning/nationality/ISO country code. Output constrained to raw CSV.
- **Defensive LLM output parsing.** `parseGPTResponse` regex-matches quoted/empty CSV fields
  and drops any line whose field count isn't 8, logging the reject rather than corrupting the
  output file — treating the model as an unreliable data source.
- **Sense disambiguation via LLM.** `determineCorrectHomonyms.js` sends the whole story text
  with homonyms bracketed, plus the numbered candidate definitions, and asks GPT to return
  `WORD: id` lines in story order. Prompt includes a worked few-shot example (the "CAN"
  story) to lock the output shape. Response parsed back into `{ WORD, homonymId }` pairs.
- **DALL·E-3 illustration generation.** Two-hop: GPT writes an image prompt (photorealistic,
  kid-friendly, seven-year-old audience) from the word + definition, then that prompt goes to
  `images.generate`. Generated images downloaded and zipped via `axios` + `JSZip`.
- **Human-in-the-loop review.** `step3SelectStoryHomonymOverrides.js` uses `inquirer` to walk
  every found occurrence, show the candidate definitions, and let a reviewer pick one or
  author a new metadata row field-by-field (defaulting each field to the existing value).
- **Diff-only deployment.** `step4DeployHomonymOverrides.js` writes back to DynamoDB as
  *overrides only*: any field equal to the default row or still marked `(inherited)` is
  deleted before write, and rows with `homonymId === 0` are skipped entirely. Result is a
  nested `stories[storyId].chapters[i].overrides[]` structure keyed by
  `phraseIndex`/`wordIndex` — minimal, targeted writes rather than full-record overwrites.
- **Pipeline framing.** A `README.md` documents the four numbered steps and what a human must
  do between them; scripts renamed to `step1…step4` prefixes to make the order explicit.
  Config centralized so the whole pipeline can be pointed at a different data run
  (`data/run1/…`) or at stage vs prod DynamoDB tables.

## Other

- `python/interventionSelection/tear_down_db.py` — small Python teardown for the intervention
  selection database (the batch's opening commit).
- `curl/getMagicStudentById.sh` — one-line auth/lookup helper.

## Signals for the resume

- 43 commits in this batch; repo spans 2023-09 to 2026-08.
- Tech actually exercised here: Node.js, AWS SDK v2 and v3 (S3, DynamoDB + `lib-dynamodb`
  DocumentClient, Cognito Identity Provider), AWS Athena, GraphQL, OpenAI API (GPT-4 chat +
  DALL·E-3), `@supercharge/promise-pool`, `inquirer`, `csv-parser`/`json2csv`, `JSZip`,
  Python, shell.
- Two genuinely resume-worthy themes, both stronger than the repo's "personal scripts"
  description implies:
  1. **Production incident forensics at scale** — built the tooling to prove *whether*
     network degradation was killing student sessions, working from raw S3 event logs across
     thousands of activities, with caching/concurrency work to make repeated large sweeps
     feasible.
  2. **LLM-assisted content pipeline with a human review gate** — used GPT-4 and DALL·E-3 to
     generate per-sense word metadata and illustrations for a children's reading product,
     with schema-validated parsing, an interactive reviewer step, and diff-only writes to the
     production story database. This is early-2024 work, before LLM pipelines were routine.
- Caveats for the merge step: this is exploratory operator tooling, not shipped product code.
  Commit messages are terse ("stuff", "more", "Work") — the substance above comes from diffs.
  Several scripts are left mid-experiment (commented-out `main`/`main2`/`main3` entry points,
  hardcoded loop bounds), so claim "built internal tooling / pipelines," not "shipped a
  service."
