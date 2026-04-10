#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== Dotfiles installer ==="

# --- Install Homebrew packages ---
if command -v brew &>/dev/null; then
  echo "Installing Homebrew packages..."
  brew install eza bat fd fzf zoxide ripgrep starship
  brew install --cask ghostty
else
  echo "WARNING: Homebrew not found. Install it first: https://brew.sh"
  echo "Skipping package installation."
fi

# --- Install zimfw ---
ZIM_HOME=~/.zim
if [[ ! -e ${ZIM_HOME}/zimfw.zsh ]]; then
  echo "Installing zimfw..."
  mkdir -p "${ZIM_HOME}"
  curl -fsSL -o "${ZIM_HOME}/zimfw.zsh" \
    https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
fi

# --- Symlink dotfiles ---
echo "Creating symlinks..."

link() {
  local src="$1" dst="$2"
  if [[ -e "$dst" && ! -L "$dst" ]]; then
    echo "  Backing up existing $dst -> ${dst}.bak"
    mv "$dst" "${dst}.bak"
  fi
  ln -sf "$src" "$dst"
  echo "  $dst -> $src"
}

link "${DOTFILES_DIR}/zshrc"         ~/.zshrc
link "${DOTFILES_DIR}/zimrc"         ~/.zimrc

mkdir -p ~/.config/ghostty
link "${DOTFILES_DIR}/ghostty/config" ~/.config/ghostty/config

mkdir -p ~/.config
link "${DOTFILES_DIR}/starship.toml" ~/.config/starship.toml

# --- Install zim modules ---
echo "Installing zim modules..."
zsh -ic 'zimfw install' 2>/dev/null

echo ""
echo "=== Done! Restart your terminal to apply changes. ==="
