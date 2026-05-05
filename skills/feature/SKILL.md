---
name: feature
description: "Kick off the full engineering workflow for a new feature. Accepts an optional spec file: /feature @path/to/spec.md"
trigger: /feature
---

# /feature

Start the full engineering workflow for a new feature.

## Usage

```
/feature                      # start with no spec; agent will ask for context
/feature @path/to/spec.md     # start from a written spec file
```

## Steps

Work through the following steps in order. Do not skip ahead without user confirmation at each gate.

### 1. Explore

Read the relevant parts of the codebase before writing anything. If a spec file was provided, read it first to understand scope, then explore affected files, related modules, and existing patterns.

### 2. Clarify

If there are unknowns or ambiguities, surface them all at once in a single message. Do not ask one question at a time. Wait for answers before proceeding.

### 3. Plan

Write a step-by-step implementation plan to `.agents/<feature-name>-plan.md`. The plan must include:
- Tests first (what needs to be tested and how)
- Implementation steps second
- Brief rationale for key decisions
- Optional improvements only if weak points directly related to the change are found
- Suggestions to break into smaller sessions if the scope is large

**Present the plan to the user and await explicit approval before proceeding.**

### 4. Test-Driven Development

Write failing tests before any implementation code.

- If the project has an existing test framework, adhere to it.
- If no test framework exists, examine the codebase and language, then suggest the best options for both unit AND integration tests. Await user confirmation before setting anything up.
- Goal: programmatic confidence the change works as intended — unit tests for logic, integration tests for behavior.
- Have the user run the tests to confirm they compile and fail as expected. Do not run them yourself.
- Write a Doer Test Plan to `.agents/<feature-name>-doer-test-plan.md` (see definition in AGENTS.md).

### 5. Create a Branch

Create a new git branch before writing any implementation code.

Branch naming: `type/short-description` (e.g. `feat/oauth-login`)

### 6. Implement

Code against the approved plan **as it exists on disk** — do not implement from memory.

- Follow the project's style and linting rules.
- Update the Doer Test Plan if steps or details change during implementation.
- Once finished, present a summary and await user confirmation of completeness.

### 7. Commit & PR

Commit the changes and open a Pull Request.

- Commit message: imperative mood, under 72 characters, body explains *why* not *what*.
- PR description: feature explanation + brief implementation overview.
- Link related issues. Request review before merge.
