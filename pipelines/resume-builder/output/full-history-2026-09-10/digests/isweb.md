# istation-cloud/isweb

**Repo:** istation-cloud/isweb (private) · created 2022-11-10 · last push 2026-09-09 · 6 stars, 1 fork
**Stack:** C# / ASP.NET MVC (Razor `.cshtml`), JavaScript, LESS/SCSS/CSS, PowerShell, Ansible, AWS CodeDeploy
**User activity:** 10 commits, 10 merged PRs (PR #1141 → #1231), 2025-10-20 → 2026-05-05. 100% merge rate; repo requires 2 approvals per PR.

## Role and contribution

Feature contributor on ISWeb — Istation's educator-facing web application (the teacher/admin portal for classrooms, reports, student profiles, and assessment administration). It is a large, long-lived ASP.NET MVC monolith deployed via Ansible + AWS CodeDeploy across multiple environments (dev2, prod2, canada, APP1-8).

Two distinct workstreams, both narrow in commit count but high in leverage:

1. **Assessment Reset V2** — designed and built a GraphQL-backed replacement for the legacy SQL-based assessment reset tool (Oct 2025).
2. **Product-gating for the Amira migration** — gated legacy Istation Lectura (Spanish) features behind subscription checks so schools moving to Amira Spanish see the correct navigation and report set (Feb–May 2026).

## Notable technical work

### Assessment Reset V2 — GraphQL service layer in a legacy MVC app (PR #1141, +2,429/-111 across 20 files)

Built from scratch, not a refactor. The single largest change in the user's history on this repo.

- **`ISWeb/Services/GraphQL/GraphQLAssessmentService.cs` (+675, new)** — a hand-rolled GraphQL client (HttpClient + Newtonsoft `JObject`, no GraphQL client library) that fans out to two separate backend services: the Assignment Service (assignment queries + `ResetAssignment` mutation + audit log query) and the SRS Service (`getActivity` score lookups). Endpoints and API keys resolved from `ConfigurationManager.AppSettings`, with fail-fast constructor validation when config is missing.
- **Interface + factory** (`IGraphQLAssessmentService.cs` +103, `GraphQLServiceFactory.cs` +27) — kept the new service seam testable and injectable inside a legacy MVC codebase that largely predates DI.
- **Domain-specific query logic** — derived the current school year from the current date (August rollover) to build `dateFrom`/`dateTo` filters; mapped numeric student grades to the GraphQL `Grade` enum; filtered to `BENCHMARK` assignments in `DONE`/`COMPLETE` status only, matching the business rule that only completed assessments are resettable.
- **Score resolution with fallbacks** — multi-step logic to decide whether an assignment is genuinely resettable: skip any assignment where an activity carries `reassess` status; special-case `ES_MX`-tagged (Spanish) assignments; fall back from the primary assessment activity to a scan across all activities when no score fields (`ISIP_overall_universal`, `armScore`, `equatedWCPM`, and their percentile-rank variants) come back populated.
- **Audit trail** — new `AssessmentResetHistExportV2.cs` (+286) export model plus a `ReportController` endpoint, rewritten against the new GraphQL audit-log schema (`stateDistrictId` / `studentDistrictId`).
- **Authorization** — added `stateDistrictId` scoping so a reset request is authorized against the *acting user's* district, not just the target student's.
- **Deployment/config plumbing** — added GraphQL endpoint + key settings across `aws/ansible/group_vars` (all, dev2, prod2, canada), `isweb-LocalSettings.config`, and the CodeDeploy `AfterInstall-environmentVariables.ps1` hook. Shipped the feature end to end, not just the app code.
- **New UI** — `ResetAssessmentV2.cshtml` (+221), `ResetSearchFormV2.cshtml` (+58), and a substantial rewrite of the existing `ResetAssessment.cshtml` (+402/-103).

### Iterative hardening of Reset V2 (PRs #1149, #1150, #1154, #1157, #1158)

Five follow-up PRs over four days, each fixing a defect found against real data:

- Null-activity-ID guards on GraphQL calls, and filtering out assignments with zero valid activities (#1149/`897f475a`).
- Corrected the user-facing "Assessment Date" to use the latest activity's `createdAt` rather than the assignment's (#1154).
- Reworked audit history fields to match the updated GraphQL schema (#1150).
- Kept the legacy V1 tool alive behind its own route so V1 and V2 could run side by side during rollout rather than a hard cutover (#1157, +499).

### Reset tool correctness fixes (PRs #1190, #1231)

- **ASSMNT-694** — teachers could assign a second BENCHMARK assessment in a screening window but then could not remove it, because the tool only surfaced the most recent assessment per window. Replaced the group-and-take-latest logic in `LoadV2BenchmarkData` and `ResetAssessment` with a full per-window listing ordered by window (BOY/MOY/EOY) then date descending; surfaced Assignment ID in both the selection and confirmation tables; corrected status labels (`DONE` → "Completed", `COMPLETE` → "Scoring").
- **CR-10174** — prereader students finish assessments with `status=not_started` / `displayStatus=prereader` rather than `scored`, so the reset eligibility check silently excluded them from EOY resets. Widened the predicate to accept the prereader state. A 31-line fix on a non-obvious data-model quirk.

### Legacy-product gating for the Amira Spanish migration (PRs #1195, #1205)

- **ASSMNT-803** (`b25f5207`, 22 files) — introduced a single `ShouldHideLegacyFeatures` check (`!ProductKeys.Contains(ProductKey.SP)`) and threaded it through the model graph: `AOrgModel`, `ClassroomModel`, `ClassroomNav`, `DomainNav`, `ClassroomODA`, `HomeModel`, `StudentProfileForm`, `ReportLists`, `UserProfileSpec`. Used it to hide the Lectura product dropdown entry, ISIP Español / Español AR tabs, Reading Risk and RAN nav links, campus "% assessed"/"% active" columns, and the Student Edit customizations panel. Passed the same flag from Razor into the report-builder JavaScript (`ProductData.js`, `GatingReportClass.js`, `SysReportClass.js`, `StandardsReportMathClass.js`) to filter Priority Summary, Gating Up History Export, Standards Report, and End of World from report lists — one source of truth spanning both server and client.
- **ASSMNT-973 / PR #1205** — follow-up once Amira Spanish packages started being configured with entry points (`SpanishReading`, `ISIP_Espanol`, `PowerPath_Spanish`) that map to `ProductKey.SP`. The naive check would have (a) dropped Amira Spanish users into the limited `NoLegacyProduct` nav profile and (b) re-exposed legacy Lectura features to them. Added `DomainHasAmiraSpanishProduct` to the `FullLegacyIstation` nav-profile condition and changed the gate to `!ProductKeys.Contains(SP) || HasAmiraSpanishSubscription`, validated against a three-way user matrix (legacy Lectura only / Amira Spanish only / neither).

## Design decisions worth noting

- Chose a side-by-side V1/V2 route split over a hard cutover, letting the legacy SQL reset path stay available while the GraphQL path proved out in production.
- Introduced a service interface + factory seam for the GraphQL layer inside a codebase without established DI, keeping the new integration isolated and swappable.
- Collapsed a cross-cutting product-visibility rule into one named property propagated through models, instead of scattering subscription checks across ~22 view and script files.
- Shipped config for every environment (dev2, prod2, canada) plus the CodeDeploy hook in the same PR as the feature — no follow-up deploy ticket.

## Quantifiable signals

- 10 commits, 10 merged PRs, 100% merged, over ~7 months (2025-10 to 2026-05).
- Largest change: +2,429/-111 across 20 files (new GraphQL service layer, views, exports, and multi-environment deploy config).
- Two backend GraphQL services integrated (Assignment Service, SRS Service); 4 deploy environments configured.
- Cross-cutting gating change touched 22 files across C# models, Razor views, and report JavaScript.
- Repo is a shared enterprise monolith: 2-approval PR policy, GitVersion semantic versioning, Ansible + AWS CodeDeploy release pipeline.
