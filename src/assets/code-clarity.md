# Code Clarity & Documentation

Code must be understood by reading it. Names and structure carry the meaning. A comment is a last resort.

## Names and Structure

- **Names say what a thing holds or does.** `userSessionToken`, not `tok`. A count is `forcedDownlevelCount`, not `downlevel`.
- **Booleans read as assertions.** `isExpired`, not `expiry`.
- **Magic numbers and strings get named constants.** `MAX_RETRY_ATTEMPTS`, not `3`.
- **No clever compression.** No nested ternaries or multi-purpose one-liners. Break them into named steps.
- **One module, one concept.** If the filename is narrower than its contents, rename it.

## Comments

- **Default: none.** Match the comment density of the surrounding code. Bare neighbors mean a bare addition.
- **Allowed: one sentence of *why*.** Only for a hidden constraint, a non-obvious invariant, or an external workaround that no name can carry.
- **Never:** restating the code, multi-line docstrings, or provenance. Provenance (upstream file, breaking commit) goes in the commit or PR body.
- **Editing an existing comment:** change it only if the edit made it false. Use the fewest words.

## Pass Before Every Commit

For each comment the diff adds, ask what the reader loses without it.

1. A name's meaning: rename until the name says it, then delete the comment.
2. A *why* no name can carry: keep one sentence.
3. Anything else: delete it.

Deleting without renaming leaves the name unexplained.

## Existing Patterns

Match the surrounding code: naming, structure, idiom, comment density.

Diverge only when the surrounding code is obviously bad (compressed one-liners, misleading names). Then flag it before writing code and offer two options:

- **Match existing patterns.** Consistent, smaller diff.
- **Follow best practices.** Cleaner, diverges from the file.

Wait for the user's choice. Never silently match a bad pattern. Never silently diverge.
