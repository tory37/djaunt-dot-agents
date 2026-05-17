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

### 4. Propose Fix

Write a fix plan to `.agents/output/bugs/<bug-name>/fix-plan.md`. Include:
- Root cause explanation
- Proposed minimal code change
- Any side effects or related risk areas

**Present the plan and await explicit user approval before writing any fix code.**

### 5. Create a Branch

Create a new git branch before writing any fix code.

Branch naming: `fix/short-description` (e.g. `fix/token-refresh-crash`)

### 6. Fix

Implement the minimal production code change that makes the failing test pass. Do not refactor or expand scope beyond the bug.

### 7. Verify

**Verification Gate:** Once the fix is implemented, **STOP** and prompt the user to run the test suite to confirm:
- The new test passes.
- No regressions in related tests.
- (If applicable) Manual verification steps pass.

Await user confirmation and report back any issues before moving to Step 8. Do not move to Step 8 until all verification steps have been confirmed by the user.

### 8. Commit & PR

Commit the fix and open a Pull Request (follow git conventions in AGENTS.md).

- Commit body: explain why the bug occurred and why this fix is correct.
- PR description: bug summary + root cause + fix approach.
- Link the original issue. Request review before merge.
