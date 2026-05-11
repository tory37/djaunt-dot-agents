---
name: {{PREFIX}}-backlog
description: "Fetch the next item from the Trello BACKLOG and run the full engineering workflow. Accepts an optional spec file: /{{PREFIX}}-backlog @path/to/spec.md"
trigger: /{{PREFIX}}-backlog
---

# /{{PREFIX}}-backlog

Fetch the next feature from the Trello BACKLOG and start the full engineering workflow.

## Usage

```
/{{PREFIX}}-backlog                      # picks the top BACKLOG card automatically
/{{PREFIX}}-backlog @path/to/spec.md     # start from a written spec file instead
/{{PREFIX}}-backlog add                  # add a new card to the BACKLOG
```

---

## Phase 0: Fetch from Backlog

Before starting, retrieve the next item from Trello:

1. Fetch cards from the BACKLOG list (`{{TRELLO_LIST_BACKLOG}}`).
2. **Ignore** any card named "Feature Template".
3. Pick the first card (top = highest priority), unless a name or spec file was specified.
4. Move the card to **DOING** (`{{TRELLO_LIST_DOING}}`) and assign yourself.
5. Present the card name, description, and URL to the user before continuing.

If a `@spec.md` was provided instead, skip the Trello fetch and use the spec as the source of truth.

---

## Phase 1: Engineering Workflow

Work through the following steps in order. Do not skip ahead without user confirmation at each gate.

### 1. Explore

Read the relevant parts of the codebase before writing anything. If a spec file was provided, read it first to understand scope, then explore affected files, related modules, and existing patterns.

### 2. Clarify

If there are unknowns or ambiguities, surface them all at once in a single message. Do not ask one question at a time. Wait for answers before proceeding.

### 3. Plan

Write a step-by-step implementation plan to `.agents/<feature-name>-plan.md`. The plan must include:
- Tests first (what needs to be tested and how)
- Implementation steps second
- Brief rationale for key decisions
- Optional improvements only if weak points directly related to the change are found
- Suggestions to break into smaller sessions if the scope is large

**Present the plan to the user and await explicit approval before proceeding.**

### 4. Test-Driven Development

Write failing tests before any implementation code.

- If the project has an existing test framework, adhere to it.
- If no test framework exists, examine the codebase and language, then suggest the best options for both unit AND integration tests. Await user confirmation before setting anything up.
- Goal: programmatic confidence the change works as intended — unit tests for logic, integration tests for behavior.
- Have the user run the tests to confirm they compile and fail as expected. Do not run them yourself.
- Write a Doer Test Plan to `.agents/<feature-name>-doer-test-plan.md` (see definition in AGENTS.md).

### 5. Create a Branch

Create a new git branch before writing any implementation code.

Branch naming: `type/short-description` (e.g. `feat/oauth-login`)

### 6. Implement

Code against the approved plan **as it exists on disk** — do not implement from memory.

- Follow the project's style and linting rules.
- Update the Doer Test Plan if steps or details change during implementation.
- **Verification Gate:** Once finished, **STOP** and prompt the user to:
    1. Run the unit tests and verify they pass.
    2. Run e2e tests (if they exist) and verify they pass.
    3. Run the manual steps in the Doer Test Plan.
    4. Report back any issues or confirm all tests pass.
- Await user confirmation of completeness before moving to Step 7. Do not move to Step 7 until all verification steps have been confirmed by the user.

### 7. Commit & PR

Commit the changes and open a Pull Request.

- Commit message: imperative mood, under 72 characters, body explains *why* not *what*.
- PR description: feature explanation + brief implementation overview.
- Link related issues. Request review before merge.

---

## Adding a New Backlog Card

When invoked with `add [@path/to/spec.md]`:

- If a filled spec file is provided via `@path`, read it and use its fields to populate the card.
- If no file is provided, prompt the user for each field in the order it appears in the template below.

Template schema:

{{FEATURE_TEMPLATE}}

**Mapping to Trello:**
- **Card name** ← Feature Name
- **Description** ← Goal + User Story + Scope (In/Out) + Constraints & Non-Goals + Related Tickets/Links
- **Checklist "Acceptance Criteria"** ← each checkbox item as a checklist item
- **Checklist "Test Plan"** ← empty (filled during implementation)

After creating the card, present the URL to the user.

---

## Trello Config
- Board ID: `{{TRELLO_BOARD_ID}}`
- BACKLOG list ID: `{{TRELLO_LIST_BACKLOG}}`
- DOING list ID: `{{TRELLO_LIST_DOING}}`
- MCP server: `trello` (defined in `.agents/mcp/trello.json`)
---
