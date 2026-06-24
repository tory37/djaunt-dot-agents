---
name: djt-techdebt
description: "Kick off the engineering workflow for addressing technical debt or refactoring. Accepts an optional spec file: /djt-techdebt @path/to/spec.md"
trigger: /djt-techdebt
---

# /djt-techdebt

Start the engineering workflow for addressing technical debt or refactoring.

## Usage

```
/djt-techdebt                      # start with no spec; agent will ask for context
/djt-techdebt @path/to/spec.md     # start from a written spec/issue file
```

## Steps

Work through the following steps in order. Do not skip ahead without user confirmation at each gate.

### 1. Explore

Read the relevant parts of the codebase before writing anything. Identify the debt, its impact, and the target state. If a spec file was provided, read it first.

### 2. Clarify

Surface all unknowns or ambiguities regarding the current implementation and the desired refactoring in a single message. Wait for answers before proceeding.

### 3. Plan & Branch

1. **Write Refactoring Plan:** Write a step-by-step refactoring plan to `.agents/output/techdebt/<name>/plan.html`. Use the standard HTML shell from the **HTML Output Convention** in AGENTS.md (`badge-techdebt`, depth-2 stylesheet path `../../assets/style.css`). Bootstrap the stylesheet first if not present. The plan MUST:
   - **Break into Phases:** Organize the refactor into discrete, verifiable phases — each as a `.phase-card`.
   - **Regression tests:** Define how to ensure functional parity at each step — as a `.test-criteria` block inside each phase card.
   - **Rationale:** Explain the approach and risks as a `.callout.info` block at the top.
2. **Create a Branch:** Create a new git branch: `refactor/short-description`.

**Write the plan to disk immediately.** Present a high-level summary and await explicit approval before proceeding.

*If using djt-kanban or djt-trello, sync these phases to the active ticket/card now.*

### 4. Test-Driven Refactoring

Ensure existing tests pass and add new tests if needed to cover the changes.
- Have the user run the tests to confirm they pass before refactoring begins.
- Produce the Doer Test Plan for the current phase by invoking **`/djt-test-plan`** (the single entry point for manual test cases). It scopes the plan to the phase's change and writes to `.agents/output/techdebt/<name>/doer-test-plan.html`.

### 5. [Step Removed]

*(Branching consolidated in Step 3)*

### 6. Iterative Implementation

Perform the refactor phase by phase:

1. **Implement:** Code against the plan for the current phase.
2. **Verify:** Once the phase is done, **STOP** and prompt the user to:
   - Run tests and verify zero regressions.
   - Run manual steps in the Doer Test Plan.
3. **Commit:** After confirmation, **COMMIT** the changes. Use the phase description for the commit message.
4. **Next Phase:** Repeat until the refactor is complete.

### 7. Finalize & PR

Commit the changes and open a Pull Request (follow git conventions in AGENTS.md).

- Commit body: explain why the refactoring was necessary and how it improves the codebase.
- PR description: technical debt summary + refactoring approach + impact.
- Link related issues. Request review before merge.
