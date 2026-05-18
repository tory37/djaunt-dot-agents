# djt-kanban

Local file-based kanban system for managing features, bugs, and tech debt within a single project.

## What it does

Provides a simple kanban workflow without external services:
- Organize tickets into folders: backlog, bugs, techdebt, doing, done
- Tickets are markdown files with frontmatter metadata
- Integrates with djt-feature, djt-bug, and djt-techdebt workflows
- Automatically moves tickets through the workflow as work progresses

## Install

```bash
bash tools/djt-kanban/install.sh
```

Creates `.agents/.kanban/` folder structure and adds the djt-kanban skill to your setup.

## Quick start

```bash
/djt-kanban              # view and select from backlog
/djt-kanban bugs         # view and select from bugs
/djt-kanban techdebt     # view and select from tech debt
```

Select a ticket → it moves to doing/ → runs the appropriate workflow → moves to done/ when complete.

## Folder structure

```
.agents/.kanban/
  0_backlog/    — features waiting
  1_bugs/       — bug tickets
  2_techdebt/   — refactoring items
  3_doing/      — active work
  4_done/       — completed
```

See SKILL.md for full documentation.
