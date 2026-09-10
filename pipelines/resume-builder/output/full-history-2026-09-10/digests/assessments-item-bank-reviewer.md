# assessments-item-bank-reviewer (amira-rnd)

## Snapshot
- Private repo, created 2026-04-07, last push 2026-04-08 — a ~2-day focused build sprint.
- 10 commits, all authored by Tory Hebert (9 as `tory37`; the initial commit has a null GitHub login, local identity `tory@Mac.attlocal.net`).
- 9 PRs opened and merged, all authored and merged by Tory. Sole contributor — no other committers.
- 0 stars / 0 forks (internal tool).
- Languages: TypeScript 76KB, CSS 28KB, Python 3KB, HTML.

## Role / contribution
Sole author and designer. Built an internal, local-first review tool end to end — data model, parsing layer, React UI, CSS design system, report export, and Python packaging/distribution — in a two-day push, shipping through nine small reviewed PRs rather than one monolithic drop.

## What the app does
Lets Amira/Evaluar content specialists review the assessment item bank (a multi-sheet Excel workbook, `data/*.xlsx`) item by item in a browser: approve / reject / needs-changes, attach field-level change suggestions with reasoning, add per-item comments, and export a CSV report for the content team. Runs entirely locally against files on disk — no backend service, no database, no upload of proprietary item content.

## Specific technical work
- **Excel-to-review pipeline.** `xlsxLoader.ts` parses multi-sheet `.xlsx` via SheetJS in the browser; each sheet becomes a reviewable row set. Added a per-workbook config layer (`src/config/workbookConfig.ts`) that excludes noise sheets and columns from the review surface — for the Evaluar Item Bank that meant hiding 9 metadata/deprecated sheets (`Instruction`, `BPs`, `Testlet Summary`, `Subscores`, and the `*_old` variants) and internal-only columns (`QUESTION_OID`, `PARENT_OID`, `calibration_form`). Reviewers only see fields they can actually judge.
- **Pluggable per-domain rendering.** A service registry (`src/services/registry.ts` + `types/service.ts`) maps a data source to a domain-specific renderer, so new item types drop in without touching the shell. Implemented the first one — `readingComprehension` — which groups flat rows into stories by `storyId`/`referenceStoryId`, orders questions within a story by `phraseIndex`, then builds a grade → story → question hierarchy with numeric-aware grade sorting (`buildHierarchy` in `services/readingComprehension/parser.ts`).
- **Media auto-detection.** `MediaRenderer.tsx` inspects each cell value: parses it as a URL, classifies by extension and path heuristics into image / video / audio, renders the right player inline, and degrades to plain text on parse failure or a broken asset (`onError` hides the element). Item bank cells hold CDN URLs, so reviewers see the actual stimulus, not a link. Later paired option text with its corresponding option image so multiple-choice distractors read as answer choices instead of two disconnected columns.
- **Session persistence.** `services/reviewSession.ts` keeps the whole review session in `localStorage` under one key — reviewer name, workbook path, sheet selections, and every per-item verdict with timestamp — with safe JSON recovery on corrupt state. Progress and stats survive a page refresh, which matters for a multi-hundred-item review pass done over several sittings.
- **CSV report generation.** `reportGenerator.ts` flattens the session into a sorted report (sheet, row, resolved item ID, status, comment, field changes, reviewer, timestamp), resolves the item ID across three possible ID column names, hand-rolls RFC-correct CSV escaping (quote doubling, quoting on comma/quote/newline), truncates long field values, and triggers a Blob download. Also generates a plain-text summary stat block.
- **Distribution as a Python package.** Reviewers are content people, not developers — so instead of "clone the repo and run npm", added a FastAPI/uvicorn wrapper (`server.py`) that serves the pre-built React bundle, mounts the caller's `./data` directory as a static route, scans a port range for a free port, auto-opens the browser, and falls back to `index.html` for SPA routing. Shipped it as a `uvx --from git+ssh://...` one-liner. Debugged and fixed the packaging: setuptools `package-data` only picks up files inside a Python package, so the built `dist/` was silently missing from wheel installs — restructured into an `assessments_item_bank_reviewer/` package, moved `server.py` and `dist/` inside it, and retargeted the Vite build output accordingly.
- **UI robustness pass.** Replaced absolutely-positioned popovers with `createPortal`-based rendering to `document.body` (`components/Portal.tsx`) after finding that floating UI clipped on short pages; converted the field-change popover into a centered modal and deliberately removed click-outside-to-close on it to prevent reviewers losing typed feedback by accident.
- **Reviewer-behavior-driven tweaks.** Un-collapsed the overall comment box permanently after noticing the toggle made reviewers miss it. Built and then removed an "Email Report" feature once it was clear `mailto:` cannot attach the generated CSV — shipped, evaluated, reverted rather than leaving a half-working path.
- **AI-agent onboarding doc.** Added a 163-line `AGENTS.md` — tech-stack table, architecture sketch, route map, file index, core TypeScript interfaces, and common-modification recipes — explicitly to cut context-gathering cost for AI sessions on the codebase.

## Notable design decisions
- Local-first, zero-backend by design: proprietary assessment item content never leaves the reviewer's machine.
- Ship-as-a-CLI (`uvx`) for a non-technical audience, trading a slightly odd Python-wraps-React packaging for a genuine one-command install.
- Config-driven field/sheet exclusion instead of hardcoded filters, so a new workbook is a config entry rather than a code change.
- Registry-based domain renderers to keep the review shell generic across item types.
- Nine small, individually-described, individually-merged PRs across two days — each with an Overview / Changes / Validation body.

## Quantifiable signals
- 10 commits, 9 merged PRs, 100% authored by the user; sole contributor.
- ~104KB of source across TypeScript, CSS, and Python.
- ~3,900 lines added in the initial commit alone (32 files: full React app, 1,373-line CSS design system, services layer, type definitions, build config).
- Repo lifespan: 2 days of active development (2026-04-07 → 2026-04-08).
- Excluded 9 obsolete/metadata sheets and 4 internal columns from the reviewer's surface via config.
