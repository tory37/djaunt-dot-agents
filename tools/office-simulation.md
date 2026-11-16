---
name: office-simulation
repo: tory37/vscode-office-simulation
platforms: darwin linux windows
kind: vsix
requires: gh
requires-hint: see tools/README.md, section Bootstrap CLI tools (gh)
vsix-extension: djaunt.office-simulation
vsix-asset: *.vsix
---

# office-simulation

A pixel-guy office view for VS Code. djaunt-overseer's Office view draws from it.

## What sync does

1. Clones `tory37/vscode-office-simulation` to `~/src/vscode-office-simulation`. Fast-forwards it if it exists.
2. Reads the latest GitHub release tag.
3. Finds the VS Code CLI (`code` on PATH, or the one inside the app). Compares the installed version of `djaunt.office-simulation` to that tag. It downloads the `.vsix` and installs it only when they differ.

Reload the editor window after an update.

## Uninstall

`code --uninstall-extension djaunt.office-simulation`.
