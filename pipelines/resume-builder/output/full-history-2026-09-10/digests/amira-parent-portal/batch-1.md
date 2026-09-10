# Batch 1 digest — AmiraLearning/amira-parent-portal

Date range: 2023-07-20 → 2026-04-22 (newest 50 of 68 commits by tory37, commits-API page 1)
Repo metadata/languages/PR counts: see `repo-context.md` (not re-fetched here).

## Role in this batch

Primary/lead frontend engineer on the Amira IES Parent Portal — a React + SCSS
web app (Webpack/Cordova-style `www/` build) that gives parents of K-3 students
their child's reading results, a running record of the child's oral reading, and
short at-home practice activity videos. Tory owns the app end to end in this
range: AWS Amplify/Cognito auth flows, AppSync GraphQL data services, an internal
admin tool for provisioning parent access codes, Segment analytics instrumentation,
and full Spanish (es-MX) localization.

## Substantial technical work (from diffs, not commit messages)

### Custom Cognito auth UI on top of AWS Amplify (`5150f416`, `2b654665`, `c1ea1a1e`, ~1,700 lines across login)
- Replaced the stock `aws-amplify-react` auth screens by subclassing Amplify's
  `SignIn` / `ForgotPassword` / `ConfirmSignUp` components and driving
  `@aws-amplify/auth` (`Auth.forgotPassword`, `Auth.forgotPasswordSubmit`)
  directly, so the branded flow kept Amplify's state machine but none of its UI.
- Built a six-box, auto-advancing/auto-backspacing confirmation-code input with
  per-field focus handling, plus new-password/confirm-password validation.
- Instrumented every auth step with Segment events (`forgot_password_attempt`,
  `_success`, `_error`, `password_reset_*`) so drop-off in the parent signup
  funnel became measurable.
- Refactored the shared `AuthForm` into a config-driven form renderer (field
  descriptors: id/name/type/placeholder/autoComplete) and consolidated login
  chrome into a single `AmiraLoginContainer` + SCSS, deleting duplicated
  per-screen markup and styles.
- Fixed real production auth defects: browser autofill leaking into auth forms
  (`c1ea1a1e` — `autoComplete: "off"`, explicit `type` on every field), an
  unusable post-reset login that needed a `?passwordReset=1` reload workaround,
  and phone-number validation with a human-readable error instead of a silent
  failure (`e6396a35`, `7957f4c4`, `76ec8643`).

### AppSync/GraphQL data-access correctness (`d9953169`, `823960b5`, `465cb01c`)
- Fixed a class of silent "student not found" bugs: DynamoDB-backed AppSync
  `list*` queries with a filter return a *page* that can legitimately be empty
  while more pages exist. Rewrote `getAccessKeyByStudentId` / `getAccessKeyByHomeId`
  to loop on `nextToken` until a match is found or pagination is exhausted, and
  switched the studentId lookup from a scan-with-filter to the indexed
  `accessKeyByStudentId` query.
- Wired Segment `identify` into the access-key resolution path so a parent's
  session carries studentId, teacher email, preferred language, phone-only flag,
  and trial status.

### Internal admin provisioning tool (`2f9b0b7b`, `71c24146`, `614fa676`)
- Built the admin screen that bulk-creates parent-portal access keys from pasted
  `studentId, teacherEmail` pairs (newline-split, `Promise.all` fan-out), then
  renders each as a QR code (`qrcode.react`) and a printable PDF
  (`@react-pdf/renderer`) pointing at `parent.amiralearning.com/?accessKey=`.
- Added loading state and try/catch around the batch call so a single bad row
  no longer left the operator staring at a dead screen.
- Access to the tool is gated by an explicit admin email allowlist in constants.

### Phoneme-to-letter display mapping for parents (`2ad92816`, `43f15284`)
- Amira's running record stores IPA phonemes (`æ`, `ɛ`, `ʤ`, `ɹ`, `ʃ`, `θ`, …),
  which are meaningless to a parent. Added a `PHONEME_TO_LETTER` table plus a
  per-story override layer: the same `/k/` phoneme renders as `c`, `k`, or `ck`
  depending on which story (and, in one case, which word position) it came from,
  and `/l/` renders as `ll` in a specific segmenting story.
- Threaded `storyid` and `phraseIndex` down through `RunningRecord` → `Phrase` →
  `Word` to make that context-sensitive mapping possible.

### Spanish (es-MX) localization and i18n tooling (`0e2dd239`, `5b3fe996`)
- react-i18next setup with `en-US` / `es-MX` / `hi-IN` resource bundles and a
  normalizer that maps backend language codes (`es_MX`, `es-mx`) to canonical tags.
- Filtered the at-home activity list by locale: five practice videos had no
  Spanish dub, so `VIDEOS_WITHOUT_SPANISH` removes them from the shuffle for
  Spanish users (memoized on locale, with the shuffle effect re-keyed on it) —
  Spanish parents never get sent to an English-only video.
- Built a dev-only debug console (`window.amiraDebug.i18n.setLanguage/clearOverride/getStatus`)
  backed by localStorage, gated on non-production `NODE_ENV`/`STACK`, so QA could
  force a locale without a backend account change. Documented it in the README.
- Gated the "view progress across the school year" module to Spanish only during
  a staged rollout.

### Activity-practice UX (`34764e70`, `e0cca11f`, `d15e34e8`, `5da5a4b5`, `af8fd03e`)
- Fisher-Yates shuffle over the activity list with a "top 3" limited view, plus a
  new set of hand-authored SVG activity icons.
- Built the AmiraTutor.com cross-sell module (component + SCSS + asset), with the
  tutor URL selected per district via a `districtIdToTutorMap`.

### Reliability / observability cleanups (`23177a48`, `8b5f6099`, `1ef9a74d`)
- Promoted swallowed `console.log`s in catch blocks to `console.error` across
  auth, API, and environment services.
- Removed a Segment `network_timed_out` event fired from the GraphQL abort
  handler (was firing on every 7s AbortController timeout and polluting analytics).
- Defensive fix in `getLastCompletedActivityForStudent`: `activity.story.tags`
  could be null, throwing on `.includes` and blanking the parent's whole report.

## Quantifiable signals (this batch)

- 50 commits, 2023-07-20 → 2026-04-22 (~2.75 years of ownership in this slice).
- Largest single feature diffs: ~900 and ~800 changed lines, both auth/login rewrites.
- Ships to production at `parent.amiralearning.com`; jira-keyed work (ASSMNT-907,
  ASSMNT-1119, AE-14360) indicates tracked product delivery, not side work.
- Tech surface: React (class + hooks), SCSS, AWS Amplify/Cognito, AWS AppSync +
  GraphQL, DynamoDB access patterns, Segment analytics, react-i18next,
  @react-pdf/renderer, qrcode.react, Webpack.

## Notes for the merge step

- `2f9b0b7b` ("New admin") committed a production `amira.env` containing live API
  keys and was reverted the same day by `0a6642b9` ("Undo"). Excluded from
  resume-relevant work; flagged only so the merge step doesn't mistake its large
  diff for a feature.
- Several commits in this range are merge commits of other engineers' branches
  (pete/*) — excluded per the noise rule.
