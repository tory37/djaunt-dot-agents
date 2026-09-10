# istation-hydra/olp-student-experience

## What the repo is

Istation's Open Learning Platform **student experience** — a production Angular 16 single-page app that is the K-12 student-facing front door for Istation/Amira reading and math. It is a hybrid app: Angular UI on top of a large legacy C++ runtime compiled to **WebAssembly**, bridged through a JS interop layer, with Canvas/WebGL rendering for the legacy activities. Ships as a PWA (service worker) and also runs on iPad.

- Created 2021-12; still actively pushed (2026-09).
- Languages: TypeScript (~3.17M bytes), SCSS (~289K), HTML (~156K); Docker/Make/Shell for build.
- 5 stars, 0 forks (private org repo — stars are not a meaningful signal here).
- Stack: Angular 16, RxJS, Apollo Angular (GraphQL), ngx-translate (i18n), angular-auth-oidc-client (OIDC), Unleash feature flags (`unleash-proxy-client`), SignalR (`@microsoft/signalr`), Sentry, AWS SDK v3 + Amplify + Cognito + SigV4 request signing, Jasmine/Karma, Husky, custom Webpack builder.

## Tory's role and contribution

Feature developer on the student experience app during the **Amira Learning / Istation platform merge** — most of his work is the seam where the Amira product (assessment, tutoring, assignments) is grafted into the Istation student UI.

- **48 commits** authored, **Jan 2025 → Jun 2026** (~18 months of continuous contribution).
- **~35 merged PRs** (about 50 PRs opened total, including release/experiment branches).
- Work is consistently test-covered: nearly every feature commit ships matching `.spec.ts` updates (Jasmine spies, `BehaviorSubject` fakes, `TestBed` module wiring) — several commits are majority test code.

## Specific technical work

