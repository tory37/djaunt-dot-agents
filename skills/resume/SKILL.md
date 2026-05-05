---
name: resume
description: "Load a saved session summary from .agents/sessions/ to restore context and continue prior work."
trigger: /resume
gemini_trigger: "When the user types /resume or asks to continue, reload, or pick up previous work, always execute the following workflow exactly:"
---

# /resume

Reload a suspended session from `.agents/sessions/` and orient the agent to continue where work left off.

## Usage

```
/resume <slug>        # e.g. /resume amr-123-oauth-login
/resume               # list available sessions if no argument given
```

## Steps

1. If no argument is given:
   - List all `.md` files in `.agents/sessions/`
   - Show the name, last-updated date, and status for each
   - Ask the user which one to resume

2. If a slug is given:
   - Read `.agents/sessions/<slug>.md`
   - Confirm the file exists; if not, list available sessions

3. After reading the file, orient with a brief recap:
   - What the work is (one sentence)
   - Current status
   - What was completed
   - What is pending
   - The immediate next step to take

4. Ask the user: "Ready to continue?" or note if any clarification is needed before proceeding.
