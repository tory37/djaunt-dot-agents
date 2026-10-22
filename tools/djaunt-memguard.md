---
name: djaunt-memguard
repo: tory37/djaunt-memguard
platforms: darwin
kind: command
requires: swiftc
requires-hint: run xcode-select --install, then re-run sync
check: launchctl list | grep -q com.djaunt.memguard
install: mac/bin/djt-memguard install
note: passwordless purge is opt-in: djt-memguard install-sudoers
---

# djaunt-memguard

Early warning and safe relief for memory exhaustion on macOS. It warns before the "your system has run out of application memory" dialog appears. It runs as a launch agent with a CLI and a menu bar app.

## What sync does

1. Clones `tory37/djaunt-memguard` to `~/src/djaunt-memguard`. Fast-forwards it if it exists.
2. Runs `mac/bin/djt-memguard install` when the repo's HEAD changed or the launch agent `com.djaunt.memguard` is not loaded. Needs `swiftc` (Xcode command line tools).
3. Skips on Linux. Only the `mac/` folder exists.

## Opt-in

Passwordless memory purge needs a sudoers rule. Sync does not add it. Run `djt-memguard install-sudoers` yourself.

## Uninstall

Run the repo's `mac/bin/djt-memguard` with its uninstall command. Read `djt-memguard --help` for the name.
