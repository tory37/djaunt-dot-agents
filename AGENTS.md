# Engineering Standards — Global

> This file is instructions for the AI agent, not the user. It applies across all projects on this machine.

**Overview**: When presenting anything non-conversational to the user, write things out to a `.md` file in the `.agents` sub-directory of the project. Create `.agents` if needed. Then direct the user to the written files instead of printing output to the screen unnecessarily.

## Workflow

Use `/djt-feature` to start a new feature (full 7-step workflow). Use `/djt-bug` to start a bug investigation (test-driven). Both accept an optional spec/issue file: `/djt-feature @path/to/spec.md`.

For small, clear tasks (typo fix, rename, one-liner) — skip the workflow and act directly.

---

## Doer Test Plan

A Doer Test Plan is a written list of manual steps that tells both the implementer and a QA engineer how to:
1. Navigate to the feature from the app's entry point (e.g. "Start at the login page, navigate to Settings > Notifications")
2. Exercise the change or new behavior
3. Verify the expected outcome at each step

It should be written in plain language, sequentially, with explicit checkpoints. Leave placeholders (`[TODO: determine exact route]`) for details not yet known. Update it as implementation reveals specifics.

Write the Doer Test Plan to `.agents/<feature-name>-doer-test-plan.md`.

---

## Git Conventions
- Interact with git through the CLI
- Branch names: `type/short-description` (e.g. `feat/oauth-login`, `fix/token-refresh`)
- Commits: imperative mood, <72 chars subject, body explains *why* not *what*
- PRs: link related issues, request review before merge
- NEVER force-push to the project's default protected branch

## IMPORTANT Rules
- **Token Efficiency:** To save context and cost, do not run tests (unit, e2e, integration) yourself. Always prompt the user to run the tests and report the results back to you.
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

## Session Management

Use `/djt-suspend` to snapshot the current session to `.agents/sessions/<slug>.md`.
Use `/djt-resume <slug>` to reload a saved session and continue where work left off.

## Environment-Specific Extensions

<!-- PROJECT_EXTENSIONS_PLACEHOLDER: replace this line with project-specific AGENTS references when configuring for a new machine -->
