---
name: {{PREFIX}}-trello
description: "Retrieve or add Trello cards across BUGS, TECH DEBT, and BACKLOG columns. Use for lightweight card management without the full engineering workflow."
trigger: /{{PREFIX}}-trello
---

# /{{PREFIX}}-trello

Retrieve the next card from a Trello column, or add a new card to one.

## Usage

```
/{{PREFIX}}-trello bugs           # retrieve top BUGS card → move to DOING
/{{PREFIX}}-trello techdebt       # retrieve top TECH DEBT card → move to DOING
/{{PREFIX}}-trello backlog        # retrieve top BACKLOG card → move to DOING (no workflow)
/{{PREFIX}}-trello add bugs       # create a new card in BUGS
/{{PREFIX}}-trello add techdebt   # create a new card in TECH DEBT
/{{PREFIX}}-trello add backlog    # create a new card in BACKLOG
/{{PREFIX}}-trello                # → prompts for column
```

> **Note:** To start the full engineering workflow from a BACKLOG card, use `/{{PREFIX}}-backlog` instead.

---

## Ambiguity Rule

If the column is not specified (e.g. bare `/{{PREFIX}}-trello` or `/{{PREFIX}}-trello add`), respond with exactly:

> "This skill supports 3 columns: BUGS, TECH DEBT, and BACKLOG. Which column did you mean?"

Do NOT fall back to a default column silently. Wait for the user's answer before proceeding.

---

## Retrieve Workflow

When retrieving (`/{{PREFIX}}-trello <column>`):

1. Fetch cards from the specified column list (see Trello Config below).
2. **Ignore** any card named "Bug Template" or "Feature Template".
3. Pick the first card (top = highest priority).
4. Move the card to **DOING** (`{{TRELLO_LIST_DOING}}`) and assign yourself.
5. Present the card name, description, and URL to the user.
6. Stop — do not begin an engineering workflow unless the user asks.

---

## Add Workflow

When adding (`/{{PREFIX}}-trello add <column>`):

1. Ask the user for a card title if not provided.
2. Create the card in the specified column list using this description template:

```markdown
### Goal:

### User Story:

### Implementation Notes:
```

3. Create two checklists on the card: **"Acceptance Criteria"** and **"Test Plan"**.
4. Present the new card URL to the user.

---

## Trello Config

| Column    | List ID                      | Excluded Templates          |
|-----------|------------------------------|-----------------------------|
| BUGS      | `{{TRELLO_LIST_BUGS}}`       | "Bug Template"              |
| TECH DEBT | `{{TRELLO_LIST_TECHDEBT}}`   | "Feature Template"          |
| BACKLOG   | `{{TRELLO_LIST_BACKLOG}}`    | "Feature Template"          |
| DOING     | `{{TRELLO_LIST_DOING}}`      | —                           |

- Board ID: `{{TRELLO_BOARD_ID}}`
- MCP server: `trello` (defined in `.agents/mcp/trello.json`)
---
