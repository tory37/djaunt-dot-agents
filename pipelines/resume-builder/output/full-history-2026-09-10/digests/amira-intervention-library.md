# amira-intervention-library (AmiraLearning)

Private repo. "Front end intervention component library" — the React component
library behind Amira's K-6 reading-tutor interventions, assessments, and tutor
activities. Consumed directly as source by `lexa-studentapp`; developed against
Storybook plus a webpack dev-server that syncs source into a local student-app
checkout. Storybook staging site published via an AWS Amplify pipeline off
`develop`.

## Scale signals

- **30 commits** authored by `tory37`, **26 merged PRs** (1 closed unmerged),
  spanning **2023-10 to 2025-09** (~2 years of continuous contribution).
- Repo created 2021-05; still active 2026-08. Tory is one of several
  contributors (others: danny-gott, fthbby/Nat).
- 1 star, 0 forks — internal product repo, stars/forks not meaningful.
- Library holds **28 intervention component families** (ElkoninBox, UpAndDown,
  HFWDotGrid, WordScramble, GSF, LetterFlies, Name, Cognate, SoundOut,
  SyllableSegmentation, VocabularyWithPicture, etc.). Tory touched ~15 of them.

## Tech stack

JavaScript (802 KB) / SCSS (94 KB). React 16 + hooks, Redux / react-redux,
webpack 4, Babel, Storybook 6, node-sass, `react-beautiful-dnd` (drag-and-drop
interventions), `react-unity-webgl` (embedded Unity WebGL builds pulled from S3),
`react-sound`, Bootstrap/SCSS, Sentry for error reporting, AWS S3 + Amplify.
Domain layer: speech synthesis (TTS with locale switching), ASR listening,
IPA→Amirabet phoneme mapping, grapheme/phoneme alignment.

## Role and contribution

Feature and bug-fix engineer on the intervention library — owned the
grade-banded copy system end to end, and repeatedly fixed hard interaction bugs
in speech-driven, timing-sensitive components (ASR listening, autoplay timers,
touch/drag on iPad).

## Notable technical work

### Grade-banded copy theming system (PR #198, largest change: 18 files, ~4,600 lines)

Built `src/functions/themingService.js` from scratch (122 lines) — a grade-band
resolution layer that maps a student's `actualGrade` into four bands
(`PRE` ≤ K, `LOW` 1-2, `MEDIUM` 3-5, `HIGH` 6+) and picks age-appropriate tutor
copy per band. Exposed two APIs: `getContentByGradeBand({pre, low, medium, high,
default})` for arbitrary content and `getCopyByGradeband(object, defaultKey)`
for the copy schema, which resolves by suffix convention
(`<key>_MID_GRADE_BAND`, `<key>_HIGH_GRADE_BAND`) with graceful fallthrough —
`HIGH` falls back to `MID`, `MID` falls back to the base (`LOW`) key. This let
thousands of existing copy strings stay untouched while band-specific overrides
were added incrementally, instead of forking the whole copy table.

Threaded the resolver through 15 intervention components and the shared
`Listen.js` patter service, and expanded `translatedCopy.js` by ~3,900 lines of
band-specific strings. Follow-up PR #199 corrected the import paths after the
service moved into `src/functions`.

### Simulated-listening rework for Elkonin box interventions (PRs #150/#151)

Replaced real per-phoneme ASR (`listenPhoneme` looped over graphemes) with a
"fake listen" model across ElkoninBox versions 0-4: components now call
`startFakeListen()` / `stopFakeListen()` around the click-driven interaction and
drive stage transitions from taps instead of blocking on speech recognition.
Removed the per-grapheme await loops, which had made the activity stall when ASR
misfired. Also fixed a class of autoplay bugs in the same components — first
Elkonin ball auto-advancing before Amira finished the instructions (PR #139),
duplicate autoclick timeouts being scheduled (PR #143), and Elkonin 99 being
selectable as an intervention when it shouldn't be (PR #152).

### iPad / touch interaction support

- **HFWDotGrid tap-to-place (PR #200):** `react-beautiful-dnd` drag doesn't work
  reliably on iPad, so added a select-then-drop tap model — a `selectedDot`
  state with select / deselect / reselect / remove transitions, an `onClick`
  drop target on the grid, a `.selected` visual treatment, and iPad-specific
  copy variants (`ftue_your_turn_iPad`, `non_ftue_intro_iPad`,
  `timeout_response_iPad`) so spoken instructions match the actual gesture.
- **Responsive Box sizing (PR #210):** intervention boxes were hard-coded at
  160px and overflowed on narrow viewports. Added viewport-derived container
  width (resize-listener + cleanup) and per-grapheme box sizing
  (`min(160, containerWidth / graphemeCount)`), applied consistently across
  demo, static, and draggable render paths in WordScramble, with font-size
  stepping for longer words.
- **Touch crash guard (PR #211):** `document.elementFromPoint` in `Name`'s
  `onTouchMove` could return an element whose `className` is an `SVGAnimatedString`
  (no `.includes`), throwing mid-drag; added a defensive type check.

### Assessment variants and data-integrity failsafes

- **UpAndDown image-based assessment (PR #195):** added a `useWordImage` variant
  that renders a target image instead of the climbing visualization, including
  demo-vs-live image resolution by stage and URL rewriting from legacy
  `s3.amazonaws.com/amira-assets` paths to the configured `ASSET_ROOT`.
- **Malformed-content failsafe (PR #159):** when a word's `GRAPHEMIC_BREAKDOWN`
  and `PHON` had mismatched lengths the `Name` intervention crashed; added a
  pre-flight length check that logs to Sentry with the offending word and closes
  the intervention gracefully instead of taking down the activity.
- **Optional-asset relaxation (PRs #157, #160):** removed hard requirements for
  phoneme video/image URLs in Name 2 and Elkonin 2/3/4, widening the pool of
  usable content words.

### Bilingual / Spanish support

- **Cognate intro (PR #205):** split the cognate introduction into four segments
  so the English word is spoken with `skipTranslation`, the Spanish cognate is
  spoken with an explicit `es-mx` locale, and the surrounding patter still
  translates — fixing wrong-language pronunciation in `tutorInSpanish` mode.
- **UpAndDown translated instructions (PR #202):** made the image variant's ask
  instructions go through the translation path.

### Speech-timing tuning

- **Minimum listen window (PR #204):** added `minTimeout` (default 2000 ms) and
  `maxTimeout` params to `useConversation.listenWord`, so sound-out interventions
  stop cutting students off before they finish responding.
- **Tutor mic state (PR #207):** Elkonin 99 left the mic visual active after the
  word was detected; added the missing `stopListening()` before closing.
- **UpAndDown end-of-page patter (PR #148/#149):** suppressed "let's read some
  more" on the final page.

## Design decisions worth noting

- Grade-band copy uses **suffix-convention lookup with fallthrough** rather than
  a nested per-band copy tree — keeps the existing flat copy table valid and
  makes band overrides purely additive.
- iPad support is handled by **swapping the interaction model and the spoken
  instructions together**, not by patching drag-and-drop — the tutor's narration
  has to describe the gesture the student can actually perform.
- Bad content data **fails soft and reports** (Sentry + close intervention)
  rather than crashing the student's session.
