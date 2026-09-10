# amira-parent-portal

**Repo:** `AmiraLearning/amira-parent-portal` — Amira IES Parent Portal (JavaScript/React + SCSS, 50MB, private).
**Created:** 2022-12-21 · **Last push:** 2026-09-08 · **PRs by tory37:** 27 · **Commits by tory37:** 68 (2023-07-10 → 2026-04-22, ~2.75 years).

## Role and contribution

Primary/lead frontend engineer on the Parent Portal — a React + SCSS web app giving
K-3 parents their child's reading results, running record, and at-home practice
videos. Owned the app end to end across this window: AWS Amplify/Cognito auth,
AWS AppSync GraphQL data services, an internal admin provisioning tool, Segment
analytics, and full Spanish (es-MX) localization.

## What was actually built

**Custom Cognito auth UI on AWS Amplify** — replaced stock `aws-amplify-react`
screens by subclassing Amplify's `SignIn`/`ForgotPassword`/`ConfirmSignUp` and
driving `@aws-amplify/auth` directly, keeping Amplify's state machine but none of
its UI. Built a six-box auto-advancing confirmation-code input, instrumented every
auth step with Segment funnel events, and refactored the shared `AuthForm` into a
config-driven renderer. Fixed real production defects: browser autofill leaking
into auth forms, an unusable post-reset login flow, silent phone-validation
failures.

**AppSync/GraphQL correctness fix** — found and fixed a class of silent
"student not found" bugs: DynamoDB-backed `list*` queries with a filter can return
an empty page while more pages exist. Rewrote the access-key lookups to loop on
`nextToken` until a match or exhaustion, and switched a scan-with-filter to an
indexed query.

**Internal admin provisioning tool, built solo end to end in 4 days** — took the
admin tool from single-student to bulk: comma-separated student list fanned out
with `Promise.all`, idempotent access-key lookup (so a re-pasted roster doesn't
orphan keys), and a printable PDF/QR handout per student. Evaluated and swapped
PDF libraries mid-feature (`jsPDF` → `@react-pdf/renderer`) once per-student page
layout was needed, hand-ported the Amira logo into inline SVG primitives after
`@react-pdf/renderer` couldn't load a local raster asset, and registered a custom
webpack font-loader rule for the brand font.

**Phoneme-to-letter display mapping for parents** — Amira's running record stores
IPA phonemes, meaningless to a parent. Built a mapping table plus a per-story
override layer so the same phoneme renders as the correct letter/digraph
depending on which story it came from, threading story/phrase context down
through the component tree to make it possible.

**Spanish (es-MX) localization** — react-i18next setup across `en-US`/`es-MX`/`hi-IN`,
locale-filtered the practice-video list so Spanish parents never land on an
English-only video, and built a dev-only debug console for QA to force a locale
without a backend account change.

## Problems solved

- Silent pagination bug in GraphQL access-key lookups that could report "student
  not found" even when the student existed.
- Idempotency gap in the admin bulk tool that would have orphaned access keys on
  a re-run.
- `@react-pdf/renderer`'s inability to render a DOM QR component or a local raster
  logo — solved with hidden-canvas `toDataURL()` extraction and hand-ported SVG.
- Fisher-Yates shuffle + Spanish-dub filtering so the activity list never surfaces
  content a locale doesn't support.

## Design decisions worth naming

- Subclassed Amplify's components rather than replacing the library, keeping its
  auth state machine while fully rebranding the UI.
- Config-driven `AuthForm` (field descriptors) instead of one component per screen.
- Chose `@react-pdf/renderer` over `jsPDF` mid-feature once per-student layout
  complexity demanded it — a real build/tooling tradeoff made under time pressure.

## Quantifiable signals

| Signal | Value |
|---|---|
| Commits (tory37) | 68 |
| PRs (tory37) | 27 |
| Active span | 2023-07-10 → 2026-04-22 (~2.75 years) |
| Largest single-feature diffs | ~900 and ~800 changed lines (auth rewrites) |
| Production surface | `parent.amiralearning.com`, Jira-tracked delivery |

## Recommended resume use

Strong bullet candidate: sole/lead frontend owner of a production parent-facing
web app spanning auth, GraphQL data layer, an internal tool, and full
localization — with a specific, quantifiable bug fix (GraphQL pagination) and a
concrete build-tooling decision (PDF library swap) to anchor it.
