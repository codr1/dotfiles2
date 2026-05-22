#!/usr/bin/env bash
#
# run_once_after_install-tmux-plugins.sh
#
# Bootstrap TPM-managed tmux plugins on a fresh machine. The tmux config and
# TPM itself are cloned by .chezmoiexternal.toml; this installs the plugins
# declared in tmux.conf (tmux-sensible, tmux-cpu, ...).
#
# Runs once per machine. To add/update plugins later, edit tmux.conf and press
# <prefix> + I inside tmux (the normal TPM workflow) — no chezmoi run needed.

set -euo pipefail

TPM_DIR="$HOME/.config/tmux/plugins/tpm"

if ! command -v tmux >/dev/null 2>&1; then
  echo "tmux not installed — skipping plugin bootstrap."
  exit 0
fi

if [[ ! -x "$TPM_DIR/bin/install_plugins" ]]; then
  echo "TPM not found at $TPM_DIR — skipping plugin bootstrap."
  echo "Run 'chezmoi apply' again once the external repos have cloned."
  exit 0
fi

echo "Installing tmux plugins via TPM..."
# install_plugins reads the @plugin list from a running server, so ensure one
# exists. start-server is a no-op if a server is already up; we never kill it,
# to avoid taking down a live tmux session.
tmux start-server
"$TPM_DIR/bin/install_plugins"
echo "tmux plugins installed."
