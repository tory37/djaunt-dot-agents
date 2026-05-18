---
epic: EXAMPLE_EPIC
ticket: example-ticket-name
created: 2026-05-17
priority: high
---

# [Epic]: [Ticket Title]

**Status:** backlog
**Assignee:** (optional)
**Due Date:** (optional)

## Context

Brief description of why this work is needed and what problem it solves.

## Scope

What's included in this ticket (and what's explicitly NOT included).

## Acceptance Criteria

- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## Implementation Phases

*Populate this section after writing your plan (via /djt-feature, etc.). Each phase should be committed upon completion.*

- [ ] **Phase 1: [Short Title]** - [Brief goal]
- [ ] **Phase 2: [Short Title]** - [Brief goal]

## Notes

Any additional context, constraints, or references to related tickets.

---

**Usage:**
1. Copy this as `.agents/.kanban/0_backlog/{epic}.{ticket}.md`
2. Update the frontmatter and content with your ticket details
3. When ready to work, invoke `/djt-kanban` and select this ticket
4. It will move to `3_doing/` and start the workflow
5. When complete, it moves to `4_done/`
