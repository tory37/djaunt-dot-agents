# Engineering Standards — Global

> This file is instructions for the AI agent, not the user. It applies across all projects on this machine.

## Acknowledge Before Acting — Unbreakable

**Before the first tool call of any request, acknowledge it.** State what the request is and what you're about to do as a whole — one or two sentences, not a step-by-step plan. Only then proceed.

- Applies to every request without exception: a question, a change, a data pull, a lookup — small or large.
- Example: "Got it — you want the login bug traced. I'll check the auth service logs and the recent commits to `auth/`." Then act.
- This is the one exception to "just do it" below: the initial acknowledgment is mandatory, but do not narrate each step after it — go silent until you have a result to report.

## Communication — Be Terse

Fear verbosity. Say exactly what is needed and nothing more, in the most direct way possible, while fully capturing the idea. No fluff, no preamble, no restating the question, no summarizing what you just did unless asked. Get to the point. Word choice and sentence construction follow **ASD-STE100** (Simplified Technical English, the aerospace-manual plain-language standard): short sentences, active voice, concrete verbs, one idea at a time.

- Answer first. Add context only if it changes what the user does next.
- Prefer the shortest form that is still complete: a word over a sentence, a sentence over a paragraph, a list over prose.
- Past the initial acknowledgment (see **Acknowledge Before Acting** above), do not narrate each step as you take it — just do it.
- **One sentence, one idea, ~20 words.** Don't join two claims with "and", "which", or a semicolon — split into separate sentences or bullets. Same rule for numbered steps: one action each, never "do X and then Y" in a single step.
- **Active voice, plain fact, named actor.** "The retry logic swallows the error," not "it was found that errors were being swallowed" or "it could potentially be handled." Cut hedging and filler ("I think", "it's worth noting", "as you can see", "in order to") along with the passive voice that usually carries it.
- **Concrete verbs, one term per concept.** Ban vague verbs ("handle", "leverage", "utilize", "manage", "process") in favor of the specific one ("parses", "retries", "deletes"). Pick one word per thing and reuse it — don't alternate synonyms (handler/callback/function) for the same referent, and don't lean on idioms or unexplained jargon.
- **No noun stacks.** Max three nouns in a row — "the user auth token refresh flow" becomes "the flow that refreshes the auth token."
- **Structure over prose, always.** Any response longer than ~3 sentences must use headers, bullets, or numbered steps — never a wall of paragraphs. If the content doesn't obviously fit a list, that's a signal to compress it, not to prose it out.
- **Lead with the outcome.** The first line answers the question or states what changed. Reasoning, caveats, and detail come after, and only if they change what the user does next.
- **Assume no shared context, but don't over-explain.** The user did not watch the work happen — tool calls, searches, and intermediate steps are invisible to them. A wrap-up must be readable standalone (name what was touched, what was found), but stay in list/fragment form, not narrative form. State the fact, not the journey to it.
- **Cap chat responses.** Prefer under ~10 lines for a status update or explanation. If more detail is genuinely needed, write it to a file and point to it — don't inline the long version in chat.
- **Compress subagent/tool output before relaying it.** A subagent's report is yours to hold, not to print. Reduce it to verdict + strongest supporting evidence line — never forward its full report structure or line-item detail dump verbatim.
- **Never splice code into prose.** File paths, line numbers, function/variable names, and code snippets always go in backticks, on their own bullet — never stitched into a sentence with "and"/commas. One fact (one file:line, one function, one claim) per bullet. A paragraph with more than one inline code reference must become a list.

## Output Files

Write anything non-conversational to `.agents/output/<type>/` under the matching subfolder (`features/`, `bugs/`, `research/`, etc.). Files are styled **HTML**, not markdown — see **HTML Output Convention** below. `.agents/output/sessions/` stays `.md` since the AI reads it back directly. Create directories as needed. Point the user to the file instead of printing its content to chat.

## Iterative Implementation & Commit Gates

**MANDATE:** Write plans, tests, and implementation to disk immediately — don't print file contents to chat when they're already on disk. Use git commits to separate logical phases of work.

1. **Write Immediately:** When a plan or implementation chunk is ready, write it to the appropriate file. Direct the user to the file for review rather than printing it all.
2. **Phase-Based Implementation:** Break features and fixes into discrete, testable phases (like user stories).
3. **Verify, Then Wait, Then Commit:** After a phase is implemented, verify it (tests pass, manual checks done) and report that to the user. Do not commit yet — wait for the user's explicit confirmation that it's working. Commit only after that confirmation. This applies even at the end of a phase: confirmation always comes before the commit, never after.
4. **Clean Diffs:** Each phase gets its own focused commit, keeping the version history readable.

### Ticket Sync (Kanban / Trello)

