# amira-story-editor (AmiraLearning)

Internal authoring/import tool for the reading-story content that drives Amira's
student reading experience. Content-team-facing web app: search stories by id /
version / title, preview, edit, bulk upload, batch tagging, publish.

## Scale signals

- Repo created 2018-12-11, still active (last push 2026-09-02) — ~8-year lifespan.
- Tory's commits: 15 (2024-05-23 → 2024-06-21), all in one focused month.
- PRs authored: 5 — 4 merged (#199, #201, #202, #203), 1 unmerged (#193).
- Private internal tool; stars/forks 0 (not a meaningful signal).
- Languages: JavaScript (1.3M), Jupyter Notebook (746K), SCSS, Python, Shell, Makefile.

## Stack

React 16 + Redux + redux-saga, react-bootstrap, react-accessible-accordion,
react-sortable-hoc. AWS AppSync (GraphQL) over DynamoDB, Cognito user pools,
aws-amplify / aws-appsync clients, CloudFormation for the AppSync schema,
S3 static hosting deploys.

## Role and contribution

Sole implementer of the **Comprehension V2 (CompV2) question** authoring feature —
end-to-end: GraphQL schema change, multi-backend API layer, Redux saga wiring, and
the React authoring UI. Then owned the fix cycle for it over the following month.

## Specific technical work

**1. New content type across schema, API, and UI (PRs #199, commits `7382db4b`, `43c4b045`)**
- Extended the AppSync/CloudFormation schema (`storydb_api_schema.graphql`) with a
  new `interaction` type and `StoryItemInteractionsInput`, hung off story items —
  fields for `prompt`, `response`, `noResponsePrompt`, `standardSet`, `textInput`,
  `ids`.
- Built the `ComprehensionV2Question` React component (~150 lines) — accordion-based
  editor for prompt, fallback response, no-response prompt, standards-set mapping,
  free-text-input toggle.
- Added a chapter-level "V2" question-type indicator badge alongside existing M/P
  (multiple-select / prediction) markers, and made adding a CompV2 question coerce
  the item's `type` to `interactive`.

**2. Cross-database write splitting (the hard part)**
- CompV2 question data is split across two systems: the story record lives in the
  Story DB, while the *question metadata* (prompt text, responses) must be written to
  the Student Record Store (SRS) via a separate `setQuestionMetadata` mutation.
- Stood up a second AppSync client (`clientSrsDB`) in `src/api/dynamodb.js` and wrote
  the fan-out save path: walk chapters → items → interactions, strip metadata fields
  out of the story payload, push each interaction to SRS, then write the trimmed
  story to Story DB.
- Handled partial-failure semantics: per-interaction retry wrapper (3 attempts),
  `Promise.allSettled` so one bad interaction doesn't abort the whole save, and a
  `failures` array carried back to the caller with `(chapterIndex, itemIndex,
  interactionIndex)` coordinates so the UI can report exactly which questions
  didn't persist.
- Fixed a mutation-aliasing bug by deep-cloning (`JSON.parse(JSON.stringify(...))`)
  instead of shallow-spreading before deleting fields — the shallow copy was
  mutating the caller's story object (`6ee00625`).

**3. Post-ship defect fixes (PRs #201, #202, #203)**
- `69c28af9` — delete for CompV2 items was wired to `onUpdate` instead of a real
  delete; added `deleteComprehensionV2Question`, and reset the item's `type` to null
  when the last interaction is removed so the item doesn't stay stuck as
  `interactive`.
- `ea76f3d7` — story-save failures were silent; added an explicit error alert
  surfacing the payload for a developer. Also removed a duplicate `id` field that
  broke the audit-save path (`ids[0]` is the canonical id).
- `3342a11d` — the publish-time cleanup pass (`cleanIntros`) treated any item with
  no text/image/instructions as empty and dropped it; since CompV2 data lives in
  `item.interactions`, every interaction-only item was being deleted on publish.
  One-line fix: add `interactions` to the emptiness check.

## Notable design decisions

- Split-store write with best-effort semantics rather than an all-or-nothing
  transaction — AppSync gives no cross-source transaction, so the design favors
  partial success plus precise failure reporting to the author.
- Metadata is stripped from the story payload before the Story DB write, keeping SRS
  as the single source of truth for question text (no drift between the two stores).
- Also opened PR #193 (not merged) proposing a schema change to support per-word
  metadata overrides for homonyms.

## Commit-message caveat

Messages are sparse ("cleanup", "finish?", "more work", "some updates") — this digest
is built from the diffs, not the messages.
