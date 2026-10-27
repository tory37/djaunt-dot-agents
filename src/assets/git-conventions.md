# Git Conventions

- Interact with git through the CLI
- Branch names: `type/short-description` (e.g. `feat/oauth-login`, `fix/token-refresh`)
- Commits: imperative mood, <72 chars subject, body explains *why* not *what*
- PRs: link related issues, request review before merge
- NEVER write a bare `#<number>` in a GitHub commit message, PR description, PR comment, or issue comment — GitHub auto-links it to an issue/PR, turning a plain number (a count, an ID, a version) into an unrelated hyperlink. Escape or reword it: back-ticks (`` `#42` ``), a zero-width space, or rephrasing ("issue count: 42") all prevent the auto-link.
