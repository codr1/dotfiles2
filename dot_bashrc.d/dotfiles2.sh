# Managed by chezmoi (dotfiles2)
# This snippet is sourced from ~/.bashrc via the bashrc.d include loop.

# Add ~/.local/bin to PATH if present and not already on PATH
if [[ -d $HOME/.local/bin && ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
  PATH="$HOME/.local/bin:$PATH"
fi

# Initialize starship prompt if installed
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init bash)"
fi
