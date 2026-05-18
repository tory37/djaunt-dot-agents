# Engineering Standards — Global

> This file is instructions for the AI agent, not the user. It applies across all projects on this machine.

**Overview**: When presenting anything non-conversational to the user, write things out to `.agents/output/<type>/` using the appropriate subfolder for the type of work (e.g. `features/`, `bugs/`, `research/`, `sessions/`). Create the directory if needed. Then direct the user to the written files instead of printing output to the screen unnecessarily.

## Iterative Implementation & Commit Gates

**MANDATE:** Prioritize writing to disk immediately (plans, tests, implementation). Do not waste tokens printing full file contents to the console if they are being written to a file. Use git commits to separate logical phases of work.

1. **Write Immediately:** When a plan or implementation chunk is ready, write it to the appropriate file. Direct the user to the file for review rather than printing it all.
2. **Phase-Based Implementation:** Break features and fixes into discrete, testable phases (like user stories). 
3. **Commit as Gate:** After completing a phase and verifying it (tests pass, manual checks done), COMMIT the changes. This commit acts as the approval gate for that phase. Only move to the next phase after the current one is committed.
4. **Clean Diffs:** This approach ensures each phase has a clean, focused diff in the version history.

### Kanban Integration

If the project uses the `djt-kanban` system (detected by `.agents/.kanban/` folder):
- **Sync Phases:** After writing an implementation plan, immediately update the active ticket in `.agents/.kanban/3_doing/` to include the implementation phases.
- **Tally Progress:** Tick off phases in the markdown ticket as they are committed.

## Handling Interjectory Requests

When the user makes a request that is outside the scope of the current feature or story (an "interjectory request"):

1. **Identify Scope:** Explicitly ask yourself: "Is this part of the current feature, or is it an 'oh this would be nice' addition?"
2. **Isolate Changes:** If it is out-of-scope, do NOT implement it on the current feature branch.
3. **Branch Off Master:** Create a new branch specifically for this request, starting from `master` (or the project's default branch).
4. **Switch Back:** Once the interjectory task is reviewed/completed, switch back to the original feature branch to continue the primary work.

## Workflow

Use `/djt-feature` to start a new feature (iterative 7-step workflow). Use `/djt-bug` to start a bug investigation (test-driven). Use `/djt-techdebt` for refactoring or tech debt. Use `/djt-research` to synthesize research into a strategy. These accept an optional spec/issue/context file: `/djt-feature @path/to/spec.md`.

**Core Flow:** Gather info -> Write plan (phases) -> implement phase -> verify -> commit -> repeat.

Use `/djt-suspend` to snapshot a session; `/djt-resume <slug>` to reload one. Use `/djt-pup` to upgrade a vague prompt before starting a new session.

For small, clear tasks (typo fix, rename, one-liner) — skip the workflow and act directly.

---

## Doer Test Plan

A Doer Test Plan is a written list of manual steps that tells both the implementer and a QA engineer how to:

1. Navigate to the feature from the app's entry point (e.g. "Start at the login page, navigate to Settings > Notifications")
2. Exercise the change or new behavior
3. Verify the expected outcome at each step

It should be written in plain language, sequentially, with explicit checkpoints. Leave placeholders (`[TODO: determine exact route]`) for details not yet known. Update it as implementation reveals specifics.

Write the Doer Test Plan to `.agents/output/features/<feature-name>/doer-test-plan.md`.

---

## Git Conventions

- Interact with git through the CLI
- Branch names: `type/short-description` (e.g. `feat/oauth-login`, `fix/token-refresh`)
- Commits: imperative mood, <72 chars subject, body explains *why* not *what*
- PRs: link related issues, request review before merge
- NEVER force-push to the project's default protected branch

## IMPORTANT Rules

- **Token Efficiency:** To save context and cost, do not run tests (unit, e2e, integration) yourself. Always prompt the user to run the tests and report the results back to you. **Never over-deliver unrequested implementation plans or code.** If the user asks a question, answer it and stop.
- ALWAYS verify work before saying it's done
- NEVER modify production databases/infra without explicit user confirmation
- NEVER commit .env files, credentials, or secrets
- When uncertain about scope, ask — don't assume

## Debug Logging

Use a **single filterable/queryable prefix** for all debug logs in a session, and remove them before merging.

The following is a TypeScript example — apply the same pattern in whatever language the project uses:

```typescript
const DEBUG_TAG = "[FEATURE-DEBUG]";
console.log(`${DEBUG_TAG} context:`, data);
```

## Code Clarity & Documentation

Write code that reads like a clear sentence. A future reader (or the AI picking this up mid-session) should be able to understand *what* a block does from the identifiers alone. Comments exist to explain *why*, not *what*.

### Self-Documenting Code

- **Names carry meaning.** Variables, functions, and types should say exactly what they hold or do. Prefer `userSessionToken` over `tok`, `calculateMonthlyRevenue` over `calc`, `isEligibleForPromotion` over `flag`.
- **Avoid clever compression.** No nested ternaries, chained optional chains on a single line doing multiple things, or one-liners that require mental parsing. Break them into named steps.
- **Boolean conditions** should read as assertions: `isExpired`, `hasCompletedOnboarding`, `canEditRecord` — not `expiry`, `done`, `edit`.
- **Magic numbers and strings** get named constants: `const MAX_RETRY_ATTEMPTS = 3` not `if (retries > 3)`.

### When to Add a Comment

Add a comment when a future reader would reasonably be confused about *why* this code does what it does — a hidden constraint, a non-obvious invariant, a workaround for a specific external behavior. One focused sentence is almost always enough.

Do NOT add comments that restate the code: `// increment counter` above `count++` adds noise.

For larger blocks (a complex algorithm, a multi-step data transformation, a non-obvious state machine), a brief header comment stating the *goal* and any important *preconditions or side effects* is appropriate. Keep it to 2–4 lines max.

### Existing Patterns That Conflict with Best Practices

If you encounter existing code that uses patterns contrary to these standards (e.g., compressed one-liners, poor naming throughout a file, no separation of concerns), do the following **before writing any code**:

1. Note the conflict in your plan or response.
2. Present the user with the choice:
   - **Match existing patterns** — for consistency within the file, lower diff noise
   - **Follow best practices** — cleaner output, but diverges from surrounding code
3. Wait for the user's direction before proceeding.

Never silently match a bad pattern. Never silently ignore it and "do it right" without flagging the divergence.

---

## Session Management

Use `/djt-suspend` to snapshot the current session to `.agents/output/sessions/<slug>.md`.
Use `/djt-resume <slug>` to reload a saved session and continue where work left off.

---

## Solution Validation & Root Cause Analysis

When presenting a diagnosis or solution, especially in plan mode summaries, be explicit about the **certainty level** and **data backing it up**.

### Three Levels of Confidence

1. **Confirmed** — The root cause is backed by:
   - Direct observation or reproduction
   - Code inspection with clear causal chain
   - Test results that isolate the problem
   - Logs/stack traces that pinpoint the failure
   - Evidence that rules out competing hypotheses

   Use language like: "Root cause confirmed: [specific fact]" with supporting evidence cited.

2. **High Probability** — The cause is strongly supported but not definitively proven:
   - Evidence points in one direction but competing hypotheses aren't fully ruled out
   - Code inspection shows a clear mechanism, but we haven't reproduced the failure yet
   - Pattern matches known issues in similar codebases

   Use language like: "Most likely cause: [specific fact] because [evidence], but [what would confirm it]" and list what's missing.

3. **Possible / Speculative** — Multiple causes remain plausible:
   - Several hypotheses fit the available data
   - We have limited visibility into the failure
   - Initial hunch based on code structure, not empirical evidence

   Use language like: "Possible causes (ranked by likelihood): [list with evidence for each]" and explain why deeper investigation wasn't feasible/done.

### Standards for All Reports

**Always answer these questions:**

- What **data** backs this solution? (logs, test results, code inspection, reproduction)
- What **data is missing** that would make this more certain?
- Why didn't you gather that data? (scope constraint, time, blocked, user hasn't provided it yet)
- What would **disprove** this solution?

