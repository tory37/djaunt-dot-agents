# Optional Embedded Tools

This directory contains optional tools and skills that can be "embedded" into a project's `.agents` directory. This allows for project-specific extensions that are tailored to the team's workflow but generic enough to be shared across multiple repositories.

## Available Tools

### Trello Toolset

A set of skills and MCP configuration to manage Trello cards (Bugs, Tech Debt, Backlog, Doing) directly from the Gemini CLI.

- **`trello` skill**: Lightweight card management (list cards, move to doing, add new cards).

### Project Sync Tool

A set of scripts to synchronize agent context (AGENTS.md -> CLAUDE.md), local Claude configuration, and workspace-scoped Gemini skills.

- **`sync.sh`**: The main synchronization script.
- **`wire-claude.sh`**: Recursively links AGENTS.md to CLAUDE.md.

## Installation

Each tool provides an `install.sh` script to deploy it into a target project.

### Example: Installing Trello

1. Navigate to the tool directory:

   ```bash
   cd tools/djt-trello
   ```

2. Run the installer:

   ```bash
   ./install.sh --target /path/to/your/project
   ```

3. Follow the prompts for your Trello API Key, Token, and List IDs.

4. Follow the post-installation steps printed by the script (e.g., updating your `.env` file).

## Contributing

To add a new tool:

1. Create a subdirectory under `tools/`.
2. Provide a `template/` folder with genericized files.
3. Provide an `install.sh` that handles deployment and prefixing.
