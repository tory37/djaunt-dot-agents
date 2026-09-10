# amira-sis-api (AmiraLearning) — digest

- **Repo:** `AmiraLearning/amira-sis-api` (GitHub id `184444296`, private, not a fork)
  - NOTE: a separate, unrelated repo of the same name exists in the `amira-rnd` org. This digest covers **only** the AmiraLearning one.
- **Purpose:** AWS AppSync GraphQL API fronting Amira's SIS hierarchy (District → School → Classroom → Student/Teacher). Federates lookups across four backing sources: Magic, Amira SIS on AWS Cloud Directory, Amira SIS AtHome, and archived rosters in S3.
- **Stack:** Node.js (JavaScript) Lambda resolvers, AWS AppSync, CloudFormation/SAM (`template.yaml`), `@aws-sdk/client-appsync`, shell-based pre/post deploy snapshot-diff test harness. Languages: JavaScript 56.5 KB, Shell 31.4 KB.
- **Lifespan:** created 2019-05-01, still active (last push 2026-08-08). Stars 0 / forks 0 (private internal service — not a meaningful signal).
- **Team scale:** ~121 commits on `develop` from ~8 contributors; primary owner is another engineer (`shoelessrob`, ~68 commits).

## Tory's role and contribution

Occasional contributor, not owner. **11 commits (4 merged PRs)** spanning **2024-02 → 2025-09**. Every contribution was a **GraphQL schema/contract change** to `sis_api_schema.graphql` — extending the `StudentMetadata` type and the `updateStudentMetadata` mutation so the student-facing clients could persist new per-student state through the SIS API.

This is cross-service API-contract work: the actual UI/feature work lived in the student app repos, and Tory came into the shared SIS service to add the field on both the read type and the write mutation, keeping the two in sync so AppSync could round-trip it.

### Merged PRs

| PR | Date | Change |
|---|---|---|
| `#46` | 2024-02-14 | `hasSeenCaptureEmailModal: Boolean` — persists whether the teacher-email capture modal has been shown to a student |
| `#49` | 2024-06-18 | `hasSeenDialogFTUE: Boolean` — first-time-user-experience dialog seen-state |
| `#56` | 2025-04-10 | `selectedTutorRig: String`, `selectedTutorSkin: String` — persists a student's chosen Amira tutor avatar (rig + skin) |
| `#58` | 2025-09-26 | `extendAssessmentTime: Boolean` — accommodation flag extending a student's assessment time limit (Jira `SC-1068`) |

## Diff-verified findings (read the actual patches, not just messages)

- All 11 commits touch exactly one file: `sis_api_schema.graphql`. No resolver or infrastructure code.
- Real change size is **~9 added schema lines total** across the four PRs. Each field was added in two places (the `StudentMetadata` output type and the `updateStudentMetadata` mutation input signature).
- Two commits show inflated stats (`db6074e` 89/87, `28e0dca` 87/87) — these are **whitespace churn only**: a whole-file tab→space reindent, then a revert back to tabs in a follow-up commit titled "cleanup". Excluded from the substance assessment.
- `extendAssessmentTime` (`SC-1068`) is the most product-meaningful of the four: an assessment-accommodation flag, Jira-tracked, the only one with a ticket linked in the PR body.

## Resume value

**Low on its own.** Small, additive schema edits to a service owned by someone else — no architecture, no resolver logic, no infrastructure, no measurable scale impact. Nothing here supports a standalone bullet.

**Useful only as supporting evidence** for a broader claim made from the student-app repos, e.g. "shipped features end-to-end across a microservice boundary — extending a shared AWS AppSync GraphQL API's schema and mutations so client-side state (tutor avatar selection, FTUE progress, assessment-time accommodations) persisted through the SIS layer." Cluster this with the student-app / studentapp-AI digests rather than giving it its own bullet.

**Concrete signals available if needed:** GraphQL / AWS AppSync schema design, cross-team API contract changes, Node.js serverless service on CloudFormation, 4/4 PR merge rate, 19-month contribution span in a shared multi-team service.
