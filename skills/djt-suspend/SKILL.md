---
name: djt-suspend
description: "Save a session summary to .agents/sessions/ so work can be resumed later. Run /djt-suspend to snapshot current context."
trigger: /djt-suspend
---

# /djt-suspend

Snapshot the current working session into `.agents/sessions/<name>.md` so it can be resumed in a future conversation.

## Steps

1. Determine the session name:
   - If the user passed an argument (e.g. `/djt-suspend AMR-123`), use that as the filename slug.
   - Otherwise, derive a short slug from the ticket key or feature being worked on (e.g. `amr-123-oauth-login`).

2. Gather context from the current conversation:
   - Ticket key and brief description
   - Current status
   - What has been implemented so far
   - What is still pending
   - Any technical notes, decisions, or gotchas
   - Clear next steps for resuming

3. Write the file to `.agents/sessions/<slug>.md` using this template:

```markdown
# <TICKET-KEY>: Brief Description

**Last Updated:** YYYY-MM-DD
**Status:** In Progress | Awaiting Feedback | Ready for Review
**Branch:** <branch name if exists>
**PR:** [link if exists]

## Summary

<!-- One paragraph: what this work is and why -->

## Implementation Complete

<!-- Bullet list of what is done -->

## Pending

<!-- Bullet list of what still needs to happen -->

## Technical Notes

<!-- Decisions made, gotchas, constraints, anything non-obvious -->

## Next Steps

<!-- Ordered list of exactly what to do next to resume -->
```

4. Create `.agents/output/sessions/` if it does not exist.

5. Tell the user the file path and that they can resume with `/djt-resume <slug>`.
lug>`.
