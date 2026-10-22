---
name: djt-hub
repo: tory37/djaunt-agent-hubs
dir-env: DJT_HUB_REPO
platforms: darwin linux
kind: command
requires: bun
requires-hint: see tools/README.md, section Bootstrap CLI tools (bun)
check: test -x "$HOME/.local/bin/djt-hub"
install: bash install.sh
agent-doc-cmd: "$HOME/.local/bin/djt-hub" docs
agent-doc-fallback: docs/agent-guide.md
agent-doc-dest: assets/djt-hub.md
---

# djt-hub

Live browser pages for multi-step processes the user must watch or approve: releases, migrations, backfills. The agent writes the page as one React file. `djt-hub up <hub>` serves it. Nothing runs in the background.

## What sync does

1. Clones `tory37/djaunt-agent-hubs` to `~/src/djaunt-agent-hubs`. Set `DJT_HUB_REPO` to use another path. Fast-forwards it if it exists.
2. Runs `bash install.sh` in the repo when its HEAD changed or `~/.local/bin/djt-hub` is missing. Needs `bun`.
3. Writes the agent guide to `~/.agents/assets/djt-hub.md`. It uses `djt-hub docs`, or copies `docs/agent-guide.md` if the binary is missing. `AGENTS.md` tells agents to read that file before using hubs.

## Use

```
djt-hub up <hub>
```

## Uninstall

Delete `~/.local/bin/djt-hub` and `~/.local/share/djt-hub/`.
