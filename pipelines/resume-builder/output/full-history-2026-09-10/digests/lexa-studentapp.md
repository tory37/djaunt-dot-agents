# lexa-studentapp

**Repo:** `AmiraLearning/lexa-studentapp` — Amira's student-facing K-5 reading tutor and assessment
client (React/JavaScript SPA, 8.6MB JS, created 2018, private).
**Created:** 2018-09-26 · **Last push:** 2026-09-10 · **PRs by tory37:** 18 (authored PRs; ~300+
numbered PRs referenced across commit history as reviewer/author) · **Commits by tory37:** 384
(2023-06-23 → 2026-09-08, ~3.2 years, nearly all through reviewed PRs #4116-#6009).

## Role and contribution

The headline repo of this work history: sustained, ~3-year ownership of the core product every
Amira student uses — the real-time speech/ASR pipeline, the WebGL-animated tutor avatar, the
assessment orchestration client, and the conversational AI comprehension feature. Nearly every
commit ships through a reviewed, numbered PR with tests and detailed messages citing JIRA tickets
by number and product owners by name. This is not scoped to one layer — the same engineer lands
features that touch React component architecture, Redux state, WebSocket/streaming audio, WebGL
rendering, GraphQL contracts, and i18n together.

## What was actually built

### Assessment Orchestration Service (AOS) integration — architecture migration, built from a thin slice to full authority
Built the client's entire integration with a new server-driven, testlet-at-a-time assessment
engine that replaced the app's own story-selection and re-leveling logic — the dominant technical
arc spanning nearly two years. Started with a "thin slice" adapter that synthesized the app's
existing story/chapter/phrase shape from AOS testlets so the whole legacy Reader pipeline could
run unchanged against server-driven content. Progressively moved authority across the
client-server boundary: story selection, then re-leveling decisions (client used to decide
up-level/down-level itself; reworked to report intent and let the server decide, with a 2-second
timeout fallback so a slow ack can't stall a student's session), then activity creation. Added
bounded retry with backoff around the core `getTestlet` call after finding it hammered the backend
with zero delay on failure, and fixed a retry-limit defect where nested try/catch blocks were
silently multiplying the real call count from an expected 4 to 15.

### AI Comprehension Dialog — a conversational feature owned front to back, twice redesigned
Built a spoken (and later typed) back-and-forth between the tutor avatar and a student about a
story, backed by an LLM inference service — student interaction UI, the ASR/TTS state machine
driving it, a 5-second timeout guard on the inference round-trip so a model call never leaves a
child waiting, the telemetry proving its latency, and the teacher-facing report that surfaces the
transcripts. Shipped behind staged in-file rollout flags. Later refactored a ~1,000-line
class component holding a 25-state hand-rolled state machine into a custom controller hook plus a
thin view — an explicitly reasoned maintainability decision, not incidental cleanup — then
redesigned the UI again (4,400+ lines) with a full supporting component set (reactive
listening-status indicator, typed icon buttons, book overlay, on-screen-keyboard awareness).

### Multi-rig WebGL tutor avatar system + student tutor picker
Rewrote the Spine (spine-webgl) asset-loading layer from hardcoded-to-one-character to rig-driven
with promise-based loading that fixed a real race (atlas being read before it arrived) and
prevented a GPU/texture leak on avatar swap. Built a layered eligibility resolver reconciling
student preference, feature flags, brand restrictions, and district policy, plus the picker UI
itself. Separately diagnosed and fixed a production bug where the avatar rendered the wrong
texture after a browser WebGL context loss — root-caused to a concurrent-load race — and built a
dev harness to reproduce context loss on demand rather than waiting for it in the field.

### White-label/partner branding platform — single-brand app to six-brand configurable platform
Took the app from hardcoded Amira branding to a fully brandable platform serving partner brands
(NWEA MAP Reading Fluency, HMH, Highlights, EPS, others) — a central brand registry, brand-aware
copy parameterization across ~40 hardcoded strings in two locales, and a real solution to a
cross-boundary problem: the app has static non-React pages outside the bundle, solved by mirroring
resolved branding into `localStorage` on login for plain inline JS to read. Extended to full
per-brand configuration — allowed curricula, badging certificate sets per locale and color mode,
and an i18n override-key convention so a partner's tooltip copy could diverge from Amira's without
forking every string.

### Bilingual (Spanish) assessment rollout — entitlement-driven, from pilot to default
Extensive work moving Spanish-language assessment support from a pilot flag to production,
license-driven behavior: built the bilingual assessment chooser (reusing a shared-services API
deliberately, to mirror a sibling app rather than reinvent), fixed routing that ignored district
entitlement entirely, converted feature enablers into fleet-wide kill switches after a product
owner requested an emergency off-switch, and found a case where the enablement predicate could not
express a real production state — a Spanish placement session that had no Spanish placement
manager — and renamed it to answer the question actually being asked.

### Extended-time and non-verbal accommodations (IEP/504 support)
Built a testing-time-multiplier accommodation, deliberately excluding timing-sensitive item types
where extending time would invalidate the measure (ORF, RAN, visual attention). Found and fixed a
gap where components owning their own timers never received the multiplier. Built an alternate
flow for non-verbal students — full-story-before-questions presentation, and shimmed the recorder
object's getters so downstream code kept working without a mic-permission prompt ever appearing.

### Teacher-facing device readiness flow ("Ready Module") rebuild
Replaced a single 164-line troubleshooting modal with a routed 8-view state machine that solves a
genuinely hard problem: the teacher's "test the mic" step has to leave the modal, run the real ASR
pipeline on a live route, and come back — solved via a URL query-param round-trip through the
router, scrubbed via `history.replaceState` so a refresh doesn't replay a stale result.

### Reliability and correctness fixes (recurring, cross-cutting theme)
- A write-clobber bug where two sequential metadata update calls, each carrying a stale snapshot,
  silently reverted each other's changes — permanently blocking content for dual-language students.
- An iPad/Safari audio-capture bug where the mic stream and playback fought each other, degrading
  both TTS and recording — fixed with explicit stream teardown/restart at every playback boundary.
- A CDN-substitution gap where one image component was the only one hitting S3 directly, breaking
  in districts where S3 is firewalled.
- A COOP-header interaction (added for a different feature) that silently stranded students on a
  completion screen with no way to close the tab — CO OP and cross-origin `window.opener` are
  mutually exclusive by spec — fixed with a side-effect-free predicate that detects exactly the
  stuck cases.
- N+1 GraphQL word-metadata calls batched into a single list API, feeding a downstream
  intervention-selection service in the same round trip.
- A struggle-monitor race condition where real-time classification resolved after the system had
  already moved on, producing "sticky" placement state — fixed by prefetching all phrase metadata
  at story start and making evaluation a synchronous state lookup.

## Problems solved

- Rendering interactive content correctly across a client-server architecture migration without a
  user-visible seam, over a two-year incremental authority transfer.
- A deadlock class in the speech pipeline: TTS that silently never returns — solved with a
  computed-timeout safeguard timer that force-advances and logs a diagnostic event.
- Lip-sync drift caused by a hardcoded bitrate assumption in audio-duration estimation — rewrote to
  probe real bitrates with safety bounds, plus a watchdog that extends or compresses animation
  frames to stay in sync, cleaning up a pre-existing interval leak along the way.
- A GraphQL client library (Amplify) that returns HTTP 200 on GraphQL-level errors — multiple
  services across the codebase had to be explicitly hardened to check the `errors` array rather
  than trust a successful HTTP response.

## Design decisions worth naming

- **Entitlement over feature flag, consistently.** Repeatedly moved gates from per-stack flags to
  per-district license checks, keeping flags only as documented fleet-wide kill switches.
- **Side-effect-free mirrors for "will this fail?" checks** rather than trial-and-catch, used
  across at least two unrelated features.
- **Generated over hand-maintained** — replaced a drifting hand-written index-map comment
  convention with a statically-parsed generated manifest, and explicitly weighed the cost of a CI
  guard against the review-attention cost of keeping it.
- **Willing to revert.** Multiple instances of shipping a change and reverting it days later
  rather than defending a decision that turned out wrong in production.
- **Removes his own debug instrumentation** once a bug is closed, rather than leaving scaffolding
  in the codebase.

## Quantifiable signals

| Signal | Value |
|---|---|
| Commits (tory37) | 384 |
| PRs (tory37, authored) | 18 |
| Active span | 2023-06-23 → 2026-09-08 (~3.2 years) |
| Distinct JIRA tickets closed | 60+ across ASSMNT-*, AE-*, CR-*, SC-*, TT-* trackers |
| Largest single commits | 4,414 lines/68 files (comprehension dialog v2); 4,074 lines/41 files (trigger DSL + 2 item types); 2,700+ lines (Spanish assessment config) |
| Brand configurations maintained | 6 (amira, eps, eps-standalone, highlights, hmh, nwea-map-tutor) × 2 locales |

## Recommended resume use

The anchor bullet of the whole resume. Nearly 3.2 years of continuous ownership of the primary
product surface, spanning a major architecture migration (client-authoritative to
server-orchestrated assessment), a shipped conversational-AI feature end to end, a WebGL rendering
system, and a real white-label platform serving named enterprise partners (NWEA, HMH). Strong
XYZ-formula material throughout — pick 2-3 of: the AOS migration (scope + duration), the
comprehension dialog (novel feature, LLM integration), the white-label platform (enterprise partner
count), or the reliability-fix pattern (concrete before/after bug stories) depending on what the
target role weights.
