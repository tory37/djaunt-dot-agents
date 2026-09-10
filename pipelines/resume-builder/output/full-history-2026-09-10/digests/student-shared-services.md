# amira-rnd/student-shared-services

**What it is:** `@amira-rnd/student-shared-services` — a private, versioned TypeScript npm package (published to GitHub Packages) holding the shared business logic that every Amira student-facing front end uses to resolve "what does this student do next." Consumed by `olp-student-experience` (Angular) and `lexa-studentapp`. Description: "Shared services to use between student front end products."

## Role and contribution

Tory created the repo and is its primary author — the initial commit (`c780802a`, 2025-06-17, ~3.7k lines) is the whole package skeleton, and he authored essentially every substantive change through 2026-09. 39 authored commits, 6 merged PRs, 15-month lifespan (2025-06-17 → 2026-09-03). Private repo, 0 stars/forks (internal library, not OSS).

This is a **library-owner / platform role**, not feature work in an app: the deliverable is an API that two independent client teams depend on, so decisions here are about where logic belongs, how it is versioned, and what each consumer no longer has to duplicate.

## Technical work and problems solved

**Extracted duplicated student-assignment logic into a framework-agnostic shared library.** The initial implementation (`c780802a`) established `AmiraAssignmentService` plus enums (`AmiraAssignmentActivityTypes`, `AmiraAssignmentStatus`, `AmiraAssignmentDisplayStatus`, `AmiraAssignmentTypes`, `Grades`, `MessageCodes`), typed GraphQL documents (`STUDENT_INBOX_QUERY`, `ADD_STUDENT_ASSIGNMENT_MUTATION`, `GET_ASSIGNMENTS_FOR_STUDENT_QUERY`), and pure filter utilities. Deliberately framework-agnostic: instead of RxJS/Angular bindings, the service exposes a hand-rolled `subscribe(callback)` returning an unsubscribe closure, so an Angular app and a plain-JS app can both consume it. `@angular/core` and `rxjs` are peer deps only.

