#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

usage() {
  echo "Usage: $0 [--local | --remote]"
  echo ""
  echo "  --local   Full install: Homebrew packages, Ghostty, font, zimfw, symlinks"
  echo "  --remote  Minimal install: starship binary, zimfw, symlinks (no GUI apps)"
  echo ""
  echo "If no flag is given, you will be prompted."
  exit 1
}

MODE=""
if [[ ${1:-} == "--local" ]]; then
  MODE="local"
elif [[ ${1:-} == "--remote" ]]; then
  MODE="remote"
elif [[ ${1:-} == "--help" || ${1:-} == "-h" ]]; then
  usage
elif [[ -n ${1:-} ]]; then
  echo "Unknown option: $1"
  usage
fi

if [[ -z "$MODE" ]]; then
  echo "=== Dotfiles installer ==="
  echo ""
  echo "  1) Local  — full install (Homebrew, Ghostty, font, CLI tools)"
  echo "  2) Remote — minimal install (starship binary, zimfw, symlinks only)"
  echo ""
  read -rp "Choose [1/2]: " choice
  case "$choice" in
    1) MODE="local" ;;
    2) MODE="remote" ;;
    *) echo "Invalid choice."; exit 1 ;;
  esac
fi

echo ""
echo "=== Running ${MODE} install ==="

# --- Install packages ---
if [[ "$MODE" == "local" ]]; then
  if command -v brew &>/dev/null; then
    echo "Installing Homebrew packages..."
    brew install eza bat fd fzf zoxide ripgrep starship
    echo "Installing Ghostty and Nerd Font..."
    brew install --cask ghostty font-jetbrains-mono-nerd-font
  else
    echo "ERROR: Homebrew not found. Install it first: https://brew.sh"
    exit 1
  fi
elif [[ "$MODE" == "remote" ]]; then
  # Install zsh if not present
  if ! command -v zsh &>/dev/null; then
    echo "Installing zsh..."
    if command -v apt-get &>/dev/null; then
      sudo apt-get update -qq
      sudo apt-get install -y -qq zsh
    else
      echo "ERROR: zsh not found and no supported package manager to install it."
      exit 1
    fi
  fi

  # Set zsh as default shell if it isn't already
  if [[ "$(basename "$SHELL")" != "zsh" ]]; then
    echo "Setting zsh as default shell..."
    chsh -s "$(command -v zsh)"
  fi

  # Install starship if not present
  if ! command -v starship &>/dev/null; then
    echo "Installing starship..."
    curl -sS https://starship.rs/install.sh | sh -s -- --yes
  else
    echo "starship already installed."
  fi

  # Install CLI tools if a package manager is available
  if command -v apt-get &>/dev/null; then
    echo "Installing CLI tools via apt..."
    sudo apt-get install -y -qq fzf ripgrep fd-find bat zoxide
    # fd and bat have different binary names on Debian/Ubuntu
    [[ ! -e /usr/local/bin/fd ]] && sudo ln -sf "$(command -v fdfind)" /usr/local/bin/fd 2>/dev/null || true
    [[ ! -e /usr/local/bin/bat ]] && sudo ln -sf "$(command -v batcat)" /usr/local/bin/bat 2>/dev/null || true
    # eza requires its own repo on Debian/Ubuntu
    if ! command -v eza &>/dev/null; then
      echo "Installing eza..."
      sudo mkdir -p /etc/apt/keyrings
      curl -fsSL https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg 2>/dev/null
      echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list >/dev/null
      sudo apt-get update -qq
      sudo apt-get install -y -qq eza
    fi
  elif command -v brew &>/dev/null; then
    echo "Installing CLI tools via Homebrew..."
    brew install eza bat fd fzf zoxide ripgrep starship
  else
    echo "NOTE: No supported package manager found (apt/brew)."
    echo "Please install manually: fzf, ripgrep, fd, bat, zoxide, eza"
  fi
fi

# --- Install zimfw ---
ZIM_HOME=~/.zim
if [[ ! -e ${ZIM_HOME}/zimfw.zsh ]]; then
  echo "Installing zimfw..."
  mkdir -p "${ZIM_HOME}"
  curl -fsSL -o "${ZIM_HOME}/zimfw.zsh" \
    https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
fi

# --- Install bat theme ---
BAT_CMD=""
command -v bat &>/dev/null && BAT_CMD="bat"
command -v batcat &>/dev/null && BAT_CMD="batcat"
if [[ -n "$BAT_CMD" ]]; then
  echo "Installing bat theme..."
  BAT_CONFIG_DIR="$($BAT_CMD --config-dir)"
  mkdir -p "${BAT_CONFIG_DIR}/themes"
  cp "${DOTFILES_DIR}/bat/themes/Catppuccin-Mocha.tmTheme" "${BAT_CONFIG_DIR}/themes/"
  $BAT_CMD cache --build
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

mkdir -p ~/.config
link "${DOTFILES_DIR}/starship.toml" ~/.config/starship.toml

if [[ "$MODE" == "local" ]]; then
  mkdir -p ~/.local/bin
  link "${DOTFILES_DIR}/scripts/keychain-passwords.sh" ~/.local/bin/keychain-passwords
  mkdir -p ~/.config/ghostty
  link "${DOTFILES_DIR}/ghostty/config" ~/.config/ghostty/config
fi

# --- Install zim modules ---
echo "Installing zim modules..."
TERM=xterm-256color zsh -ic 'zimfw install' 2>/dev/null || true

echo ""
echo "=== Done! Restart your terminal or run 'exec zsh' to apply changes. ==="
