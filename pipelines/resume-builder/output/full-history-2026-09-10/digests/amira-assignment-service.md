# amira-assignment-service (AmiraLearning)

Private production service. Serverless AWS SAM app (Python Lambdas + Node.js/GraphQL
Lambdas) that owns assignment creation, screening-window instancing, and the student
inbox for a K-12 literacy assessment platform.

## Scale signals
- Repo created 2022-05; active through 2026-09. User's contributions: 2026-05 to 2026-07.
- 6 commits authored, all 6 merged as PRs (#435, #441, #465, #467, #470, #474). 100% merge rate.
- Languages: Python 2.4 MB, JavaScript 631 KB, Shell, Makefile.
- Stars 1, forks 0 (internal repo — not a meaningful signal).

## Role / contribution
Backend engineer on a shared production service owned by a wider team. Every
contribution is a production-defect fix in the bilingual (English/Spanish "Evaluar")
assessment assignment pipeline, each tied to a JIRA ticket and driven from a real
customer-reported symptom (empty student inbox, missing students in a teacher UI,
wrong assessment track assigned). Work is diagnosis-heavy: each PR body states a
root cause traced through the code path, names the exact production record or
district/student that reproduced it, and scopes the fix to the one gate that was wrong.

## Specific technical work
- **Evaluar/Assess track eligibility (JS, `getAssignment.js`)** — Discovered
  `subscriptions.evaluar` was being used as a per-student bilingual flag when it is
  actually a school/district product entitlement, so every student in a subscribed
  grade got a Spanish assignment instance materialized from a district-level shell.
  Gated shell expansion on the existing per-student `isESL` signal plus the resolved
  language config, and stripped the unmaterialized shell from the returned list so
  the record is never created (PR #465).
- **Symmetric-gate refactor** — A follow-up QA pass found the mirror-image bug:
  Spanish-only students still got an English track under the BTS rollout. Rather than
  add a second independent check, collapsed `isStudentBilingualEligible` into
  `resolveAssessmentTrackEligibility`, which computes
  `assessmentLanguageOverride ?? spanishConfig` once and derives both
  `evaluarEligible` and `assessEligible` from it — explicitly so the two gates cannot
  drift apart again. Scoped the new filter to the BTS flag and to `ASSESSMENT_TYPES`
  only, so legacy single-track schools and curriculum/microlesson assignments are not
  swept up (PR #467).
- **Screening-window date corruption (Python, `helpers.py`)** — Traced an entire
  district's empty inbox to `resolve_oda_end_dates_for_assignments` truncating a
  district EOY benchmark's `dateTo` from 2026-05-22 to 2026-04-30, pushing it into the
  past so it was dropped by a downstream range filter. Identified `entityType in
  (DISTRICT, SCHOOL)` as the correct discriminator after showing the existing
  `parentId` guard already covers instanced student assignments. Confirmed against the
  live production record before shipping (PR #441).
- **Locale resolution for on-demand assignment (Python, `migration.py`)** — Changed
  `_session_locale` to take the full license plus a `use_evaluar` flag so an
  `ENGLISH_ONLY` school with an Evaluar subscription can be assigned Spanish content
  on demand, while screening-window instancing (which never sets `use_evaluar`) is
  provably unaffected. Chose to ship this unconditionally rather than behind a feature
  flag, on the stated reasoning that a wrong correctness check is a bug, not a feature
  to toggle. Also converted `_assert_evaluar_provisioned` from raise-only to a
  tri-state return so the one config that legitimately has no Spanish data can drop
  the locale silently instead of hard-failing (PR #470).
- **Legacy-school regression (Python, `migration.py`)** — Caught that the tier-1
  subscription gate emptied the manifest for legacy non-BTS Spanish-only schools,
  because Spanish was their only yielded locale, so "restrict" became "delete
  everything." Added a narrow exemption preserving the restrict-only contract for
  bilingual configs where English remains a real fallback (PR #474).
- **Calendar flag rollout (`template.yaml`)** — Two-line config change enabling
  `USE_ASSESSMENT_CALENDAR` in production, but the PR body did the real work:
  documented that the fix does not repair already-stored bad `dateTo` values, called
  out which district behavior settings self-heal at read time, and raised an explicit
  cross-team question to Reporting about the downstream `schoolYearEndDate` blast
  radius (PR #435).

## Notable design decisions
- Preferred deriving related booleans from one resolved value over adding parallel
  checks, specifically to eliminate a class of drift bug that had already bitten twice.
- Consistently reused existing upstream signals (`isESL`, `parentId`, `entityType`)
  instead of adding new data fetches to a hot inbox path.
- Reasoned explicitly about which filter is narrow vs. broad (`isEvaluarAssignment`
  matches only assessment shells; its negation does not) and scoped filters to avoid
  dropping unrelated assignment types.
- Documented blast radius and cross-team impact in PR descriptions rather than
  shipping silently.

## Testing
Test code consistently outweighs production code in these PRs: 273 test lines vs. 31
production lines (#467), 155 vs. 26 (#465), 155 vs. 8 (#441), 84 vs. 45 (#470).
Approach is combinatorial — a full pre/post-rollout x bilingual-flag x language-config
matrix, plus named repro cases mirroring the QA district's exact student roster.

## Tech
Python, JavaScript (ES modules), AWS Lambda, AWS SAM (`template.yaml`), GraphQL,
DynamoDB-backed assignment records, Jest, pytest, webpack, feature-flag-gated rollout.
