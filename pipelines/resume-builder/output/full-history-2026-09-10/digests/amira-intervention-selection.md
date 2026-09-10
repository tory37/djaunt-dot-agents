# amira-intervention-selection (AmiraLearning) — digest

## Snapshot
- Private org repo, created 2023-08-15, still active (last push 2026-07-23).
- Stars/forks: 0/0 (internal service — not a scale signal).
- Tory's window: 2023-08-24 → 2023-09-28 (~5 weeks), 6 commits on `develop`, 2 PRs (`#2` merged, `#1` closed/superseded).
- Author linkage note: `author.login` resolves as `tory37`; local commit names are "Tory" / "Tory Hebert".
- Stack: Node.js 18 (CommonJS), AWS Lambda, AWS SAM / CloudFormation, DynamoDB (AWS SDK v3), AWS AppSync (GraphQL), IAM, Makefile + npm build/deploy scripts.

## Role / contribution
Tory was the **originating engineer** on this service. He created the repo's first real implementation — the initial commit (`18a5f73`, "Initial implementation of lambda and needed aws components") and the merged PR `#2` ("Lambda implementation") are both his. Everything after (David Maharry, Pete Jungwirth, rob Arseneault, Derek Nicol) is maintenance, deploy-workflow, and build-infra work layered on top of the Lambda + SAM stack he stood up.

He replaced the repo's scaffold ("hello" Lambda, placeholder `schema.graphql`, throwaway `driver.js`) with the working service.

## What he actually built (from diffs, not commit messages)
Commit messages are terse and unhelpful ("updaates", "clkeanup", "throw error"). The diffs show:

**1. GraphQL resolver Lambda over DynamoDB (`src/iss/getItem.js`, new file, ~60 lines)**
- Backs the `interventionSelection` metadata field on the `PsycolinguisticStore` type in the SRS word/words query (per PR `#2` body) — i.e. an AppSync field resolver fronting a DynamoDB table.
- Wrote a `parseWord` function handling a compound key format: a word may arrive bare (`"tiger"`) or locale-suffixed (`"bananas|en_US"`). It splits on `|`, defaults the locale to `en_US` when absent, and normalizes the word (`trim().toLowerCase()`) before the lookup. This is the core domain logic — it makes a single resolver serve both the legacy bare-word callers and locale-aware callers without a schema change.
- Used AWS SDK v3 `DynamoDBClient` + `GetItemCommand` against a composite key (`PK` = cleaned word, `locale`), then `unmarshall` to convert the DynamoDB attribute-value shape to a plain object.
- Deliberate miss-vs-error distinction: a missing item returns `null` (a legitimate GraphQL null), while a failed DynamoDB call logs word + locale + error message + stack and rethrows. The later `96434767` "throw error" commit is exactly this decision being tightened — a swallowed error would have looked identical to a cache miss to the caller.
- Table name and region injected via env vars, not hardcoded.

**2. Infrastructure as code — rewrote `template.yml` (SAM)**
- Replaced the placeholder `HelloLambda` with `InterventionSelectionStoreAccessorLambda` (nodejs18.x, 512 MB, 300 s timeout), described as "a proxy lambda to access the InterventionSelectionDb from complex queries."
- Added a `Mappings`-driven env matrix so `stage` and `production` resolve their own DynamoDB table names (`amira-intervention-selection-<env>`) from a single `TargetEnv` parameter.
- Tightened IAM: swapped the inherited AWS-managed grab-bag (`AmazonDynamoDBReadOnlyAccess`, `AWSAppSyncInvokeFullAccess`, `AWSLambdaDynamoDBExecutionRole`) for a purpose-written `AppSyncDynamoDBPolicy` managed policy scoped by `!Sub` to the single environment-specific table ARN. Assume-role trust set for `appsync`/`lambda`. This is a real least-privilege narrowing, not a cosmetic refactor.

**3. Build and deploy pipeline (`package.json`)**
- Authored the bundle chain: `clean` → `prep` → `deps` (prod-only install into `./bundle`) → `copy` → `zip`, feeding `sam package` (S3 config bucket) and per-env `sam deploy` scripts.
- Stamped deploys with provenance: `VcsRef=$(git rev-parse HEAD)` and `GitBranch=$(git symbolic-ref --short HEAD)` passed as CloudFormation parameter overrides, so any deployed stack traces back to a commit.
- Final commit `1bff237` fixed a real cross-tool bug: the deploy scripts had been copied out of a Makefile and still carried Make's `$(shell ...)` syntax, which npm/shell does not expand — corrected to plain `$(...)`. Also removed a stray `mkdir bundle` from `clean` that collided with `prep`.

**4. Local invocation harness (`drivers/getItemDriver.js`)**
- Wrote a driver that runs the handler against the real stage table across four cases: plain word, second plain word, `null` word, and locale-suffixed word — covering the parse branches and the null path without a deploy. Pragmatic substitute for a test suite in a repo with `"test": "exit 1"`.

## Notable design decisions
- Locale encoded in the word string rather than a new GraphQL argument — backward-compatible for existing SRS callers.
- Lambda as a thin "store accessor" proxy in front of DynamoDB for queries too complex for a direct AppSync DynamoDB resolver.
- Env-driven config + mapping table over per-environment templates.
- Least-privilege IAM policy scoped to one table ARN, replacing broad AWS-managed policies.

## Quantifiable signals
- 6 commits, 1 merged PR, ~5-week span in Aug–Sep 2023.
- Created the service that is still in use ~3 years later (repo last pushed 2026-07-23).
- 2 deploy environments (stage, production) wired from one parameterized SAM template.
- Sole author of the initial implementation; all subsequent contributors built on it.

## Caveats
- Small footprint — this is a single-Lambda microservice, not a large system. Its resume value is "stood up a production AWS serverless service end-to-end (code + IaC + IAM + deploy pipeline) solo," not volume.
- Repo `languages` API reports only Makefile/JavaScript; the SAM YAML is not counted.
