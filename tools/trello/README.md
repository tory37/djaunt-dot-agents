# Trello Toolset for .agents

A set of genericized Trello skills and MCP configuration to manage BUGS, TECH DEBT, and BACKLOG cards directly from the Gemini CLI.

## Included Skills

- **Trello (`djt-trello`)**: Lightweight card management. List cards in a column, move them to DOING, or add new cards with standard templates and checklists.

## Installation

Run the following command from this directory. Replace the placeholders with your actual Trello information.

### Copy & Paste Installation

```bash
./install.sh \
  --target "../../" \
  --prefix "djt" \
  --api-key "YOUR_API_KEY" \
  --token "YOUR_TOKEN" \
  --board "YOUR_BOARD_ID" \
  --list-bugs "YOUR_BUGS_LIST_ID" \
  --list-tech "YOUR_TECH_DEBT_LIST_ID" \
  --list-backlog "YOUR_BACKLOG_LIST_ID" \
  --list-doing "YOUR_DOING_LIST_ID"
```

## Post-Installation

1. **Environment Variables**: The installer creates `.env.trello.example` in your target directory. Copy its contents into your project's `.env` file.
2. **MCP Registration**: Ensure your Gemini CLI configuration includes the `trello` server pointing to `.agents/mcp/trello.json`.
3. **Try it out**: Run `/<prefix>-trello` (e.g., `/djt-trello`) to verify.

## Finding IDs

- **API Key & Token**: Get them from [Trello Power-Up Admin Central](https://trello.com/power-ups/admin).
- **Board/List IDs**: You can find these by adding `.json` to any Trello board URL or using the Trello API.
