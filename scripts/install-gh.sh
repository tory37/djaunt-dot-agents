#!/usr/bin/env bash
# install-gh.sh — Install the GitHub CLI (gh) on Linux.
# sync.sh runs it through the gh.linux recipe in tools/prerequisites.txt.
# Tries the distro package manager first, then Homebrew, then the release tarball into ~/.local/bin.
# The tarball path needs no root, so it also covers immutable systems such as SteamOS.

set -uo pipefail

# install_with_apt — the official GitHub CLI apt repo (https://github.com/cli/cli/blob/trunk/docs/install_linux.md)
install_with_apt() {
    local keyring=/etc/apt/keyrings/githubcli-archive-keyring.gpg
    sudo mkdir -p -m 755 /etc/apt/keyrings \
        && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee "$keyring" >/dev/null \
        && sudo chmod go+r "$keyring" \
        && echo "deb [arch=$(dpkg --print-architecture) signed-by=$keyring] https://cli.github.com/packages stable main" \
            | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null \
        && sudo apt-get update \
        && sudo apt-get install -y gh
}

# install_with_zypper — the official GitHub CLI rpm repo
install_with_zypper() {
    sudo zypper --non-interactive addrepo --refresh https://cli.github.com/packages/rpm/gh-cli.repo 2>/dev/null
    sudo zypper --non-interactive --gpg-auto-import-keys install gh
}

# cannot_use_system_packages — SteamOS has a read-only root that updates wipe. Without sudo, no distro installs either.
cannot_use_system_packages() {
    command -v steamos-readonly >/dev/null 2>&1 || ! command -v sudo >/dev/null 2>&1
}

# install_from_release — latest release tarball, gh binary copied to ~/.local/bin
install_from_release() {
    local arch version tmp_dir
    case "$(uname -m)" in
        x86_64)        arch=amd64 ;;
        aarch64|arm64) arch=arm64 ;;
        armv6l|armv7l) arch=armv6 ;;
        i386|i686)     arch=386 ;;
        *) echo "No gh release for $(uname -m)" >&2; return 1 ;;
    esac
    version="$(curl -fsSL https://api.github.com/repos/cli/cli/releases/latest \
        | sed -n 's/.*"tag_name": *"v\([^"]*\)".*/\1/p' | head -n 1)"
    [ -n "$version" ] || { echo "Could not read the latest gh release" >&2; return 1; }
    tmp_dir="$(mktemp -d)"
    curl -fsSL "https://github.com/cli/cli/releases/download/v$version/gh_${version}_linux_$arch.tar.gz" \
        | tar -xz -C "$tmp_dir" \
        && mkdir -p "$HOME/.local/bin" \
        && install -m 755 "$tmp_dir/gh_${version}_linux_$arch/bin/gh" "$HOME/.local/bin/gh"
    local status=$?
    rm -rf "$tmp_dir"
    [ $status -eq 0 ] && echo "Installed gh $version to ~/.local/bin/gh"
    return $status
}

if ! cannot_use_system_packages; then
    if command -v apt-get >/dev/null 2>&1; then install_with_apt && exit 0
    elif command -v dnf >/dev/null 2>&1; then sudo dnf install -y gh && exit 0
    elif command -v zypper >/dev/null 2>&1; then install_with_zypper && exit 0
    elif command -v pacman >/dev/null 2>&1; then sudo pacman -S --noconfirm github-cli && exit 0
    fi
fi
if command -v brew >/dev/null 2>&1; then brew install gh && exit 0; fi
install_from_release
