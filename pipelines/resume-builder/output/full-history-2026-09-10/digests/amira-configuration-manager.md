# amira-configuration-manager (AmiraLearning)

Internal admin/back-office tool used by CSMs to manage customer license and
entitlement configuration for school districts on the Amira reading-assessment
platform. Private repo, 2 stars. Created 2023-08-14, still active (last push
2026-08-26). Tory was the primary feature contributor over ~2 years.

## Scale signals

- 37 commits authored by `tory37`, spanning 2024-08-13 → 2026-08-12.
- 20 PRs authored, 18 merged (2 open/closed: `#37`, `#44`).
- Languages: JavaScript 129.7 KB, Shell 12.8 KB, CSS 11.4 KB, HTML 1.7 KB.
- Repo lifespan 2023-08 → present; Tory active across ~24 months of it.

## Stack

React 18 (Create React App), AWS Amplify 5 + AppSync GraphQL (two separate
APIs: Student Record Store and Student Information System), Cognito auth,
TanStack Table v8, React-Bootstrap 5, lodash, papaparse,
`@supercharge/promise-pool`, S3 static hosting, AWS SAM/CloudFormation for
infra, shell deploy scripts per environment (dev2 / prod / ca).

## Role and contribution

Effectively the feature owner of the license configuration grid for a long
stretch. Nearly every entitlement/config toggle that CSMs use to turn platform
capabilities on or off per school passed through his commits: the React table
column, the admin-gating rule, the GraphQL fetch/create/update field, the
`schema.graphql` type additions, and the default-config constant — a
four-to-five-file change per flag, done consistently rather than half-wired.

Also acted as a release/branch-flow steward late in the timeline (see
"Release discipline" below).

## Specific technical work

**Curriculum Selector (SC-56, PR `#11`, `df6873f2`, +96)** — added per-school,
per-locale curriculum assignment (EN_US and ES_MX) to the license grid. Modeled
curriculum as an array of `{curriculumId, displayName, locale}` records rather
than two scalar columns, so the dropdown edit had to filter out the existing
entry for that locale and re-push the new one, falling back to an
`enus_default` / `esmx_default` "Amira Default" sentinel when cleared. Wired
the new field through the fetch/create/update GraphQL documents and restricted
the control to admin users.

**Table state and re-render correctness (PR `#9`, `314b661b`, +50/-43)** —
fixed a stale-closure class of bug in the TanStack Table integration. The
column definitions were being rebuilt on every render and each cell renderer
closed over a stale `updatedSchoolConfigs`, so edits and Discard silently
misbehaved. Moved the column array into `useMemo` keyed on
`[updatedSchoolConfigs, isUserAdmin]`, threaded the current config explicitly
into every `renderLicenseSwitch(cell, updatedSchoolConfigs, ...)` call instead
of relying on closure capture, corrected the `tableColumns` memo dependency
list, and replaced `JSON.parse(JSON.stringify(...))` deep-cloning with lodash
`cloneDeep`. Same commit renamed the constants to a validated form
(`VALID_RESOURCE_PROVIDERS`, `VALID_CONTENT_TAGS`, `VALID_LICENSED_CONTENT`,
`LICENSE_LIST_NAMES`).

**Admin-gated configuration tier (PRs `#7`, `#8`, `#10`; AE-14985)** — added a
two-tier permission model to the grid: some config columns are visible to all
users but editable only by admins (`isAdmin` from `AuthUtils` threading into
each switch renderer). Applied it to resource providers (FCRR, Istation, Amira
Teacher) and licensed content flags (Arriba, Into Reading, Resilience).
Follow-up commits fixed the admin-detection bug and the Discard-changes path.

**Bulk config expansion (SC-904, PR `#12`, `10b7246f` + `b57db725`, +114 to
`Licenses.js`)** — largest single push: added and removed a batch of config
columns, added a confirmation modal (custom overlay CSS), and introduced
per-environment AppSync configuration in `aws-exports.js` (dev2 vs prod
endpoints, region, auth type) plus `start:dev2` / `deploy-dev2` npm scripts
that build and `aws s3 sync` into the environment's bucket.

**Sticky table chrome (PR `#26`, `72a6251b`, +63 CSS)** — the grid grew wide
enough that CSMs lost track of which school row they were editing. Replaced
Bootstrap's `responsive` wrapper with a dedicated `.license-table-wrapper`
scroll container and layered `position: sticky` on both the header row and the
School column, working through the z-index stacking (header 10, first column 5,
their intersection 15, a pseudo-element divider at 6), opaque backgrounds so
striped rows don't bleed through the sticky column, and
`scrollbar-gutter: stable` plus `-webkit-scrollbar` overrides so macOS
overlay scrollbars stay visible (`#22`).

**Individual entitlement flags** shipped end-to-end (React column + GraphQL
docs + `schema.graphql` type/input additions + default constant), each on its
own ticket: `scoreType` dropdown (`#20`), `amiraIsipVisibility` (SC-1036,
`#13`), `alwaysAllowTutor` (SC-1044, `#15`), `blockAssessmentRescore` (`#18`),
`ignoreBrowserCompatibilityCheck` (`#16`/`#19` — caught that the create schema
was missing the field the update schema already had), `excludeMicrolessonsByDefault`
(`#17`), block-assessment settings (`#24`), `useGradeLevelSoda` (ASSMNT-670,
`#35`), and `assessmentControlCanEditBilingualConfiguration` RBAC field
(CR-10490, `#49`). Also fixed onboarding curriculum blocking for non-admins
(SC-1035, `#14`) and default English reporting language.

## Notable design decisions

- **District-level toggle abstraction (ASSMNT-760, PR `#37`, unmerged, +135)** —
  rather than adding yet another per-school column for `evaluarPilotEnabled`,
  built a reusable `useDistrictToggle` hook plus `DistrictToggle` component that
  aggregates a per-school boolean into a single district-wide switch, with a
  defined indeterminate state when schools disagree. A generalization of the
  grid's editing model, not a one-off field.
- **Consistency over invention on RBAC fields** — new permission fields were
  deliberately given the same default role set as their existing sibling
  (`assessmentControlCanEditBilingualConfiguration` mirroring
  `assessmentControlCanEditStudentLanguage`) and kept as a dedicated field
  rather than overloading the sibling.
- **AI-assistant onboarding docs (PR `#44`, unmerged, +272)** — proposed an
  `AGENTS.md` documenting app purpose, the two-AppSync-API pattern, directory
  layout, and per-environment schema files (`schema.dev2/prod2/ca.graphql`).

## Release discipline

In 2026-08, a CR-10490 PR that was approved for `develop` got merged straight
to `main`, bypassing the `feature → develop → release branch → main` flow.
Tory caught it and resolved it cleanly in two PRs the same day: a revert on
`main` (`#51`) and a cherry-pick of the same change into `develop` (`#50`), so
the fix went out through a proper release branch instead. He also cut the
release PR for the Use Grade Level Soda change (`#40`). This is process
ownership, not just feature work.

## Not his work (do not attribute)

The SIS-1504 security remediation (removing embedded AppSync API keys, moving
to per-environment Cognito Identity Pools + AWS_IAM, SAM/CloudFormation infra,
bucket HTTPS enforcement, deployment runbooks) was authored by Patrick Moon
(`moon-amira`) in 2026-08. Batch license loading for large districts was Ryan
Conlon. Tory's earlier `aws-exports.js` work predates and was superseded by
that remediation.
