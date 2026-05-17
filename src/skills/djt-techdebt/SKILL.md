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

### 3. Plan

Write a step-by-step refactoring plan to `.agents/output/techdebt/<name>/plan.md`. The plan must include:

- Regression tests first (how to ensure existing behavior is preserved)
- Implementation steps second
- Rationale for the refactoring approach
- Potential risks and mitigation strategies

**Present the plan to the user and await explicit approval before proceeding.**

### 4. Test-Driven Refactoring

Ensure existing tests pass and add new tests if needed to cover the changes.

- Goal: ensure functional parity and verify the improvement.
- Have the user run the tests to confirm they pass before refactoring begins.
- Write a Doer Test Plan to `.agents/output/techdebt/<name>/doer-test-plan.md` (see definition in AGENTS.md).

### 5. Create a Branch

Create a new git branch before writing any refactoring code.

Branch naming: `refactor/short-description` or `fix/tech-debt-description`

### 6. Implement

Code against the approved plan as it exists on disk.

- Follow the project's style and linting rules.
- Update the Doer Test Plan if steps or details change.
- **Verification Gate:** Once finished, **STOP** and prompt the user to:
  1. Run the tests and verify they pass (zero regressions).
  2. Run the manual steps in the Doer Test Plan.
  3. Report back any issues or confirm all tests pass.
- Await user confirmation of completeness before moving to Step 7.

### 7. Commit & PR

Commit the changes and open a Pull Request (follow git conventions in AGENTS.md).

- Commit body: explain why the refactoring was necessary and how it improves the codebase.
- PR description: technical debt summary + refactoring approach + impact.
- Link related issues. Request review before merge.
