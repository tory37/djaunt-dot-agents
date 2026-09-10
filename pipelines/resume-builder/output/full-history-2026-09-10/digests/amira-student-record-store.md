# amira-student-record-store (AmiraLearning)

Private AWS AppSync + Lambda GraphQL service — the "Student Record Store" (SRS),
the system of record for K-5 reading activities, scores, story metadata, word
psycholinguistics, and per-district license/entitlement configuration at Amira
Learning. Serverless Node.js on AWS SAM/CloudFormation, backed by MySQL (RDS,
via Knex) and DynamoDB, fronted by AppSync with VTL resolvers, packaged as
container-image Lambdas and cached with Redis.

## Scale signals

- **Repo lifespan:** created 2018-09; still active (last push 2026-09-10).
- **Tory's span:** 2023-09-05 → 2026-09-02 (3 years of contribution).
- **Commits authored:** 44 total on `develop` (~32 non-merge + 12 merge commits).
- **PRs:** 25 opened, 22 merged, 3 closed unmerged.
- **Languages:** JavaScript (~656 KB) dominant, plus Python, Makefile, Dockerfile.
- Stars/forks negligible (1/0) — internal private service, not OSS.
- Roughly half the PRs carry Jira keys (`ASSMNT-*`, `SC-*`, `CR-10490`),
  showing sprint-tracked delivery rather than ad-hoc commits.

## Role and contribution pattern

Cross-cutting **API contract owner** on a shared platform service rather than a
full-time maintainer. Almost every change lands in the AppSync GraphQL schema
(`res/srs-schema.graphql`, earlier `res/student_record_store_schema.graphql`)
and the SAM template (`template.yaml` / `cfn/template.yaml`) that wires the
schema to data sources and resolvers.

The pattern: a feature owned elsewhere (educator client, student app, tutor,
assessment engine) needs a new field, entitlement, or query; Tory extends the
SRS contract — type, input types, filter inputs, resolver, data source, and
where needed a new Lambda — so the consuming team can read/write it. This is
the integration seam between ~a dozen Amira services, so the work is
schema-design and backward-compatibility work, not isolated feature code.

Three recurring workstreams:

1. **License / entitlement schema (`AmiraLicenses`)** — the largest slice.
2. **Assessment and content data model** (story metadata, interactions,
   calibration items, drag-and-drop item types).
3. **Word-metadata resolvers** for the intervention-selection pipeline.

## Notable technical work (verified from diffs, not commit messages)

### `backdateActivity` mutation — new Lambda, end-to-end (PR #629, ASSMNT-1152, 2026-05)

The most substantial single change. Built a complete new AppSync mutation from
schema to infrastructure in one PR:

- New handler `src/srs/backdate-activity.js` (61 lines) using Knex against RDS
  MySQL — bulk-updates `createdAt` for a list of activity IDs and returns an
  `ActivityUpdateSummary` per row.
- **Security-conscious input handling:** IDs are stored as MySQL binary and
  matched via `unhex()`; the handler strips every non-hex character
  (`replace(/[^A-F0-9]/gi, '')`) before binding, and binds through
  `client.raw('unhex(?)', [id])` rather than string interpolation.
- Custom `ValidationError` class mapped to an AppSync `AppSyncError` typename,
  with a VTL response template that calls `$util.error(...)` so callers get a
  typed GraphQL error instead of a 500.
- `context.callbackWaitsForEmptyEventLoop = false` to keep the DB pool warm
  across invocations.
- Full infra wiring in the same change: new Dockerfile build target
  (`srsbackdateactivity`), a `AWS::Serverless::Function` on **arm64** with
  VPC config and env-injected DB credentials, an `AWS::AppSync::DataSource`,
  and the mutation resolver.
- Added 71 lines of Mocha unit tests exercising the new handler.

### Batch word-metadata query + intervention-selection field resolver (PR #218, 2023-09)

Solved an N+1 problem in the intervention pipeline. The existing schema only
exposed `word(WORD: String!)` — one word per request.

- Added `words(WORDS: [String!]!): [PsycholinguisticsStore]` backed by a
  DynamoDB **BatchGetItem** VTL resolver, collapsing per-word round trips into
  one call.
- Shipped a follow-up fix in the same PR after finding the first version
  broken on real input: DynamoDB `BatchGetItem` rejects duplicate keys, so the
  VTL template was rewritten to dedupe (`$processed.contains($word)`) before
  building the key list. Good evidence of debugging a real failure mode in a
  templating language with no test harness.
