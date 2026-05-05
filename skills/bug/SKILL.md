---
name: bug
description: "Kick off the test-driven bug investigation workflow. Accepts an optional issue file: /bug @path/to/issue.md"
trigger: /bug
gemini_trigger: "When the user types /bug, reports a bug, or asks to investigate a failing test, always execute the following workflow exactly, step by step:"
gemini_notes: "File argument: instead of the @path/to/issue.md syntax, the user will provide a file path as plain text — read the file yourself before proceeding."
---

# /bug

Start the test-driven bug investigation workflow.

## Usage

```
/bug                        # start with no issue file; agent will ask for repro steps
/bug @path/to/issue.md      # start from a written issue or repro-steps file
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

Write a fix plan to `.agents/<bug-name>-fix-plan.md`. Include:
- Root cause explanation
- Proposed minimal code change
- Any side effects or related risk areas

**Present the plan and await explicit user approval before writing any fix code.**

### 5. Fix

Implement the minimal production code change that makes the failing test pass. Do not refactor or expand scope beyond the bug.

### 6. Verify

Have the user run the test suite to confirm:
- The new test passes
- No regressions in related tests

### 7. Commit & PR

Commit the fix and open a Pull Request.

- Commit message: imperative mood, under 72 characters, body explains *why* the bug occurred and *why* this fix is correct.
- PR description: bug summary + root cause + fix approach.
- Link the original issue. Request review before merge.
