---
name: djt-bug
description: "Kick off the test-driven bug investigation workflow. Accepts an optional issue file: /djt-bug @path/to/issue.md"
trigger: /djt-bug
---

# /djt-bug

Start the test-driven bug investigation workflow.

## Usage

```
/djt-bug                        # start with no issue file; agent will ask for repro steps
/djt-bug @path/to/issue.md      # start from a written issue or repro-steps file
```

## Steps

Work through the following steps in order. Do not proceed past a gate without user confirmation.

### 1. Explore

Read the relevant code before forming any hypothesis. If an issue file was provided, read it first, then trace the affected code paths.

### 2. Clarify

If repro steps, expected vs. actual behavior, or scope are unclear, ask all questions at once in a single message. Wait for answers before proceeding.

### 3. Reproduce

Write a failing test that captures the bug. The test should:
- Be minimal and targeted
- Fail for exactly the right reason (not coincidentally)
- Follow the project's existing test framework and conventions

**Have the user run the test to confirm it fails as expected before proceeding.**

### 4. Propose Fix & Branch

1. **Write Fix Plan:** Write a fix plan to `.agents/output/bugs/<bug-name>/fix-plan.md`. Include:
   - Root cause explanation.
   - Proposed minimal code change (broken into phases if complex).
   - Any side effects or related risk areas.
2. **Create a Branch:** Create a new git branch: `fix/short-description`.

**Write the plan to disk immediately.** Present a high-level summary and await explicit user approval before writing any fix code.

*If using djt-kanban, sync these phases to the active ticket in `3_doing/` now.*

### 5. [Step Removed]

*(Branching consolidated in Step 4)*

### 6. Iterative Fix

Implement the fix. If the fix was broken into phases, follow the iterative pattern:

1. **Implement:** Apply the minimal production code change for the current phase.
2. **Verify:** Once implemented, **STOP** and prompt the user to run the test suite to confirm:
   - The new test passes.
   - No regressions in related tests.
3. **Commit:** After confirmation, **COMMIT** the changes. Use the phase/fix description for the commit message.
4. **Repeat:** If there are more phases, repeat until the bug is fully resolved.

### 7. Final Verification & PR

**Verification Gate:** Ensure all verification steps have been confirmed by the user.

### 8. PR & Documentation

Commit the fix and open a Pull Request (follow git conventions in AGENTS.md).

- Commit body: explain why the bug occurred and why this fix is correct.
- PR description: bug summary + root cause + fix approach.
- Link the original issue. Request review before merge.
