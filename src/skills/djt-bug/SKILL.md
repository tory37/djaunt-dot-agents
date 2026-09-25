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

This workflow has two hard approval gates: **Step 3 (before investigating)** and **Step 5 (before fixing)**. Never skip either, even for a bug that looks obvious.

### 1. Orient

Read the issue file if one was provided. Take a light pass over the obviously relevant code — enough to state the problem accurately and name candidate theories. Do not start a deep investigation yet.

### 2. Clarify

If repro steps, expected vs. actual behavior, or scope are unclear, ask all questions at once in a single message. Wait for answers before proceeding.

### 3. GATE — Problem Statement & Approach

**Before any investigation work, report back in chat.** Keep it short — this is a check on understanding, not a document. Cover, in this order:

1. **The problem as you understand it.** Restate it in your own words: what happens, what should happen, where, and for whom. Never assume the user's framing is correct — say so if the code suggests something different.
2. **Theories, if any.** Ranked. Each with the certainty level and the evidence behind it (see **Solution Validation & Root Cause Analysis** in AGENTS.md). Say "no theory yet" when that's the truth — a guessed theory is worse than none.
3. **How you would start investigating.** The first few concrete moves: which files, which logs, which repro, which test.

**STOP. Wait for the user's approval.** If the user corrects the understanding, restate it and wait again. Do not investigate on an unapproved problem statement.

### 4. Investigate & Reproduce

Trace the affected code paths. Gather the evidence that confirms or kills each theory.

Then write a failing test that captures the bug. The test should:
- Be minimal and targeted
- Fail for exactly the right reason (not coincidentally)
- Follow the project's existing test framework and conventions

Run the test yourself and confirm it fails for the right reason. Report the actual output.

### 5. GATE — Diagnosis & Proposed Solution

**Before writing any fix code, report back in chat.** Cover, in this order:

1. **The issue, restated.** One or two sentences — the same problem from Step 3, corrected if the investigation changed it.
2. **Whether that framing held up.** Say plainly if the real bug turned out to be different from what was first reported.
3. **The diagnosis.** Root cause with a stated certainty level and the evidence behind it. Use the Confirmed / High Probability / Possible ladder from AGENTS.md — do not label a cause "confirmed" without a repro, an isolating test, or a pinpointing trace.
4. **The proposed solution.** The minimal change, named by file and function.
5. **Exactly how the solution fixes the issue.** Walk the causal chain: the bad behavior happens because X; the change makes X impossible/correct; therefore the behavior is right. If that chain has a gap, the diagnosis is not done — go back to Step 4.
6. **Side effects and risk.** What else touches this code path.

**STOP. Wait for the user's approval before moving to the fix.**

### 6. Fix Plan & Branch

Once the user approves the diagnosis:

1. **Write Fix Plan:** Write a fix plan to `.agents/output/bugs/<bug-name>/fix-plan.html`. Use the standard HTML shell from the **HTML Output Convention** in AGENTS.md (`badge-bug`, depth-2 stylesheet path `../../assets/style.css`). Bootstrap the stylesheet first if not present. Include:
   - Root cause as a `.finding-card.critical` block.
   - Proposed minimal code change as `.phase-card` blocks (one per phase if complex).
   - Side effects or related risk areas as a `.callout.warning`.
2. **Create a Branch:** Create a new git branch: `fix/short-description`.

If the bug is visual/UI (broken layout, styling regression, a component that needs redesigning as part of the fix), invoke **`/djt-frontend-design`** before writing the fix — the single entry point for interface design and anti-slop review.

**Write the plan to disk immediately.** Point the user to the file; do not print it into chat.

*If using djt-kanban or djt-trello, sync these phases to the active ticket/card now.*

### 7. Iterative Fix

Implement the fix. If the fix was broken into phases, follow the iterative pattern:

1. **Implement:** Apply the minimal production code change for the current phase.
2. **Verify:** Run the test suite yourself and report the actual results:
   - The new test passes.
   - No regressions in related tests.
3. **Commit:** After the user confirms the fix is working, **COMMIT** the changes. Use the phase/fix description for the commit message.
4. **Repeat:** If there are more phases, repeat until the bug is fully resolved.

### 8. Final Verification & PR

**Verification Gate:** Ensure all verification steps have been confirmed by the user.

Commit the fix and open a Pull Request (follow git conventions in AGENTS.md).

- Commit body: explain why the bug occurred and why this fix is correct.
- PR description: bug summary + root cause + fix approach.
- Link the original issue. Request review before merge.