**Never report "Root Cause Confirmed" without evidence.** Use "Most Likely" or "Possible" instead when you're working from incomplete information.

**Go as deep as possible.** If you haven't answered the four questions above, keep investigating. Only stop when:

- You've exhausted available data / logs / code paths
- The user has asked you to stop or move on
- Completing the investigation would require user action (running tests, providing logs, etc.) — in that case, explain what's needed and why

### Example (Bad)
>
> **Root Cause Confirmed:** Missing error handler in login flow.

### Example (Good)
>
> **Most Likely Cause:** Missing error handler in auth/login.ts around line 47, based on:
>
> - Stack trace shows uncaught error at that location
> - Code inspection confirms no try/catch wrapping the async call
> - Two similar handlers in the file *do* have error handling (lines 23, 61), suggesting this is a pattern oversight
>
> **Not yet confirmed because:**
>
> - We haven't reproduced the failure with a fresh token refresh
> - We don't know what triggers the specific code path (needs test environment access)
>
> **To fully confirm:** Run integration tests with an expired token; expected: graceful error handling instead of crash.

ed:** Missing error handler in login flow.

### Example (Good)
>
> **Most Likely Cause:** Missing error handler in auth/login.ts around line 47, based on:
>
> - Stack trace shows uncaught error at that location
> - Code inspection confirms no try/catch wrapping the async call
> - Two similar handlers in the file *do* have error handling (lines 23, 61), suggesting this is a pattern oversight
>
> **Not yet confirmed because:**
>
> - We haven't reproduced the failure with a fresh token refresh
> - We don't know what triggers the specific code path (needs test environment access)
>
> **To fully confirm:** Run integration tests with an expired token; expected: graceful error handling instead of crash.

