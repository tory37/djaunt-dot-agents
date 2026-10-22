# tools/

Everything this setup depends on that lives outside this repo. One file per companion repo. `scripts/sync.sh` reads these files and installs from them. To add, change, or drop a dependency, edit `tools/`. Never edit `sync.sh` for it.

## Companion repos (installed by sync)

| File | Repo | What it is | Platforms |
|---|---|---|---|
| [`djt-hub.md`](djt-hub.md) | `tory37/djaunt-agent-hubs` | Live browser pages for agent processes | macOS, Linux |
| [`djaunt-overseer.md`](djaunt-overseer.md) | `tory37/djaunt-overseer` | Session tabs for Claude CLI in VS Code | macOS, Linux |
| [`djaunt-branding.md`](djaunt-branding.md) | `tory37/djaunt-branding` | Brand assets and editor and terminal themes | macOS, Linux |
| [`djaunt-memguard.md`](djaunt-memguard.md) | `tory37/djaunt-memguard` | Memory pressure guard | macOS |

## How sync reads a tool file

Each file starts with a `---` frontmatter block of `key: value` lines. Sync reads that block. Everything after it is documentation for humans.

Sync clones the repo to `$DJAUNT_SRC_DIR/<repo name>` (default `~/src`). It fast-forwards the clone if it exists, and uses it as is if it has local changes. It never aborts the whole sync: a failing tool logs a warning and sync moves on.

| Key | Required | Meaning |
|---|---|---|
| `name` | yes | Tool name. Also the stamp name. |
| `repo` | yes | GitHub `owner/name`. |
| `platforms` | yes | Space-separated `uname -s` values, lowercase: `darwin`, `linux`. Sync skips the tool elsewhere, including Windows. |
| `kind` | yes | `command` runs `install` lines. `vsix` installs the latest release as an editor extension. |
| `dir-env` | no | Env var that overrides the clone directory. |
| `requires` | no | A command that must be on PATH to install. |
| `requires-hint` | no | Shown when `requires` is missing. |
| `check` | no | A shell command, run in the repo. Exit 0 means the tool is still installed. Without it, the stamp alone decides. |
| `install` | `command` | A shell command, run in the repo. Repeat the key for several. They run in order and stop at the first failure. |
| `note` | no | Printed after a successful install. |
| `agent-doc-cmd` | no | A shell command whose output is the agent guide. |
| `agent-doc-fallback` | no | A repo-relative file to copy when `agent-doc-cmd` fails. |
| `agent-doc-dest` | no | Destination under `~/.agents/`. Needed with the two keys above. |
| `vsix-extension` | `vsix` | Extension ID. |
| `vsix-asset` | `vsix` | Release asset glob. |

**Up to date** means the repo HEAD equals the stamp in `~/.local/share/djaunt-dot-agents/<name>-rev` and `check` passes. Sync reinstalls when either fails. A `vsix` tool compares the installed version to the latest release tag instead.

Values stay on one line. Do not add inline comments.

### Add a tool

1. Write `tools/<name>.md` with the keys above.
2. Add a row to the table in this README.
3. Run `bash scripts/sync.sh`.

## Bootstrap CLI tools (not installed by sync)

> **Agent instructions:** Before installing tools, detect what package managers are available on this system and research what's currently the best-practice package manager for this OS. If the best one isn't installed, ask the user if they'd like to install it first (then use it for the rest); if not, use whatever is available. For each tool below, install via package manager using the repo/homepage links to identify the correct package name. If a tool is unavailable or unsupported on this platform, skip it and move on — do not abort. For GitHub release binaries, download and install the latest release for the current platform's architecture.

### Shell utilities

> On older macOS, Homebrew may lack bottles (prebuilt binaries) for Rust-based tools (`ripgrep`, `bat`, `fd`, `eza`) and compile Rust and LLVM from source. Install with `brew install --force-bottle <pkg>` so a missing bottle fails fast, then skip the tool or fetch its GitHub release binary.

- **tree** — directory tree printer | <https://github.com/Old-Man-Programmer/tree>
- **jq** — JSON processor. Sync needs it to merge `~/.claude/settings.json`. | <https://github.com/jqlang/jq>
- **fzf** — fuzzy finder | <https://github.com/junegunn/fzf>
- **ripgrep** (`rg`) — fast grep | <https://github.com/BurntSushi/ripgrep>
- **bat** — `cat` with syntax highlighting | <https://github.com/sharkdp/bat>
- **fd** — fast `find` | <https://github.com/sharkdp/fd>
- **eza** — modern `ls` | <https://github.com/eza-community/eza>

### Git and dev

- **gh** — GitHub CLI. Sync needs it to clone the companion repos and read overseer releases. | <https://github.com/cli/cli>
- **direnv** — per-directory env vars | <https://github.com/direnv/direnv>
- **code** — VS Code editor | <https://code.visualstudio.com>
- **bun** — JavaScript runtime. `djt-hub` needs it. | <https://bun.sh>
  - Install with `brew install oven-sh/bun/bun` or the official script (`curl -fsSL https://bun.sh/install | bash`), **not** plain `brew install bun`. On macOS versions Homebrew no longer supports (Tier 3), homebrew-core has no bottles for bun's dependencies and compiles them from source, including LLVM, which takes hours.

### AI tooling

- **claude** — Claude Code CLI | <https://github.com/anthropics/claude-code> (npm: @anthropic-ai/claude-code)
- **gemini** — Gemini CLI | <https://github.com/google-gemini/gemini-cli> (npm: @google/gemini-cli)

### Other

- **overseer-native** | <https://github.com/tory37/overseer-native> (latest release when written: v0.23.0). Not installed by sync. Unverified: `sync.sh` installs `djaunt-overseer`, a different repo. Delete this line if `overseer-native` is retired.
