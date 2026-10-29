# djt-work-deep — Reference

Read each section at the step that names it.

## Recon

Recon fills brief `00-recon.html`. It uses the same four sections as every brief.

**Problem: the request, decoded.**

- Say what the request asks, in plain words. Quote the spec or issue where it is exact.
- Define each domain term and each technical term on first use.
- Say who sees the change, and what "done" looks like to them.
- List what is out of scope.

**Background: the codebase map.**

- Stack: languages, versions, frameworks, package manager. Cite the manifest line.
- Architecture: the main parts and how they talk to each other. One short diagram in a `<pre>` block is fine.
- Data flow for the touched area only: the entry point, each hop, and where data is stored or returned. One `file:line` per hop.
- Conventions: naming, layout, error style, test style. Cite one example file for each.
- Commands: build, run, test, lint, type check, format. Take them from `package.json` scripts, `Makefile`, or CI. Mark each one as run and passed, or not run yet.

**Solution: the route.** A first outline of the micro-phases and the concept each one teaches. The plan in step 3 makes it final.

**Evidence.** Most recon claims cite repo precedent (tier 2) as `path:line`. Concept explanations cite tier 1 docs.

Run the test and lint commands once during recon. Report the baseline: what passes and what already fails.

## Micro-phases

A micro-phase is the smallest change that:

1. Teaches one concept. Name it in a few words: "React context for theme state", "pytest fixtures for the DB session".
2. Works on its own. The app builds. The tests pass. Nothing is half-wired.
3. Has its own test, or proves itself with an existing one.

Split a phase when:

- It teaches two concepts. Example: a new API route plus a new UI component is two phases.
- Its brief needs more than three Background concepts.
- Its diff touches more than one layer of the architecture.

Do not split a phase to below one working change. A phase that leaves the build red is not a phase.

Order the phases so each concept builds on the last. Data shape first, then logic, then the edges (UI, API, CLI).

## Research

For each claim, in this order:

1. The stack file's **Tier 1 docs** section. Use `docs-mcp` for AWS and MDN. Use the listed URLs for the rest.
2. A lint rule's own doc page, when a repo lint rule drives the choice.
3. Repo precedent: `path:line`. It shows what the repo does, not that it is right.
4. Rule-pack files, from the rows loaded at step 5.1. Only beside a tier 1 or tier 2 source.

Match the doc version to the repo: the language version, the framework major version.

**Unproven.** When research finds nothing, send the user this, then wait:

```
Unproven: <the claim>
Searched: <each source and query tried>
Build anyway? (yes / no / try <source>)
```

Record an approved unproven claim in the brief's Evidence table, with the tier set to `unproven (approved)`.

## Briefs

Short but deep. The target is a reader who has never seen this code or this language. Aim for a 5-minute read.

**File.** `<output dir>/briefs/NN-<slug>.html`. `NN` is two digits and runs in order across the whole work: `00-recon`, then each gate or phase. `<slug>` is the concept in kebab case. Set the badge and `data-type` to the work type.

**Problem.** Two to four sentences. What this phase solves and why it matters now. No solution here.

**Background.** The concepts a newcomer needs to understand both the problem and the fix. One `h3` per concept. Cover three layers, as the phase needs them:

1. The language feature. Example: what a Python context manager does.
2. The framework internals. Example: when React runs an effect.
3. This codebase. Example: where this repo opens DB sessions, with `path:line`.

Teach the idea, then show it in this repo's code. Define a term before using it. Link out for depth instead of restating a whole doc page.

**Solution.**

- What changes, by file and function.
- Why this way. Tie each reason to a Background concept.
- Alternatives rejected, one line each, with the reason.
- The tradeoff accepted, if any.

**Evidence.** One table row per claim made in Background and Solution: the claim, the citation, the tier. Use the citation format in `citations.md`. A claim with no row is not built.

**Chat teaser.** Two to four lines: the concept, the one insight worth the read, and the path.

## Bug briefs

`01-problem.html` goes with Gate A. `02-diagnosis.html` goes with Gate B.

- Problem: the bug in plain words. What happens, what should happen, for whom.
- Background: the failing subsystem. What it is for, how data moves through it, and the language or framework rule the bug breaks.
- Solution: Gate A holds the ranked theories and the next moves. Gate B holds the root cause, the causal chain, and the minimal fix.
- Evidence: each step of the causal chain cites a trace, a test, a log line, or a doc. Certainty levels follow `~/.agents/assets/root-cause.md`.
