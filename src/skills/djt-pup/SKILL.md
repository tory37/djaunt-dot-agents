---
name: djt-pup
description: "Upgrade a prompt for a future session so it is optimized for AI understanding. Accepts any form: inline text, a file path, a URL, or a ticket reference."
trigger: /djt-pup
---

# /djt-pup

Upgrade a prompt so it is clear, complete, and optimized for an AI agent picking it up in a future session with zero prior context.

## Usage

```
/djt-pup "do the thing with the widget"        # inline prompt text
/djt-pup @path/to/prompt.md                    # file containing the prompt
/djt-pup https://...                           # URL to a document with the prompt
/djt-pup TICKET-123                            # ticket ID or reference
```

## Steps

### 1. Ingest the Input

Determine what form the argument takes and read the source content:

- **Inline text** — use it directly as the raw prompt.
- **File path** (`@...` or a path string) — read the file.
- **URL** — fetch the page and extract the relevant text.
- **Ticket reference** (any ID-like string, e.g. `ABC-123`, `#42`) — look it up via available tools and read the title, description, and any acceptance criteria.
- **Missing or unreadable** — respond with:
  > "I couldn't find or read the prompt source you provided. Please paste the prompt text directly, share a readable file path, a reachable URL, or a valid ticket reference."
  > Then stop and wait.

### 2. Analyze the Raw Prompt

Identify weaknesses that would confuse a future agent with no context:

- Vague pronouns or implicit references ("it", "the thing", "as before")
- Missing scope — what repo, service, file, or system is involved?
- Missing goal — what is the desired end state?
- Missing constraints — tech stack, style rules, access limits, out-of-scope areas
- Assumed knowledge — internal terms, prior decisions, or context not in the text
- Ambiguous success criteria — how will the agent know it is done?

### 3. Ask Clarifying Questions (if needed)

If the analysis reveals gaps, ask all clarifying questions in a **single message**. Be specific — reference the exact phrase or gap that prompted each question. Do not ask one question at a time.

Wait for the user's answers before proceeding to Step 4.

If the prompt is already clear and complete, skip this step and proceed directly.

### 4. Write the Upgraded Prompt

Produce an upgraded version of the prompt with the following qualities:

- **Self-contained** — a future agent with no memory of this conversation can execute it without asking follow-up questions.
- **Goal-first** — open with what needs to be accomplished and why.
- **Scoped** — name specific files, services, repos, or areas of the system when known.
- **Constrained** — state what is out of scope or must not change.
- **Verifiable** — include a clear success condition or acceptance criteria.
- **Concise** — no filler. Every sentence earns its place.

Format the output as a fenced code block so it can be copied cleanly.

### 5. Confirm or Iterate

After presenting the upgraded prompt, ask the user:

> "Does this capture the intent correctly, or should I adjust anything?"

Apply any corrections and re-present until the user approves. Then stop.
