# amira-rnd/torys-script-library

**Login matched:** `tory37` (Tory Hebert <tory37@gmail.com>) — `author.login` resolved cleanly on both commits.

## Scale signals

- Commits by user: **2** (sole author; repo is 100% his work)
- PRs: 0 (direct-to-main personal tooling repo)
- Lifespan: created 2026-06-03, last push 2026-06-24 (~3 weeks active)
- Private repo, 0 stars / 0 forks — internal tooling, not a public library
- Languages: HTML 62.3 KB (generated bookmark artifacts), Python 31.5 KB, Shell 8.5 KB
- Initial commit: **+3,005 lines across 15 files** — the whole library landed at once, so it is a
  consolidation of tooling built during earlier day-to-day work, not greenfield in-repo development.

## Role / contribution

Sole author and owner. This is a personal QA/developer-productivity toolkit extracted and published
for reuse, supporting Amira's Spanish (Evaluar) assessment work — specifically the Lexa student app
and the `assessments-data` item bank.

## Technical work and problems solved

**1. Cross-repo mock-data generation pipeline (`generate-mock-data.sh`, 124 lines, Bash)**

Automates a manual, error-prone workflow: the test-data generator scripts live on one branch of
`assessments-data`, while the per-task-type JSONL fixtures live on three *different* feature branches.
The script copies the generators to a `mktemp -d` staging dir first, then checks out each
`ASSMNT-1185-*` branch in turn, runs the matching generator (`graphemePhonemeConversion.py`,
`blending.py`, `vocabulario.py`), and writes the output straight into the frontend repo's
`src/services/aosMocks/*_example_testlet_suites` directories.

Notable design decisions:
- Saves the caller's current branch up front and restores it via a `trap cleanup EXIT` handler, so an
  interrupted run never strands the repo on a foreign feature branch.
- Stages the generators outside the repo precisely *because* they do not exist on the branches being
  checked out — a real constraint the naive version of this script would hit immediately.
- `set -e` plus explicit pre-flight existence checks on both repo paths.

**2. Launch-URL formatter for local mock testing (`url_manipulation/*.py`, ~780 lines Python)**

A family of scripts (`format_all_mock_urls.py` plus five per-task-type variants: blending,
grapheme-phoneme conversion, sentence builder, spelling, vocabulario) that take a real Lexa launch URL
— the long, signed, query-param-heavy URL produced by the live assignment flow — and rewrite it to
point at `http://localhost:8080/` with `mockAOS=true`, `readyModuleTestMode=SKIP`, and the right
`mockSuite` selector, while preserving all 16 required auth/identity params
(`userId`, `token`, `access_token`, `assignmentId`, `districtId`, `schoolId`, `inboxReturnUrl`, etc.).

Notable design decisions:
- Validates up front against a `REQUIRED` param list and prints exactly which params are missing
  rather than emitting a silently broken URL — the failure mode that costs the most debugging time
  when the URL only breaks after app load.
- Percent-encodes every value with `quote(v, safe='')` instead of naive string concatenation, so
  tokens and return URLs survive the round trip.
- Emits **Netscape-format bookmarks HTML** so the whole matrix of test URLs imports directly into
  Chrome/Edge/Firefox/Safari as a nested folder tree (by task type → grade → media type). This turns
  "reconstruct the URL by hand each time" into "click a bookmark," and is the reason the repo is
  62 KB of HTML.
- Companion shell wrappers (`export_all_assessment_urls.sh`, `generate_all_bookmarks.sh`) degrade
  gracefully: each mock-suite directory is probed with `-d` and skipped with a warning rather than
  aborting the whole export.
- Documented for other engineers in a 208-line `COMBINED_BOOKMARKS_README.md` with per-browser
  import instructions.

**3. Assessment-content QA analyzer (`vocabulario-testing/find_mixed_pattern_testlets.py`, 261 lines)**

The substantive analytical piece. Spanish vocabulary items come in four presentation patterns, which
the script infers structurally from each item's JSONL shape rather than from any declared field:

| Pattern | Detection rule |
|---|---|
| P1 — picture word/concept | image-bearing options, no `instructions.text` |
| P2 — picture with instruction | image-bearing options, `instructions.text` present |
| P3 — word-definition | text options, no `imageURL` |
| P4 — word-synonym with picture | text options, `imageURL` present |

The bug it exposes: testlet-level spoken instructions are chosen from **item 0's** pattern, so any
testlet whose later items use a different pattern gives the student verbal instructions that do not
match the UI they see — images appear or vanish unannounced, which can invalidate the assessment
result.

Findings, from the generated report checked into the repo:
- **87 of 194 vocabulario testlets (44%) contained mixed patterns**
- 36 testlets mixed P1+P2, 51 mixed P3+P4
- Output is a 52 KB markdown report with a per-combination summary table, an explanation of the
  student-facing impact, and a per-testlet drill-down (testlet ID, detected pattern, conflicting
  patterns present).

This is content-QA-by-static-analysis: instead of manually clicking through 194 testlets, he derived
the defect class from the data shape and quantified its blast radius across the whole Spanish item
bank.

**4. Repo hygiene (`5c2aff6`)** — added `.gitignore` and untracked a committed `.DS_Store`.

## Resume-relevant themes

- Developer-productivity and QA tooling built to remove manual, repetitive setup from an assessment
  testing workflow
- Bash automation across multiple repos and git branches with safe cleanup semantics (`trap`,
  branch restore)
- Python CLI tooling: `argparse`, `urllib.parse`, JSONL processing, generated HTML/markdown reports
- Static analysis of assessment content to find a UX/validity defect, quantified at 44% of 194 testlets
- Wrote user-facing documentation for the tools so other engineers could run them
