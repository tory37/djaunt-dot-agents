---
name: djt-kanban
description: "Manage local kanban workflow for features, bugs, and tech debt. /djt-kanban [bugs|techdebt]"
trigger: /djt-kanban
---

# /djt-kanban

Manage a file-based kanban system for organizing and tracking work across your project.

## Usage

```
/djt-kanban              # view and select from backlog tickets
/djt-kanban bugs         # view and select from bug tickets
/djt-kanban techdebt     # view and select from tech debt tickets
```

## Folder Structure

The kanban system uses `.agents/.kanban/` with status folders ordered for visual clarity:

```
.agents/.kanban/
  0_backlog/    — Feature tickets waiting to be picked up
  1_bugs/       — Bug tickets (parallel track)
  2_techdebt/   — Refactoring and tech debt items (parallel track)
  3_doing/      — Currently active work
  4_done/       — Completed work
```

## Ticket Format

Tickets are markdown files named `{epic}.{ticket}.md` with frontmatter metadata:

```markdown
---
epic: auth-flow
ticket: login-password-reset
created: 2026-05-17
priority: high
---

# Auth Flow: Password Reset

Description of the ticket, acceptance criteria, and scope...
```

**Frontmatter fields:**
- `epic` — feature grouping (e.g., `auth-flow`, `dashboard-redesign`)
- `ticket` — specific work item name
- `created` — date ticket was created (ISO 8601)
- `priority` — critical, high, medium, low
- Optional: `assignee`, `due-date`, `depends-on`

## Workflow

### Starting Work

1. **List tickets** from the appropriate folder (backlog, bugs, or techdebt)
2. **Select a ticket** to start working on
3. **Ticket auto-moves** to `3_doing/` — agent begins the standard workflow (plan, implement, test, etc.)

### Completing Work

1. **Once work is done**, ticket auto-moves to `4_done/`
2. Ticket remains in archive for project history

## Integration with Standard Workflows

Each ticket is independent; when you select one:

- **Backlog ticket** → runs the full `/djt-feature` workflow
- **Bug ticket** → runs the `/djt-bug` workflow
- **Tech debt ticket** → runs the `/djt-techdebt` workflow

The kanban system manages state transitions (folder movement); the standard workflows handle implementation, testing, and completion gates.

## Visual Benefits

**Alphabetical folder ordering (0 → 4)** creates a natural visual progression:

```
0_backlog    ← incoming work
1_bugs       ← parallel bug track
2_techdebt   ← parallel refactoring track
3_doing      ← active work (small, focused)
4_done       ← completed (reference/history)
```

**At a glance**, `ls .agents/.kanban/` shows:
- How many items are queued (backlog size)
- Known bugs and tech debt inventory
- Current focus (doing folder size — should be small)
- Completed work for the session
