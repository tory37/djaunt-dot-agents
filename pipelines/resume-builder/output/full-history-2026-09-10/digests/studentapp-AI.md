# studentapp-AI (AmiraLearning)

**Repo purpose:** npm-packaged decision engine that chooses whether, how, and when Amira's AI reading tutor interrupts a K-5 student mid-reading. Two workspaces: `heuristic-policy` (rule-based "passes" that select the intervention) and `studentapp-agent` (applies a policy to incoming app state). Published to GitHub Packages as `@amiralearning/heuristic-policy` and `@amiralearning/studentapp-ai`.

**Languages:** JavaScript (~1.38 MB), CSS, HTML, Makefile.

## Scale signals
- 6 commits authored by tory37 (`Tory Hebert` / `Tory`), 2023-11-21 to 2024-03-26.
- 5 PRs authored, all merged (#144, #145, #155, #156, #158).
- Repo created 2019-09; still active (pushed 2026-08). 0 stars/forks (private org repo).
- Contribution is small and surgical — targeted rule tuning, not feature ownership.

## Role / contribution
Focused contributor tuning intervention-selection rules in a shared decision engine. All work sits in the policy layer that decides which literacy intervention (Elkonin boxes, sound-out, morpheme, riddle, name-fact) a student is eligible for, and when the tutor is allowed to interrupt.

## Specific technical work (verified by diff, not commit message)
1. **End-of-story interventions enabled** (`heuristic-policy/intervene_selector/index.js`, PR #144). Previously `END_OF_STORY` was a dead branch that nulled out `state.word`/`state.wordIndex` — the tutor never intervened when a student finished a passage. Collapsed it into the `PHRASE` case so end-of-story runs the same phrase-level word selection (`getPhraseLevelSelection` + `createSelectedWordFields`), recovering a whole class of missed teaching moments. Net -4 lines by deleting a special case rather than adding one.
2. **Relaxed content-asset gating on interventions** (`heuristic-policy/constants.js`, PRs #155/#156/#158, ticket AE-13928). The `interventionRequiredFields` map gates each intervention on the word-level content fields present in the item bank; a missing field silently disqualifies the intervention. Removed over-strict requirements in three passes: dropped `word_PHONEME_VIDEO_URL` from `name2`, then `word_FUNFACTS_IMG_URL` from `name2`, then `word_IMG_URL` from `elkoninBox2/3/4`. Each removal widens the eligible-word pool for that intervention type where the asset was not actually rendered.
3. **Cross-package version coordination** (PR #145 and each of the above). Every content change also bumped `heuristic-policy`'s version and `studentapp-agent`'s dependency pin, since the agent consumes the policy as a scoped GitHub Packages dependency. Signals familiarity with a two-package npm workspace and its publish/consume flow (the `make publish` targets).

## Notable characteristics
- Iterative, evidence-driven tuning: `name2` was fixed twice within four days (#155 then #156) as further unused-asset requirements surfaced, then the same pattern was applied to Elkonin boxes a week later (#158) — recognizing a class of bug from a single instance.
- Preference for deleting special cases over branching (the END_OF_STORY change).
- Small diffs with real behavioral reach: a one-line constants edit changes which students see which intervention across the whole product.

## Domain
Ed-tech / K-5 literacy. Adaptive tutoring, phonics and phonemic-awareness intervention design, content-asset dependency modeling.
