---
name: djt-feature
description: "Kick off the full engineering workflow for a new feature. Accepts an optional spec file: /djt-feature @path/to/spec.md"
trigger: /djt-feature
---

# /djt-feature

Start the full engineering workflow for a new feature.

## Usage

```
/djt-feature                      # start with no spec; agent will ask for context
/djt-feature @path/to/spec.md     # start from a written spec file
```

## Steps

Work through the following steps in order. Do not skip ahead without user confirmation at each gate.

### 1. Explore

Read the relevant parts of the codebase before writing anything. If a spec file was provided, read it first to understand scope, then explore affected files, related modules, and existing patterns.

### 2. Clarify

If there are unknowns or ambiguities, surface them all at once in a single message. Do not ask one question at a time. Wait for answers before proceeding.

### 3. Plan

Write a step-by-step implementation plan to `.agents/output/features/<feature-name>/plan.html`. Use the standard HTML shell from the **HTML Output Convention** in AGENTS.md (`badge-feature`, depth-2 stylesheet path `../../assets/style.css`).

The plan MUST cover:

- **Break into Phases:** Organize the work into discrete, testable phases. Each phase should deliver a small, verifiable piece of value.
- **Tests First:** Define what needs to be tested for each phase.
- **Implementation steps:** Detail the steps for each phase.
- **Brief rationale:** Explain key decisions.

Structure each phase as a `.phase-card` with a `.phase-number`, `.phase-title`, a `.phase-steps` ordered list, and a `.test-criteria` block for verification criteria.

**Write the plan to disk immediately.** Bootstrap the stylesheet first (`mkdir -p .agents/output/assets && cp ~/.agents/assets/style.css .agents/output/assets/style.css` if not present). Present a high-level summary to the user and await explicit approval of the phased approach before proceeding.

*If using djt-kanban or djt-trello, sync these phases to the active ticket/card now.*

### 4. Test-Driven Development & Branching

1. **Create a Branch:** Create a new git branch before writing any code. Branch naming: `feat/short-description`.
2. **Write Failing Tests:** Write failing tests for the *first phase* only. Adhere to project conventions.
3. **Confirm Failure:** Have the user run the tests to confirm they compile and fail as expected.

Write a Doer Test Plan to `.agents/output/features/<feature-name>/doer-test-plan.html` for the current phase. Use the standard HTML shell (`badge-feature`, depth-2 stylesheet path). Structure steps as a `.test-steps` ordered list where each `<li class="test-step">` contains the action and a `<span class="checkpoint">` for the expected outcome.

### 5. [Step Removed]

*(TDD and Branching are now consolidated in Step 4)*

### 6. Iterative Implementation

Implement the feature one phase at a time. For each phase:

1. **Implement:** Code against the plan for the current phase.
2. **Verify:** Once the phase is implemented, **STOP** and prompt the user to:
   - Run unit/e2e tests and verify they pass.
   - Run the manual steps in the Doer Test Plan.
3. **Commit:** After user confirmation that the phase is correct and tests pass, **COMMIT** the changes. Use the phase description as the basis for the commit message.
4. **Next Phase:** Repeat for the next phase until the entire plan is complete.

### 7. Finalize & PR

Commit the changes and open a Pull Request (follow git conventions in AGENTS.md).

- Commit body: explain what the feature does and why it was built this way.
- PR description: feature explanation + brief implementation overview.
- Link related issues. Request review before merge.
