---
name: djaunt-overseer
repo: tory37/djaunt-overseer
platforms: darwin linux
kind: vsix
requires: gh
requires-hint: see tools/README.md, section Bootstrap CLI tools (gh)
vsix-extension: djaunt.djaunt-overseer
vsix-asset: *.vsix
---

# djaunt-overseer

Vertical tabs for Claude CLI sessions in VS Code. Sessions stay real terminals. It also shows the Jira tickets and PRs each session worked on (see the `overseer:track` skill).

## What sync does

1. Clones `tory37/djaunt-overseer` to `~/src/djaunt-overseer`. Fast-forwards it if it exists.
2. Reads the latest GitHub release tag.
3. Finds the VS Code CLI (`code` on PATH, or the one inside the app). Compares the installed version of `djaunt.djaunt-overseer` to that tag. It downloads the `.vsix` and installs it only when they differ.

Reload the editor window after an update.

## Uninstall

`code --uninstall-extension djaunt.djaunt-overseer`.
