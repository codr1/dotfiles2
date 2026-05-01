#!/bin/bash
#
# Append a `~/.bashrc.d/*.sh` source loop to ~/.bashrc, once.
# Idempotent via a marker comment — re-running will not duplicate.
# Lets dotfiles2 manage shell config without taking over the whole .bashrc.

set -euo pipefail

MARKER='# >>> dotfiles2 bashrc.d include >>>'
BASHRC="$HOME/.bashrc"

if [[ -f "$BASHRC" ]] && grep -qF "$MARKER" "$BASHRC"; then
  exit 0
fi

cat >> "$BASHRC" <<'EOF'

# >>> dotfiles2 bashrc.d include >>>
# Source per-feature snippets installed by chezmoi.
# Edit ~/.bashrc.d/*.sh to customize, or add your own files there.
if [[ -d "$HOME/.bashrc.d" ]]; then
  for _f in "$HOME"/.bashrc.d/*.sh; do
    [[ -r "$_f" ]] && . "$_f"
  done
  unset _f
fi
# <<< dotfiles2 bashrc.d include <<<
EOF
