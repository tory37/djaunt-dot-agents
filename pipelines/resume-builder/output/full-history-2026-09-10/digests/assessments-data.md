# assessments-data (amira-rnd)

Private repo. "Repo to hold items, testlets, blueprints, etc data" — the content-build
pipeline for Amira's K-5 literacy assessment platform. Python-only (~954 KB), created
2025-03-07, active through 2026-09-10. 0 stars / 0 forks (internal work repo — scale
signal is content volume, not GitHub metrics).

## Role and contribution

Content-pipeline engineer on the assessment item build system. Owned the Python builders
that turn author-facing Excel item banks (`data/*Item Bank.xlsx`, maintained by a content
team) into the JSONL item/testlet/blueprint artifacts ingested into DynamoDB and served to
the student app. Work spans two tracks:

- **Spanish (Evaluar) assessment content** — new task-type builders and item-shape fixes.
- **Adventures / Formative interaction types** — a new family of interactive item screens
  (multiple choice, bucketing, sequence, free answer) built in lockstep with renderer PRs
  in the `lexa-studentapp` frontend repo.

Consistently paired backend content PRs with a named companion frontend PR, and wrote PR
descriptions that explain the failure mechanism, not just the change.

## Quantifiable signals

- 5 commits authored on `main`, 11 PRs opened, 6 merged (2026-04 to 2026-09).
- Largest single feature PR: +2,306 / -22 (`vocabulario` builder, 957 items / 194 testlets).
- Test suite the work runs against: 328 passing tests; one PR alone added 76 unit tests.
- Item bank scope handled by the builders: 1,375-1,527 authored rows.
- Repo lifespan touched: ~6 months of the repo's 18-month life.

## Specific technical work

**Testlet completion bug — empty-generator `all()` (PR 364, merged).** Every bucketing and
sequence row shipped `operational: false`, so no testlet built from them could be
administered. The orchestration service derives testlet completion from operational items
only, and `all()` over an empty generator returns `True` — so a testlet reported COMPLETED
on item 1 without administering anything. Traced two independent gates in
`interaction_item`: an `awaiting_renderer` tag appended unconditionally (its premise — no
renderer existed — had since become false), and `operational` hardcoded `False` regardless
of tags, so clearing the tag alone changed nothing. Made `operational` derive from gap tags
and asserted the invariant (`item["operational"] == (not awaiting)`) in the test suite.
Result: bucketing 0/20 → 12/20 operational, sequence 0/4 → 1/4, renderer content gaps 51 →
33 rows, with all 1,375 item ids preserved (`0 new, 0 removed`) and the rebuild idempotent.

**Stable item identity across rebuilds (`stable_key`).** Items are matched to existing ids
by a content key so re-sorting the source spreadsheet, closing a content gap, or delivering
artwork never re-mints an id. Deliberately excludes three classes of "production
bookkeeping" from identity — `tracker_` position tags, `awaiting_` gap tags, and asset URLs
— and verified the choice empirically: identity still holds all 1,527 rows apart with every
URL blanked. Extended the exclusion into nested `subItems` when it was found to leak there.

**ShortAns → freeAnswer item type (PR 344, merged).** ShortAns rows were mapped onto
`retell`, which has no `imageURL` field, silently dropping 25 of 46 rows (5 production-
ready). Diagnosed three things the old mapping structurally could not express: a column
that is an art brief for designers on Image/Video rows but spoken content on Text rows
(resolved by the declared type column, so ingest never inspects a cell to infer its
meaning); two "Verbal Instructions" columns straddling the stimulus that must stay separate
(concatenating them asked the question before the video played); and assets taken verbatim
from `Asset Location`, prefixed but never guessed. Left `build_retell` byte-identical for
its existing 34 items.

**Bucketing board contract rewrite (PR 343, merged).** Realigned the draft `buckets`
contract to the shape the shipped renderer actually consumes, renaming the type to
`bucketing` to match the on-wire itemType. Collapsed buckets, printed symbols and row
breaks into one flat reading-order `options[]` list partitioned by `role`; parsed the board
from a single authored cell as a token stream (`[bucket]`, `[image: f.png]`, `[break]`)
because adjacent buckets carry no whitespace to split on; changed `phrase` to an array of
arrays so an empty bucket is an explicit `[]` — the old delimited encoding could not express
one, so response arity never matched bucket count and a key containing the separator
mis-split. Surfaced two latent bugs in passing: column lookups now normalize whitespace
runs (wrapped tracker headings read `After\nQuestion Screen` on one sheet and
`After Question Screen` on another, and a miss silently fell back to a default rather than
raising), and a missing column now reports its row instead of aborting the build.

**Spanish (Evaluar) task-type builders.** Added `vocabulario` end to end (PR 238): new
Spanish task type, sheet-name and testlet-type alias bridging to the differently-named
source spreadsheet tabs, `ISAssets/…` → CDN URL transformation, a 4-way pattern classifier
(picture-word, picture-sentence, word-definition, word+image), plus item and testlet
builders with per-pattern Spanish instructions — 957 items across 194 testlets, 76 tests.
Regenerated Spanish listening-comprehension JSONL with UI tags, localized copy
(Repetir/Siguiente) and repeat-variation handling (PR 232). Retargeted Spanish blending
items to the `mmc` type so they route to the frontend's `ModularMultipleChoice` renderer
rather than the English-shaped `BlendingSelection` component (PR 268). Smaller
grapheme-phoneme-conversion fixes: `verticalOptions`, `readOptionsAloud`, populated
`options.text` — each regenerating 807 JSONL rows via the `build-items.yml` GitHub Actions
workflow.

**Diagnostic work on broken inputs (PR 359, closed).** Investigated why a refreshed
spreadsheet export broke the build and traced it to a finalize pass that wrote its output
over the raw tab name and moved the raw tracker tab to a `… (tracker)` suffix — inverting
the `FINAL_TAB_SUFFIX` convention `find_sheet` relies on. Isolated the two concrete
failures (a flattened wrapped header breaking five hard-coded lookups; a column dropped
from a 46-column finalize view) and concluded the fix belonged in the tracker tooling, not
the builder — declining to merge a workaround.

## Design decisions worth naming

- **Never drop an authored row.** A row missing a required cell is tagged
  `awaiting_<gap>`, counted, and listed in a generated `content-gaps.md` the content team
  works from — because a dropped row is invisible to authors, so it never gets fixed.
- **Declared type over inferred type.** Column meaning is resolved from an explicit type
  column, never by inspecting the cell's contents, so ingest behavior is predictable.
- **Build-time guarantees.** Rebuilds are idempotent and id-stable; PRs report id deltas
  (`0 new, 0 removed`) as evidence.
- **Post-merge ingest is called out explicitly** — DynamoDB holds old flags until re-ingest,
  so merged builder changes are documented as not-yet-live on stage.

## Tech
Python, pytest, openpyxl/Excel ingest, JSONL, DynamoDB, GitHub Actions (auto-generated
build artifacts), AWS CDN asset pipelines, Jira/Atlassian ticket workflow.
