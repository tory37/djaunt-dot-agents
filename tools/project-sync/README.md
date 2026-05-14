# Project Sync Tool

This tool installs project-level synchronization scripts that help maintain agent context across different AI tools (Gemini CLI, Claude Code).

## Features

1.  **Claude Code Wiring**: Recursively finds `AGENTS.md` files and creates `CLAUDE.md` symlinks so Claude Code can use local context.
2.  **Local Claude Config**: Sets up a `.claude` directory within the project that mimics the global structure, linking project-specific skills and context.
3.  **Gemini Skill Linking**: Automatically links skills found in `.agents/skills` to the Gemini CLI's **workspace scope**, ensuring they are only active in this project.

## Installation

Run the installer from this directory:

```bash
./install.sh --target /path/to/your/project
```

## Usage

In your project root, run:

```bash
bash .agents/scripts/sync.sh
```

This should be run:
- After first installation.
- After adding new `AGENTS.md` files.
- After adding or updating Gemini skills in `.agents/skills`.
