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

---

## Ambiguity Rule

If the column is not specified (e.g. bare `/{{PREFIX}}-trello` or `/{{PREFIX}}-trello add`), respond with exactly:

> "This skill supports 3 columns: BUGS, TECH DEBT, and BACKLOG. Which column did you mean?"

Do NOT fall back to a default column silently. Wait for the user's answer before proceeding.

---

## Retrieve Workflow

When retrieving (`/{{PREFIX}}-trello <column>`):

1. Fetch **all** cards from the specified column list (see Trello Config below).
2. **Filter** out any card named "Bug Template" or "Feature Template".
3. Present the list of available cards to the user with their names and (brief) descriptions.
4. **Ask the user to pick which card they want to start.**
5. Once the user selects a card:
   - Move the card to **DOING** (`{{TRELLO_LIST_DOING}}`) and assign yourself.
   - Present the full card name, description, and URL to the user.
   - Stop — do not begin an engineering workflow unless the user asks.

---

## Add Workflow

When adding (`/{{PREFIX}}-trello add <column> [@path/to/template.md]`):

- If a filled template file is provided via `@path`, read it and use its fields to populate the card.
- If no file is provided, prompt the user for each field in the order it appears in the template below.

### Bug cards (`add bugs`)

Template schema:

{{BUG_TEMPLATE}}

**Mapping to Trello:**

- **Card name** ← Summary
- **Description** ← Expected Behavior + Actual Behavior + Environment + Error Output + Related Tickets/Links
- **Checklist "Steps to Reproduce"** ← each numbered step as a checklist item
- **Checklist "Affected Files"** ← each file or component as a checklist item

### Feature / Tech Debt / Backlog cards (`add techdebt`, `add backlog`)

Template schema:

{{FEATURE_TEMPLATE}}

**Mapping to Trello:**

- **Card name** ← Feature Name
- **Description** ← Goal + User Story + Scope (In/Out) + Constraints & Non-Goals + Related Tickets/Links
- **Checklist "Acceptance Criteria"** ← each checkbox item as a checklist item
- **Checklist "Test Plan"** ← empty (filled during implementation)

After creating the card, present the URL to the user.

---

## Trello Config

| Column    | List ID                    | Excluded Templates |
| --------- | -------------------------- | ------------------ |
| BUGS      | `{{TRELLO_LIST_BUGS}}`     | "Bug Template"     |
| TECH DEBT | `{{TRELLO_LIST_TECHDEBT}}` | "Feature Template" |
| BACKLOG   | `{{TRELLO_LIST_BACKLOG}}`  | "Feature Template" |
| DOING     | `{{TRELLO_LIST_DOING}}`    | —                  |

- Board ID: `{{TRELLO_BOARD_ID}}`
- MCP server: `trello` (defined in `.agents/mcp/trello.json`)

---