**Assignment resolution pipeline.** `getNextAmiraAssignment()` derives student/school/district/grade from injected user data, queries the student inbox, filters invalid manifest activities (skipping assessment assignments, whose manifests aren't launched item-by-item), picks the first incomplete assignment, and — when the assignment is owned by a DISTRICT/SCHOOL/GROUP/TEACHER rather than the student — instantiates a student-scoped copy via mutation. Includes a fallback chain: if instantiation fails, the failed assignment is dropped from the candidate list and resolution recurses to the next one (`getNextAssignmentAfterFailed`).

**Multi-endpoint service factory (SC-654, PR #6, `962ee29d`).** The single-GraphQL-client design was silently hitting the wrong endpoint and producing a "Curriculum Lesson Info query failed" error. Tory added a `ServiceFactory` that constructs and injects a distinct client per backing service (amira-assignment, skills-mastery, curriculum-lesson-plan, later SIS and a legacy REST `ApiClient`), plus a README migration guide for consumers moving off the one-client constructor. Later commits grew the factory to 6 injected dependencies while keeping a single `createServiceFactory()` entry point.

**SIS-driven assessment suppression (SC-543, PR #8, `b2024b19`).** Added a new `SISService` + `sis-queries` and wired `filterAssessmentAssignments()` into inbox resolution so students whose SIS record has `metadata.assessmentEnabled === false` stop being served assessments. Two deliberate design calls, both about failing open: (1) product required null/undefined to mean *enabled*, so the check is explicitly `=== false` and nothing else — Tory flagged the tri-state as a bad contract in an inline comment rather than silently implementing it; (2) any SIS error or missing student returns all assignments unfiltered, so an SIS outage can never block a student from working. Landed with 124 lines of new `sis-service` tests plus 367 lines of service-level assertions.

**Automatic-assignment grade gating, then a correctness rework (SC-1057, PRs #30/#31).** First pass (`69d6486`) filtered at the *assignment* level: if a student's grade wasn't in `automaticTextSetAssignments` / `automaticInstructAssignments`, whole assignments were dropped, with text-set vs. instruct activity types cross-checked against which list the grade belonged to. Code review with the backend owner surfaced that this was too coarse — with text sets off, all four curriculum assignments vanished entirely. The rework (`5321ffba`) pushed the decision down to the **manifest-item** level: `isManifestItemIncomplete` now takes the assignment type and grade config, resolves the item's skill, and reports a gated item as "complete" so resolution walks past it instead of discarding its parent assignment; assessment-type assignments are exempted from the gate. Along the way (`d3a5657d`) he collapsed three near-identical inline grade/`BK`-skill-prefix branches in the service into one shared `shouldSkipSkillBasedOnAutomaticLogic()` used by both assignment *creation* and assignment *selection*, removing the drift between the two paths, and replaced a 3-argument config passthrough with a single `UserData` object. PR #31 carries hand-run validation screenshots across four text-set on/off scenarios.

**Optional structured logging passthrough (SC-1052, PR #34, `53c12c6e`).** Added a `Logger` interface as an *optional* constructor arg (consumers that don't pass one lose nothing) and instrumented the filtering pipeline with structured events — `studentInbox_query`, `student_assignment_instantiated`, `assignment_filtering` — each carrying `filterType`, `filterReason`, skill/student ids, grade config, and the specific resources removed. This made "why did this student see nothing?" answerable from logs instead of by local repro, covering both subscription-based removal (no instruct / no tutor subscription) and automatic-assignment gating.

**Subject-tile resolution fix for FORMATIVE assignments (ASSMNT-2499, PR #67, `949bb0a4`).** Subject classification was tag-driven with Reading as the fallback bucket, so FORMATIVE (Amira Adventures) assignments — which carry no subject tag — classified as Reading and got handed to any client asking for the next Reading assignment, meaning a client that had never heard of Adventures would launch one as an ordinary assessment. Tory added an exported `NON_SUBJECT_ASSIGNMENT_TYPES` set filtered ahead of tag matching in `filterAssignmentsBySubject`. Documented rationale in the PR: the check sits in the filter rather than in `assignmentMatchesSubject` so the tag classifier stays single-axis and the next such type is a one-line addition; an alternative `AOS-FORMATIVE` tag was considered and rejected because it required a new producer plus cross-team AOS coordination for the same result. Fixing it in the shared library meant `lexa-studentapp` got the fix for free and `olp-student-experience` could delete its own duplicate type filter.

**Package/build hygiene.** Set up subpath exports (`./services`, `./types`, `./enums`, `./utils`) with per-entry type declarations, `dist`-only publishing, ESLint + `@typescript-eslint`, and Jest/ts-jest. Also restructured the tree out of a `src/core/` nesting into flat `src/{services,types,enums,utils,queries}` (`50a1c654`), fixed an import path that broke `npm link` local development, and documented the `npm link` workflow for testing library changes against a consuming app before publish.

## Testing

Heavily test-first for a library of this size: single commits add 880-907 lines of spec at a time (`b2f9b23f`, `8886e6de`), and the final PR reports **375 passing tests across 11 suites**. Spec files consistently accompany behavior changes rather than trailing them, and PR #67's test plan names four targeted assertions including the negative case (a Reading assignment next to a FORMATIVE one must still resolve — the exclusion must not swallow neighbours).

## Quantifiable signals

- 39 commits, 6 merged PRs, sole primary author
- Created 2025-06-17, still active 2026-09-03 (~15 months)
- ~523 KB TypeScript (99.9% of the codebase); 375 tests / 11 suites
- 2 downstream consumer applications (`olp-student-experience`, `lexa-studentapp`)
- 6 backing services integrated behind one factory (assignment, skills-mastery, curriculum-lesson-plan, SIS, legacy REST API, optional logger)
- Jira-tracked work across two boards: SC-543, SC-654, SC-1052, SC-1057, ASSMNT-2499

## Tech stack

TypeScript, GraphQL (Apollo Client, graphql-tag), RxJS (peer), Node 18, Jest + ts-jest, ESLint, npm packaging to GitHub Packages, Angular (peer consumer), dependency injection / factory pattern, observer pattern.
