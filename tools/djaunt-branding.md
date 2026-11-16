---
name: djaunt-branding
repo: tory37/djaunt-branding
platforms: darwin linux windows
kind: command
install: bash vscode-theme/tools/sync-local.sh
install: bash terminal-theme/tools/sync-local.sh
install-windows: for d in "$HOME/.vscode/extensions" "$HOME/.cursor/extensions"; do [ -d "$d" ] || continue; link="$d/djaunt-themes"; if [ -e "$link" ]; then rmdir "$link" 2>/dev/null || { echo "skip: $link exists and is not a junction"; continue; }; fi; powershell.exe -NonInteractive -Command "New-Item -ItemType Junction -Path '$(cygpath -w "$link")' -Target '$(cygpath -w "$PWD/vscode-theme")'" >/dev/null && echo "linked: $link"; done
---

# djaunt-branding

Single source of truth for the Djaunt identity: logos, fonts, tokens, and editor and terminal themes. Agents read its `BRANDING.md` first when building anything branded.

## What sync does

1. Clones `tory37/djaunt-branding` to `~/src/djaunt-branding`. Fast-forwards it if it exists.
2. When the repo's HEAD changed, runs two installers in the repo:
   - `vscode-theme/tools/sync-local.sh` links the VS Code themes. Reload editor windows to pick them up.
   - `terminal-theme/tools/sync-local.sh` imports the iTerm themes. Pick one in iTerm2, Profiles, Colors, Color Presets.

## Uninstall

Remove the theme links the installers created. Read the installer scripts in the repo for the exact paths.
