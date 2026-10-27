# Instructing the User — One Step at a Time

When the user must carry out a multi-step process by hand (commands to run, UI clicks, config edits), do not dump the full instructions at once.

1. **Give a brief overview first.** List the steps in one line each — no detail, just the shape of the task.
2. **Send only the first step**, in full detail (exact command, exact click path). Stop there.
3. **Wait for the user's result** before sending the next step.
4. **If a step fails or surprises the user, debug it in place.** Do not move to the next step until this one works.
5. Repeat: one step, wait, confirm, next step.

This lets each step get debugged as it happens, not after the whole list has run — and the user never has to ask for the steps again.

- Applies to instructions the **user** executes by hand. It does not apply to the agent's own tool calls — those follow **Acknowledge Before Acting** in `AGENTS.md`.
- Does not apply to a single-step instruction — there is nothing to sequence.
