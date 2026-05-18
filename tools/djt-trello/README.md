# Trello Toolset for .agents

A set of genericized Trello skills and MCP configuration to manage BUGS, TECH DEBT, and BACKLOG cards directly from the Gemini CLI.

## Step 0: Get your Trello IDs

Before installing, you need a few things from Trello. It's easiest to do this in a browser.

1. **API Key & Token**: Get them from [Trello Power-Up Admin Central](https://trello.com/power-ups/admin).
    - **API Key**: This is listed clearly on the page.
    - **Token**: Click the **"Token"** link (or "generate a token manually") next to your API Key. Follow the prompts to authorize and copy the long string.
    - **⚠️ Note on "Secret"**: You will also see an "API Secret" on that page. **Do NOT use the Secret.** The MCP server needs the **Token**, not the Secret.
2. **Board ID**: Open your board. The ID is the 8-character string in the URL (e.g., `https://trello.com/b/abcd1234/my-board` → `abcd1234`).
3. **List IDs**: This is the "secret" part:
    - Add `.json` to the end of your board URL (e.g., `https://trello.com/b/abcd1234.json`).
    - Open that page. It's messy, but don't panic.
    - Press `Ctrl+F` (or `Cmd+F`) and search for the name of your list (e.g., "Bugs").
    - Look for the `"id":` value right before the name. It looks like a long string of random characters: `"id":"6646...","name":"Bugs"`.
    - Repeat for your **Bugs**, **Tech Debt**, **Backlog**, and **Doing** lists.

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

If you don't provide these as flags, the script will prompt you for them.

## Post-Installation

1. **MCP Registration**: Ensure your Gemini CLI configuration includes the `trello` server. See the `README.trello.md` file created in your project's `.agents/skills/` directory for the exact snippet.
2. **Try it out**: Run `/<prefix>-trello` (e.g., `/djt-trello`) to verify.
