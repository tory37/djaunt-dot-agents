---
name: djt-test-plan
description: "Produce a tight, change-scoped manual test plan. One plan: the author runs it from an interactive artifact with links and copy buttons, then it is posted to the ticket's Doer Test Plan field once local validation is done. QA runs it as written. mitmweb fault-injection scripts are generated per environment. /djt-test-plan [target]"
trigger: /djt-test-plan
---

# /djt-test-plan

Write manual test plans that validate **one change**, and generate the mitmweb (mitmproxy) scripts needed to exercise the hard-to-reach cases.

**Read `reference.md` (same directory as this file) before Step 1.** It holds the full principles, step detail, artifact spec, QA format, table rules, and script conventions. This file is the outline.

**One plan, two forms.** The doer test plan is the QA test plan. Never write a separate QA plan. Never offer one.

| Form | Reader | When | Lands in |
|---|---|---|---|
| **Artifact** | The author, testing their own change | Before sending the change to review | An interactive artifact (links, copy buttons, result tracking) |
| **Markdown** | QA, with no repo access | After the author confirms local testing is done | The ticket's Doer Test Plan field (else the PR or request source) |

This is the single entry point for **all manual-test-case authoring**. Any request to "write a test plan", "manual test steps", "QA steps", "how do I test this", or "doer test plan" routes through this skill.

## Usage

```
/djt-test-plan                       # doer plan for the current branch/diff
/djt-test-plan PROJ-1615           # doer plan from a ticket
/djt-test-plan origin/develop..HEAD  # doer plan from a diff range
/djt-test-plan @path/to/spec.md      # doer plan from a spec/notes file
/djt-test-plan post                  # post the plan to the ticket, after local testing is done
```

Input-agnostic: work on whatever is given (diff, PR, ticket, prose, current branch). State what you could not determine. Never guess.

## Which step?

- **Write the artifact** — the default. Any ask to test the change yourself, "before review", "how do I test this", or a bare `/djt-test-plan`.
- **Post the plan** — only when the user says local testing is done / validated, or runs `/djt-test-plan post`.
- **Never both in one pass.** After the artifact, stop and wait.
- If unclear which step, ask.

## Principles (non-negotiable)

1. **Tight scope.** A case belongs only if its outcome could change because of this change. Never list what is out of scope.
2. **No backtracking.** Order cases by shared setup first, importance second.
3. **One case per behavior**, not per environment. Env details go in Scripts and Notes.
4. **Real API when the contract changed.** Inject faults only on existing, verified pathways.
5. **See it or ask.** Bake in only hosts and links you can observe. Never guess a production endpoint.
6. **Terse rows.** Intent, steps, expected result. Setup once. Scripts by name.
7. **Honest confidence.** Flag speculative cases and gaps.
8. **Executable as written.** Copy button or own code block for anything typed. Link for anything opened.
9. **No secrets.** Test emails and IDs are fine. Credentials: say where to find them.

## Workflow

1. **Gather context.** Read the diff, ticket, or spec. Find the response shapes, branches, and edges the change keys off. Collect links you can see. Resolve the plan destination.
2. **Derive cases.** Keep only in-scope cases. Drop structurally unreachable cases and duplicated happy paths. Capture intent, steps, expected result, and setup. Sequence with no backtracking.
3. **Find fault-injection points.** Contract-changing cases are `[real API]`. Map the rest to drop, empty, mutate, or latency. If any case needs injection, Step 4 is a blocking gate.
4. **Resolve environments and hosts.** Skipped when no case needs injection. Otherwise ask which environments, ask for each host, and confirm repo-found URLs.
5. **Generate mitmweb scripts.** Host-agnostic, operation-matched, one per case. Ship as heredoc blocks inside the plan. Never as repo files.
6. **Write the plan.** Rows are QA-ready: what the tester sees and does, no repo detail. Publish the artifact, give the link, stop.
7. **Wait for the doer's result.** Failures mean fix and update the artifact. Pass means Step 8. Skipped rows stay in the plan, marked skipped.
8. **Post the plan.** Convert the same plan to markdown. Set the ticket's Doer Test Plan field. Else post to the PR or request source. The source of the request wins. Ask if unclear. On failure, write `.agents/output/<type>/<slug>/test-plan.md`.
9. **Summarize in the terminal.** Short. Name the artifact or destination, case count, scripts, environments, gaps.

## Output shapes

- **Artifact:** `.agents/output/<type>/<slug>/doer-test-plan.html`. Load `artifact-design` first. Sections in order: header, links, setup, cases, notes, scripts, copy-results.
- **Posted plan:** Markdown, never HTML. Tory's voice, pitched at the tester. Sections: heading, what changed, dev-verified, setup, cases, notes, scripts.
- **Case table:** `| # | Do | Expect |`. One row per behavior. No importance labels. No rationale. The plan must be shorter than the change deserves.
- **Scripts:** one block per independently-run unit, each titled `TC{n}`. Real values, absolute or `~/` paths, no placeholders.