If the project uses `djt-kanban` (`.agents/.kanban/` folder present) or `djt-trello` (Trello skill in use), keep the active ticket in sync with implementation phases:

- After writing a plan, add the phases to the ticket — the markdown card in `.agents/.kanban/3_doing/` for Kanban, or an "Implementation Phases" checklist on the card for Trello.
- Tick off each phase there once its commit lands.

## Handling Interjectory Requests

When the user makes a request that is outside the scope of the current feature or story (an "interjectory request"):

1. **Identify Scope:** Explicitly ask yourself: "Is this part of the current feature, or is it an 'oh this would be nice' addition?"
2. **Isolate Changes:** If it is out-of-scope, do NOT implement it on the current feature branch.
3. **Branch Off Master:** Create a new branch specifically for this request, starting from `master` (or the project's default branch).
4. **Switch Back:** Once the interjectory task is reviewed/completed, switch back to the original feature branch to continue the primary work.

## Workflow

Use `/djt-feature` to start a new feature (iterative 7-step workflow). Use `/djt-bug` to start a bug investigation (test-driven). Use `/djt-techdebt` for refactoring or tech debt. Use `/djt-research` to synthesize research into a strategy. These accept an optional spec/issue/context file: `/djt-feature @path/to/spec.md`.

**Core Flow:** Gather info -> Write plan (phases) -> implement phase -> verify -> confirm with user -> commit -> repeat.

Manual test plans, UI/frontend work, and session snapshot/resume each route to their own skill — see the dedicated sections below. Use `/djt-pup` to upgrade a vague prompt before starting a new session.

For small, clear tasks (typo fix, rename, one-liner) — skip the workflow and act directly.

---

## Manual Test Plans — always via `/djt-test-plan`

**Any** request to write manual test cases — a doer test plan, QA steps, "how do I test this", validation steps for a change — goes through the `/djt-test-plan` skill. Do not hand-roll manual test plans inline; invoke the skill so scope, importance ranking, environment/URL resolution, and mitmproxy (mitmweb) fault-injection scripts are handled consistently.

A doer test plan tells both the implementer and a QA engineer how to: navigate to the change from the app's entry point, exercise the new behavior, and verify the expected outcome at each step — written tersely, scoped tightly to what the change puts at risk (not a regression sweep), and ordered by importance.

The skill places the plan on the active ticket when one is in play, otherwise writes it to `.agents/output/<type>/<name>/doer-test-plan.html`, with any generated mitmproxy scripts alongside.

---

## UI/Frontend Design — always via `/djt-frontend-design`

**Any** task that designs or builds a UI — a new page or component, a redesign of an existing view, a "make this look better" ask — goes through the `/djt-frontend-design` skill before code is written. Do not hand-roll interface design inline; invoke the skill so anti-slop constraints, current design paradigms, and the pre-flight design plan are applied consistently.

This applies inside `/djt-feature`, `/djt-bug`, and `/djt-techdebt` as well: whenever a phase or fix touches visual/UI work, invoke `/djt-frontend-design` for that phase before implementing it, the same way `/djt-test-plan` is invoked for manual test cases.

---

## HTML Output Convention

All human-facing output files (plans, reviews, research) are written as styled `.html` files, not markdown. This makes them visually scannable when opened in a browser.

### Stylesheet Bootstrap

Before writing the first HTML output file in a project, ensure the stylesheet exists:

```bash
mkdir -p .agents/output/assets
[ -f .agents/output/assets/style.css ] || cp ~/.agents/assets/style.css .agents/output/assets/style.css
```

### Relative Path to Stylesheet

Use a relative path from the HTML file to `.agents/output/assets/style.css`:

- File at `.agents/output/<type>/<file>.html` (one level deep) → `../assets/style.css`
- File at `.agents/output/<type>/<name>/<file>.html` (two levels deep) → `../../assets/style.css`

### Standard HTML Shell

Every output HTML file uses this base structure:

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>{{Title}} — {{type}}</title>
  <link rel="stylesheet" href="{{relative-path}}/assets/style.css">
</head>
<body data-type="{{type}}">
  <div class="container">
    <header class="doc-header">
      <div class="doc-meta">
        <span class="badge badge-{{type}}">{{TYPE}}</span>
        <span class="doc-date">{{YYYY-MM-DD}}</span>
      </div>
      <h1>{{Title}}</h1>
    </header>
    <main>
      {{sections}}
    </main>
  </div>
</body>
</html>
```

### Rainbow Type System

The stylesheet maps each doc type to a bold `--primary` color via `data-type` on `<body>`. Every component (H1 gradient, H3, phase numbers, card accents, table headers, code tint, etc.) automatically inherits this color — no extra CSS needed per doc.

| Type | Color | Hex |
|---|---|---|
| `feature` | Electric blue | `#3b9eff` |
| `bug` | Hot red | `#ff4d4d` |
| `research` | Vivid purple | `#b060ff` |
| `review` | Neon green | `#22d167` |
| `techdebt` | Vivid amber | `#f5a623` |

### Type Badges

Use `badge-feature`, `badge-bug`, `badge-research`, `badge-review`, or `badge-techdebt` on `.badge` elements in `.doc-meta`.

### Severity / Status Badges

Use `badge-critical`, `badge-warning`, `badge-suggestion`, `badge-complete`, `badge-pending`, or `badge-in-progress`.

### Key Component Classes

| Class | Use for |
|---|---|
| `.phase-card` | Each implementation phase (feature/techdebt plans) |
| `.phase-number`, `.phase-title`, `.phase-header` | Phase card header |
| `.phase-steps` | Ordered list of steps inside a phase |
| `.test-criteria` | Verification criteria block inside a phase |
| `.finding-card` + `.critical/.warning/.suggestion/.positive` | Review findings |
| `.finding-header`, `.finding-title`, `.finding-body`, `.finding-file` | Finding card anatomy |
| `.checklist` | Unordered list with checkbox-style bullets |
| `.test-steps` + `.test-step` | Numbered manual test steps (doer plans) |
| `.test-step .checkpoint` | Expected outcome inside a test step |
| `.meta-block` + `.meta-item` | Key/value metadata grid |
| `.section` + `.accent/.success/.warning/.danger` | Left-bordered content block |
| `.files-list` + `.file-chip` | Inline file path chips |
| `.bibliography` | Numbered sources list |
| `table` | Standard dark-styled data table |

---

## Git Conventions

- Interact with git through the CLI
- Branch names: `type/short-description` (e.g. `feat/oauth-login`, `fix/token-refresh`)
- Commits: imperative mood, <72 chars subject, body explains *why* not *what*
- PRs: link related issues, request review before merge
- NEVER commit until the user explicitly confirms the change is working — this holds even mid-workflow, after each phase (see Iterative Implementation & Commit Gates)
- NEVER push (including force-push) unless the user explicitly tells you to push
- NEVER force-push to the project's default protected branch
- NEVER write a bare `#<number>` in a GitHub commit message, PR description, PR comment, or issue comment — GitHub auto-links it to an issue/PR, turning a plain number (a count, an ID, a version) into an unrelated hyperlink. Escape or reword it: back-ticks (`` `#42` ``), a zero-width space, or rephrasing ("issue count: 42") all prevent the auto-link.

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

Use `/djt-suspend` to snapshot the current session to `.agents/output/sessions/<slug>.md` (stays `.md` — the AI reads it back directly).
Use `/djt-resume <slug>` to reload a saved session and continue where work left off.

---

## Context Compaction

Claude's `/compact` and Gemini's `/compress` both accept free-text steering instructions as an argument, but neither tool auto-applies a saved rule — there's no hook or skill that can inject this for you (Claude's `PreCompact` hook is side-effect-only: it can log or block a compaction, not rewrite its prompt). Paste this manually as the argument each time:

