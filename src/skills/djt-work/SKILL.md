---
name: djt-work
description: "Kick off the engineering workflow for a feature, bug, or refactor. /djt-work [feature|bug|refactor] [@path/to/spec.md]"
trigger: /djt-work
---

# /djt-work

One workflow for features, bugs, and refactors. Phases, tests, user gate, commit.

## Usage

```
/djt-work                           # agent asks what the work is
/djt-work bug @path/to/issue.md     # type + context file
/djt-work @path/to/spec.md          # agent infers the type
```

## Setup

- State a tool-call budget per phase before starting it. Max 2 subagents at once. See **Budgets** in AGENTS.md.
- Before writing code, read `~/.agents/assets/code-clarity.md`.
- Harness: `~/.agents/skills/djt-harness/`. Read `citations.md` before the plan. Load a stack file only at the step that names it.
- Bug: before the problem statement, read `~/.agents/assets/problem-statement.md`. Before any diagnosis, read `~/.agents/assets/root-cause.md`.

## Type differences

| | feature | bug | refactor |
|---|---|---|---|
| Output dir | `features/<name>/plan.html` | `bugs/<name>/fix-plan.html` | `techdebt/<name>/plan.html` |
| Badge | `badge-feature` | `badge-bug` | `badge-techdebt` |
| Branch | `feat/` | `fix/` | `refactor/` |
| Plan opens with | Problem / Goal | Original Problem, then Findings | Rationale (`.callout.info`) |
| First test | Failing test for phase 1 | Failing test that reproduces the bug | Existing tests pass (parity baseline) |
| Extra gates | none | Gate A before investigating, Gate B before fixing | none |

## Steps

Do not skip a gate without user confirmation.

### 1. Explore

Read the spec or issue file first. Then read the affected code and existing patterns. For a refactor, name the debt, its impact, and the target state. For a bug, take a light pass only. Do not investigate deeply yet.

Detect the stacks from the manifests: `react`, `js-ts`, `python`, `html-css`, `aws`. Read the **Detect** and **Lint discovery** sections of each matching `djt-harness/stacks/<stack>.md`. Record the repo's lint, type, and format commands. Never add a linter the repo lacks.

### 2. Clarify

Ask every open question in one message. Wait for answers.

### 3. Bug only — Gate A: problem statement

Report in chat, short:

1. The problem in your words: what happens, what should happen, where, for whom. Say so if the code contradicts the user's framing.
2. Ranked theories with certainty level and evidence. "No theory yet" is a valid answer.
3. The first concrete investigation moves.

**STOP.** Wait for approval.

### 4. Bug only — investigate, then Gate B: diagnosis

Trace the code paths. Write a minimal failing test. Run it. Confirm it fails for the right reason.

Report in chat:

1. The issue, restated. Say if the framing changed.
2. Root cause with certainty level and evidence. Not "Confirmed" without a repro, an isolating test, or a pinpointing trace.
3. The minimal fix, by file and function.
4. The causal chain: bad behavior happens because X, the change fixes X, so behavior is right. A gap means go back to investigate.
5. Side effects and risk.

**STOP.** Wait for approval.

### 5. Plan

Write the plan to disk now. Use the HTML shell from **HTML Output Convention** in AGENTS.md (depth-2 stylesheet path `../../assets/style.css`). Bootstrap the stylesheet if missing. Point the user to the file.

- Open with the section in the table, in a `.section.accent` block. Write for a cold reader. Never lead with the approach.
- One `.phase-card` per phase: `.phase-number`, `.phase-title`, `.phase-steps`, `.test-criteria`.
- Phases are small and testable. Root cause goes in a `.finding-card.critical`. Risks go in a `.callout.warning`.
- Add brief rationale for key decisions.
- Each design choice gets one line: the choice, then its source, per `citations.md`. Flag a choice with no source as **unproven**. Build it only after the user approves.

Wait for explicit approval of the phases.

### 6. Branch and tests

1. Create the branch before any code.
2. Write the first test from the table (feature: failing tests for phase 1 only).
3. Run it. Report the real output.
4. Invoke `/djt-test-plan` for the phase's Doer Test Plan. Source goes in `<output dir>/doer-test-plan.html`.
5. If the phase touches UI, invoke `/djt-frontend-design` before writing it.

### 7. Implement, phase by phase

1. Load the stack file's rule-pack rows that match this phase. Read only those files.
2. Implement the phase.
3. Run the lint commands from step 1, then the project's tests. Report the real results. Ask the user to run the Doer Test Plan steps.
4. **STOP.** Wait for confirmation.
5. Commit. Use the phase description for the message.
6. Next phase.

### 8. PR

Open a PR per git conventions in AGENTS.md. Link the issue. Request review.

- Commit body: why. Feature: why built this way. Bug: why it occurred and why the fix is correct. Refactor: why it was needed and what improves.
- PR description: problem or goal for a cold reader, then (root cause for bugs), then approach.
