# amira-admin-reports-domo (AmiraLearning)

Private monorepo, created 2024-11-11, still active (pushed 2026-09-10). Stars 2, forks 0 — internal work repo, so star/fork counts carry no signal.

## What the repo is

Domo-embedded admin reporting suite for Amira Learning's K-5 literacy platform. District and school administrators use it to view assessment growth, reading risk, standards mastery, usage, and assessment completion/classification reports. Three workspaces: `admin-reports` (the React UI shipped as a Domo app), `domo-iframe-viewer` (QA harness that renders the reports iframe on a staging site), `domo-connector-query` and `mock-data-generator` (data-side tooling).

Stack: TypeScript (~870 KB, dominant), React 18, TanStack React Table v8, Recharts, react-select, superagent, Day.js, CRA + react-app-rewired, `@domoinc/ryuu-proxy` for local Domo dev, AWS SAM (`template.yml`), Makefile-driven builds, GitHub Actions. Reports are driven by hand-built SQL strings executed through Domo's dataset query API.

## Tory's role and contribution

Feature contributor on the **Assessment Growth report**, Sept 2025. Small, tightly scoped engagement: 7 authored commits on `main` (3 README edits, 4 squash-merged feature PRs), 9 PRs opened, 5 merged. All work tracked against Istation Jira tickets (SC-1131, SC-1134, SC-1135, SC-1137, SC-1138, SC-1139, SC-1142) — this repo sits on the Istation side of the Amira/Istation relationship.

Every merged change lands in the Assessment Growth vertical: its report component, its column defs, its filter config, and the shared SQL query builders and sidebar components those depend on.

## Specific technical work (from diffs, not commit messages)

**1. Metrics sidebar extension — "View Type" and "Cut Lines" pickers (PR `#132`, +179/-3)**
- Added two new enum-backed picker components, `ViewTypePicker.tsx` and `CutLinePicker.tsx`, each mapping a TypeScript string enum (`ViewType`, `CutLineType`) onto the shared `MetricSelect` control, with reverse enum-key lookup on selection and a first-option fallback when the current value doesn't match.
- Threaded both as optional props through two layers of the shared `MetricSidebar` -> `MetricSection` hierarchy, gating render on `hasViewTypeConfig` / `hasCutLineConfig` presence checks so every other report that reuses the sidebar is unaffected. This is the repo's established optional-capability pattern (same shape as the existing subscore/classification/usage pickers) — he matched it rather than forking a new one.
- Wired View Type to real behavior in `AssessmentGrowthReport.tsx`: a memoized filter that partitions `assessmentPeriodWindows` by `screeningWindowType` (`DistrictAssignment` for Windows view vs `Period`), then feeds the filtered set into the `useFilters` hook so the period dropdown reflects the chosen view.
- New shared types: `types/view-type.ts`, `types/cut-line.ts`, re-exported through the barrel files.

**2. Demographics filter, end to end (PRs `#133`/`#141`, +28/-3)**
- Added a multi-select "Demographic" entry to `filterConfig`, pulled `demographicsOptions` off Domo's `appData` payload, and passed it into `useFilters` so selected demographic categories flow back out as `selectedDemographicCategories`.
- Extended the SQL builders in `queries/growth.ts` to accept `selectedDemographicCategories` and splice a `getDemographicsSelector(...)` projection into the `SELECT` list of the by-student growth query — so demographics arrive as a real queried column, not a client-side join.
- Threaded the new param through all three call sites: the aggregate fetch, the paged student fetch, and the 500 000-row CSV export path.
- Added a `demographics` column to the TanStack column defs with a null/`"NULL"` -> `"N/A"` guard, since the Domo result set returns the literal string.

**3. Scope reduction — District and Student only (PR `#136`, +8/-37, and PR `#137`, +2/-29)**
- Collapsed a five-branch granularity switch (`district`/`school`/`grade`/`class`/`student`) down to a single ternary, dropping the by-school, by-grade, and by-class query paths and the `sortAndLabelByGradeData` post-processing they needed.
- Removed the `isSchoolAdmin`-conditional default aggregation and the aggregation-option filtering that went with it, hardcoding `by-district` as the entry state.
- Stripped the now-dead filters from `filterConfig`.
- The **why** is the interesting part and is captured in the code: Assessment Growth scores are normed *by grade*, so school/grade/class rollups of those scores are not statistically meaningful. He deleted working UI because it produced misleading numbers — a product-correctness call, not a cleanup.

**4. README** — three edits documenting the monorepo's workspace layout (`admin-reports` vs `domo-iframe-viewer`).

Work that was opened but closed unmerged (still shows scope of the assignment): a Chart/Table view toggle for Assessment Growth (`#154`), a 500-result limit banner on the student view (`#148`), and an unduplicated total-student-count fix (`#142`).

## Quantifiable signals

- 7 commits on `main`, 9 PRs authored, 5 merged, all within Sept 2025.
- ~215 lines added / ~72 removed across merged feature work.
- Touched 12 distinct source files; created 4 new ones (2 components, 2 type modules).
- Export path he threaded demographics through is sized for 500 000 rows.
- Repo is one of several contributors' (Brian Lee, Anastasia Fefilova, Patrick Murphy, Derek Nicol, Ka Sy) — Tory's slice is the Assessment Growth report, not repo-wide ownership.

## Resume-usable framing

- Shipped filter and metric-selection features for a Domo-embedded React/TypeScript admin reporting suite used by K-5 district administrators.
- Extended shared, multi-report sidebar components with new optional pickers without regressing the six other reports that consume them.
- Carried a demographics dimension end to end — UI filter, SQL projection in the Domo query builder, table column, and CSV export path sized to 500k rows.
- Removed statistically invalid school/grade/class rollups from a growth report after identifying that grade-normed scores make those aggregations misleading.

## Caveats

- All contribution is Sept 2025 and narrow (one report). Reads as a short focused engagement, not sustained ownership — do not over-claim scale from this repo.
- The four feature commits are squash-merges attributed to `tory37` with a `Co-authored-by: Tory Hebert` trailer; diffs were read directly and confirm the work.