```text
Compact aggressively. Drop: file contents, code snippets, resolved debugging steps, dead-end exploration, prior conversational turns. Keep: a 1-2 sentence summary of the overarching feature/mission, what phase just finished and the specific objective for the next phase, file paths as pointers only (do not re-summarize their contents), and any open question blocking the next step.
```

---

## Solution Validation & Root Cause Analysis

State a certainty level with every diagnosis, backed by the data behind it. Never label something "confirmed" on incomplete evidence — downgrade to the honest level instead.

| Level | Evidence required | Say it as |
| --- | --- | --- |
| **Confirmed** | Reproduction, causal-chain code inspection, isolating test results, or a pinpointing stack trace — competing hypotheses ruled out | "Root cause confirmed: [fact], backed by [evidence]" |
| **High Probability** | Mechanism is clear but not yet reproduced, or evidence favors one hypothesis without ruling out others | "Most likely cause: [fact] because [evidence], but [what would confirm it]" |
| **Possible / Speculative** | Several hypotheses fit; limited visibility into the failure | "Possible causes (ranked): [list], investigation stopped because [reason]" |

For every report, answer: what data backs this, what data is missing, why wasn't it gathered, and what would disprove it. Keep investigating until those are answered, the user says stop, or the next step needs user action (running tests, sharing logs) — in which case say what's needed and why.

**Example:** Instead of "Root Cause Confirmed: missing error handler in login flow" (no evidence cited), write "Most likely cause: missing error handler in `auth/login.ts:47` — stack trace points there, no try/catch wraps the call, and two sibling handlers at lines 23/61 do have one. Not yet confirmed: haven't reproduced with an expired token. To confirm: run the integration test with an expired token and check for graceful handling instead of a crash."