### Cross-repo shared-library extraction (PR #1203, largest commit — 45 files, ~3.4K changed lines)
Migrated the app's Amira assignment layer out of the local codebase and onto a new private npm package, `@amira-rnd/student-shared-services`, consumed across multiple front ends.
- Deleted local GraphQL documents (`STUDENT_INBOX_QUERY`, `ADD_STUDENT_ASSIGNMENT_MUTATION`, `GET_ASSIGNMENTS_FOR_STUDENT_QUERY`, skills-mastery and curriculum-lesson queries) and the local `AmiraAssignment*` enum family (~200 lines of duplicated enums/types), repointing every import to the shared package's `/types`, `/enums`, `/utils` entry points.
- Added a second scoped registry (`@amira-rnd`) to `.npmrc` for GitHub Packages auth.
- Wired `AmiraAssignmentService` into Angular's `APP_INITIALIZER` with a bootstrap gate that waits for the Apollo client to be ready before initializing, and resolves-on-error so a failed assignment fetch cannot block app startup.
- Same PR added assignment support for the **partner login path** (students entering from a partner IdP rather than the Istation login).
- Follow-on commits (#1206, #1218, #1294, #1304) tracked breaking changes in the shared package: TS config fixes when `initialize()` stopped returning a promise, consuming `isManifestItemIncomplete` from shared utils, version bumps.

### Client-side logging/telemetry service (PR #1308/#1312 — 29 files, ~1.4K changed lines)
Integrated a device/usage logging service behind an Unleash flag (`enableLoggingService`), fired after user authentication in `AppComponent` with the authenticated user id pushed into the service.
- Brought in **AWS Amplify + SigV4 request signing** (`@aws-crypto/sha256-browser`, `@smithy/signature-v4`, `@aws-sdk/client-cognito-identity`) so the browser can sign requests to the log endpoint with Cognito credentials.
- Failure is non-fatal by design — logging errors are caught and swallowed so telemetry can't break the student session.
- Built an in-app **debug-menu harness** (form for log type / arbitrary JSON payload / forced activity id, plus success-error result panel) so QA could exercise the logging path without a build.

### Evaluar Spanish assessment pilot (PR #1367, ASSMNT-701 — 8 files, ~450 lines)
Implemented the self-assign flow for the Evaluar (Spanish assessment) pilot.
- Added a `batchAddAssignment` GraphQL mutation binding against the assignment service, including a numeric-grade → GraphQL `Grade` enum map (`NUMERIC_GRADE_TO_GRAPHQL_GRADE`).
- New `EvaluarPilotService` creating Spanish-only `PROGRESS_MONITORING` assignments, with an `AOS-SPANISH` tag lookup used for **duplicate-assignment prevention**, plus the inbox-dialog launch flow.
- Deliberately quarantined the pilot code: the service is documented as temporary, kept **out of the services barrel export** to avoid a circular dependency, and carries an explicit post-pilot removal/GA-refactor note. Refactored `ActivityLauncherService` to an RxJS pipeline (`switchMap`/`timeout`/`finalize`) so the launch path has a bounded wait and always clears its loader.

### School-year scoping of assignments (PR #1338)
Made `CalendarService` fetch the current assessment school year and had `AmiraAssignmentService` automatically append `schoolYears: [currentYear]` to every assignment query/mutation — fixing cross-year assignment bleed without touching each call site.

### Assessment eligibility via an external state service (PR #1110, SC-226)
Added `IdahoAssessmentService` and an `ExternalAssessmentEligibility` DTO so the home page could ask a state-specific service whether a student is eligible to assess; shipped behind a feature flag and required extending the generic `api-handler` class (+71 lines) to support the new call shape.

### Spanish calibration launch (PR #1328/#1361)
`AmiraSpanishIsipPilotService` plus nav-component launch button, gated by a new feature flag threaded through **all six environment configuration files** (dev, rc, staging, prod, prod2, prod-ca).

### Student-facing UX and i18n work (many smaller PRs)
- Converted `AssessmentService.hasAssessed` from a plain boolean to a `BehaviorSubject` so subject cards react to assessment state instead of reading a stale snapshot; drove a dynamic "Assessment Complete!" subheading for assess-only licenses (#1315).
- Full **Spanish translation pass on the student inbox** for students configured for Spanish tutoring — added `tutorInSpanish` to the SIS GraphQL user query and plumbed `TranslateModule`/`| translate` through the subject-card component tree (#1196).
- Tutor Picker navigation from the profile popup (#1151); mic-test confirmation modal and launch button (#1275); tutoring access allowed even when assignments exist (#1286); ISIP-based character art on subject cards (#1281); loading screens for external Amira launches (#1097, #1117, #1124); logout-screen branding (#1111, #1127).
- Removed the dead `app-launch` page and redirected it to home (#1221), deleting ~200 lines of superseded bootstrap/compatibility code.
- Ran production feature-flag operations directly (enable/disable `amiraIsipPilot`, `spanishIsipPilot`, `amiraEvaluarPilot` per environment config).

## Notable design decisions

- **Fail-open telemetry and bootstrap**: both the logging service and the assignment `APP_INITIALIZER` resolve on error rather than blocking or crashing the student session.
- **Deduplicate across apps rather than in-app**: chose to move shared assignment types/queries/utils into a versioned npm package consumed by multiple front ends, accepting the cost of tracking its breaking changes.
- **Pilot code is explicitly disposable**: pilot services are isolated, flag-gated, and annotated with removal conditions instead of being woven into the permanent launch flow.
- **Everything ships behind an Unleash flag** with per-environment configuration, so features land dark and are enabled by environment.
- Reactive state via `BehaviorSubject` rather than imperative fields, so UI stays consistent with async data.

## Quantifiable signals

| Signal | Value |
|---|---|
| Commits authored | 48 |
| Merged PRs | ~35 (of ~50 opened) |
| Contribution span | 2025-01 → 2026-06 (~18 months) |
| Repo lifespan | 2021-12 → present |
| Largest single change | 45 files / ~3.4K lines (shared-library extraction) |
| Environments configured | 6 (dev, rc, staging, prod, prod2, prod-ca) |
| Codebase size | ~3.2M bytes TypeScript |
