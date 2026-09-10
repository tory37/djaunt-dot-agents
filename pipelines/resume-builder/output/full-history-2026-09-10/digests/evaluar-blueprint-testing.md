# evaluar-blueprint-testing (AmiraLearning)

Private repo. "Helper webapp for testing evaluar blueprints for BTS 2026."
Created 2026-07-08, last push 2026-07-08 — a single-day, single-author build.

## Role / contribution

Sole author and originator. All 7 commits on `main` are tory37; there are no other
contributors, no PRs (direct-to-main solo repo), and no forks/stars (internal tool).
Tory designed, built, and shipped the whole tool — backend, HTML/CSS/JS front end,
spreadsheet integration, and the operator-facing README — in one sitting.

## What the tool actually does

An internal QA workflow tool for the Evaluar blueprint manual test pass (Back-to-School
2026). A shared Google Sheet held hundreds of manual test scenarios across grade/blueprint
tabs; testers were picking rows by hand and transcribing results back into the sheet.
This tool removes both of those steps:

- Parses the workbook's tab structure into structured scenarios (grade, student
  credentials, blueprint link, HMH vs Istation login flow, target "perform well/poorly").
- Serves a local web app on `localhost:8787` with a picker page (random pick with
  tab/grade filters, or browse all cases in a searchable table) and a per-scenario test
  page that inlines the exact login/assign/take steps and credentials for that case.
- Autosaves notes and result fields directly into the correct row of the live Google
  Sheet as the tester types — no manual transcription.
- Supports a claim model so multiple testers on separate machines don't duplicate work.

## Notable technical work and design decisions

**Zero-credential Google Sheets integration.** The interesting constraint: get read/write
access to a live shared sheet without asking every tester to set up a Google Cloud
project, service account, or OAuth credentials. Solution was a bundled Apps Script Web App
(`evaluar_appscript.gs`) deployed once from inside the sheet itself, executing as the
owner, guarded by a shared token. The Python client (`evaluar_sheets.py`) talks to it over
plain HTTP with only the standard library — no Google client libraries in the dependency
tree at all. Tester onboarding collapsed to: clone, `pip install`, paste a URL + token
into a config file. Write-back is scoped to the specific cells of the specific row under
test, never a bulk sheet rewrite.

**Two-tier storage with graceful offline degradation.** If no config is present the tool
falls back to reading a downloaded `.xlsx` via openpyxl and persisting results to local
JSON, so the tool still works with no network/sheet access; the UI labels which mode it's
in ("LIVE — synced with the Google Sheet" vs "LOCAL — reading the downloaded xlsx").

**Concurrency / claim semantics, revised after first pass.** The initial design claimed a
scenario as a side effect of picking it, which meant simply browsing burned rows. Commit
`038e006b` decoupled the two: picking writes nothing, and a dedicated Claim button is the
only path that writes a tester name — with a server-side check that refuses to overwrite
someone else's existing claim. Remembered tester name moved to `localStorage`.

**Orphaned-row detection.** Real sheet data had rows with results filled in but no tester
name (work done before the tool existed, or someone who never signed the row). Commit
`4024472f` added a warning banner on the test page; `aea8028b` pushed the same signal
upstream into the picker — orphan tag on case cards, highlighted rows in the all-cases
table, and an "⚠️ need a check" count in the header stats — so a tester sees it before
clicking in rather than after. That same commit fixed a variable-shadowing bug where the
new `has_orphan_data()` helper collided with the local variable it replaced, which would
have made the warning fire unconditionally.

**Form hydration from source of truth.** `49a54dea` fixed the results form rendering blank
for rows that already had sheet data: scenarios now carry `existing_values` read from the
live cells, used as the baseline, with the local JSON backup layered on top when present.

**Perceived-latency handling.** Live-sheet reads on pick/claim/navigate cost a couple of
seconds. `a701b776` added a full-screen blocking overlay with spinner that shows on click
and prevents double-submits on both the test page and the picker.

**UI built without a framework.** Both pages are server-rendered from Python string
templates with hand-written dark-theme CSS and vanilla JS (debounced autosave, fetch-based
claim/pick endpoints, client-side search/filter over a JSON payload of scenario
summaries). No build step, no npm, no framework — appropriate for a tool that has to run
from a bare `python3` on a tester's laptop.

**Dependency discipline.** `requirements.txt` pins to releases deliberately older than 7
days per stated org dependency policy, and documents *why* each of the two dependencies
exists (certifi is there only to supply a CA bundle for macOS python.org installs whose
OpenSSL can't see the system CA store).

## Quantifiable signals

- 7 commits, 100% of repo authorship, 0 other contributors.
- ~1,900 lines added across the run; `evaluar_pick.py` alone is ~1,470 lines (parsing +
  both rendered pages), `evaluar_server.py` ~280, `evaluar_sheets.py` ~200,
  `evaluar_appscript.gs` ~110.
- Languages: Python 77.5 KB (96%), JavaScript 3.5 KB.
- Repo lifespan: single day (2026-07-08). Stars/forks: 0 (private internal tool).
- No PRs — solo direct-to-main workflow.

## Stack

Python 3.9+ (stdlib `http.server`, `urllib`, `ssl`), openpyxl, certifi, Google Apps Script,
Google Sheets, vanilla JS + hand-written CSS, JSON local persistence.

## Caveat for synthesis

Commits carry `Co-Authored-By: Claude Sonnet 5` trailers — this was AI-assisted
development. The design decisions, the constraint framing (no-credentials onboarding), and
the iterative corrections are Tory's; treat it as tool-assisted authorship, not as
independent evidence of hand-written volume. Scale is small — this is a one-day internal
utility, best used as supporting evidence for tooling/QA-enablement or
pragmatic-integration bullets, not as a headline project.
