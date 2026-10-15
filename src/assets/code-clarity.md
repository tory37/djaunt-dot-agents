# Code Clarity & Documentation

Write code that reads like a clear sentence. A future reader (or the AI picking this up mid-session) should be able to understand *what* a block does from the identifiers alone. Comments exist to explain *why*, not *what*.

## Self-Documenting Code

- **Names carry meaning.** Variables, functions, and types should say exactly what they hold or do. `userSessionToken`, not `tok`.
- **Avoid clever compression.** No nested ternaries, chained optional chains on a single line doing multiple things, or one-liners that require mental parsing. Break them into named steps.
- **Boolean conditions** should read as assertions: `isExpired`, not `expiry`.
- **Magic numbers and strings** get named constants: `const MAX_RETRY_ATTEMPTS = 3` not `if (retries > 3)`.

## When to Add a Comment

Default to zero comments. Rely on names and structure to carry meaning, not prose next to the code.

Add a comment only when a future reader would reasonably be confused about *why* this code does what it does — a hidden constraint, a non-obvious invariant, a workaround for a specific external behavior — and no rename or restructure can make that clear on its own. One focused sentence, almost never more.

Do NOT add comments that restate the code: `// increment counter` above `count++` adds noise.

When editing code that already has a comment, update it only if the change makes it factually wrong. Edit the minimum words needed to make it accurate again — don't rewrite, expand, or restyle it.

## Existing Patterns That Conflict with Best Practices

If you encounter existing code that uses patterns contrary to these standards (e.g., compressed one-liners, poor naming throughout a file, no separation of concerns), do the following **before writing any code**:

1. Note the conflict in your plan or response.
2. Present the user with the choice:
   - **Match existing patterns** — for consistency within the file, lower diff noise
   - **Follow best practices** — cleaner output, but diverges from surrounding code
3. Wait for the user's direction before proceeding.

Never silently match a bad pattern. Never silently ignore it and "do it right" without flagging the divergence.