- Added `InterventionSelectionMetadata` as a **nested field resolver** on
  `PsycholinguisticsStore`, backed by a separate Lambda data source
  (`InterventionSelectionStoreAcessor`) — lazily resolved per-word, so callers
  that don't request intervention metadata pay nothing for it.

### License / entitlement modeling (~12 PRs, 2025-2026)

Owned the growth of the `AmiraLicenses` type — the district/school entitlement
model that gates product behavior platform-wide. Each addition had to land in
three places consistently (`AmiraLicenses`, `CreateAmiraLicensesInput`,
`UpdateAmiraLicensesInput`, and sometimes `TableStringFilterInput`); a missed
one breaks writes silently, and Tory shipped a dedicated fix (PR #459) for
exactly that class of omission.

Fields added include: `alwaysAllowTutor`, `amiraIsipVisibility`,
`ignoreBrowserCompatibilityCheck`, `excludeMircolessonsByDefault`,
`assessmentTimerMultiplier`, `allowCurriculumOnboard`, `availableCurriculums`,
`blockOnDemandAssessments`, `useAdaptiveSoda`, `useGradeLevelSoda`,
`evaluarPilotEnabled` (Spanish/Evaluar pilot gating), `adventuresConfig`, and
the `AmiraTutorSettings` sub-type (`tutorSelectionEnabled`, `prohibitedRigs`,
`prohibitedSkins`) with its matching input type.

Also extended the **RBAC** model: `assessmentControlCanEditBilingualConfiguration:
BehaviorRBAC` (PR #687, CR-10490), part of an `assessmentControl*` permission
family gating what educators may change on an assessment. That same PR deleted
a stale 4,236-line duplicate CFN template (`cfn/template-in-place.yaml`) — the
line count is cleanup, not new work.

### Assessment / content data model

- **Assessment calibration** (PR #262, 2024-12): added `letterDisplay`,
  `wordPartToDelete`, `startingWord`, `playComponentIntroductions`, and a
  `TypedOptions` type (`key`, `imageUrl`) — the schema shape for
  calibration/phonics item rendering.
- **Reference stories** (PR #259, 2024-11): `referenceStoryId`,
  `referenceStoryPhrases`, `canViewReferenceStory` on `AmiraStoryDb` — a
  story-on-story relationship for comparison reading.
- **Comprehension v2 interactions** (PR #233, 2024-03): new `interaction` type
  (`ids`, `imageURL`, `prompt`, `response`, `noResponsePrompt`) attached to
  stories — the data contract for conversational comprehension prompts.
- **Word metadata overrides** (PR #224, 2024-01): `WordMetadataOverride`
  (`phraseIndex`, `wordIndex`, `metadata: PsycholinguisticsStore`) so content
  authors can override psycholinguistic word data at a specific position in a
  story instead of globally.
- **Drag-and-drop item types** (PRs #701, #713, ASSMNT-2417, 2026-09): modeled
  a formative item board as `dropZones: [AosDropZone]` with a
  `backgroundImageUrl`, replacing an earlier "option role" modeling; added a
  `multiSelect` item mode. A deliberate schema-shape decision — dropping a
  previously shipped abstraction in favor of a clearer one.

## Design decisions worth calling out

- **Contract-first, backward-compatible.** Every schema change is purely
  additive (optional fields, new types). No breaking changes in 3 years of
  commits across a service with many downstream consumers.
- **Nested field resolvers over fat payloads** — intervention metadata resolves
  lazily per word rather than being inlined into the parent type.
- **Batch over loop** — replaced per-word DynamoDB reads with BatchGetItem.
- **Typed GraphQL errors** — validation failures surface as `AppSyncError` via
  VTL `$util.error`, not as opaque Lambda exceptions.
- **Infra as part of the feature** — new capabilities ship with their SAM
  resources, Docker build target, data source, and resolver in the same PR,
  not as a follow-on infra ticket.

## Technologies evidenced

AWS AppSync, GraphQL (SDL, schema design, field resolvers, input/filter types),
VTL (Apache Velocity resolver mapping templates), AWS Lambda (container image,
arm64), AWS SAM / CloudFormation, DynamoDB (BatchGetItem), Amazon RDS MySQL,
Knex.js, Node.js, Babel, Mocha/Sinon, Docker & docker-compose, Redis, Jira-driven
workflow, RBAC/entitlement modeling.
