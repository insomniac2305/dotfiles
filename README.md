# dotfiles

Personal terminal configuration with zsh, Starship prompt, and Ghostty.

## What's included

| File | Purpose |
|---|---|
| `zshrc` | Zsh config — history, NVM lazy-loading, aliases, plugin settings |
| `zimrc` | [zimfw](https://zimfw.sh/) plugin list |
| `starship.toml` | [Starship](https://starship.rs/) prompt — Catppuccin Mocha powerline theme |
| `ghostty/config` | [Ghostty](https://ghostty.org/) terminal settings |
| `install.sh` | Bootstrap script for local or remote machines |

## Shell setup

- **Framework:** zimfw (lightweight zsh plugin manager)
- **Prompt:** Starship with Catppuccin Mocha palette and connected powerline segments
- **Font:** JetBrainsMono Nerd Font

### Plugins

- zsh-autosuggestions, zsh-syntax-highlighting, zsh-completions
- zsh-history-substring-search, zsh-you-should-use, zsh-autopair
- fzf-tab

### CLI tools

- **eza** (ls), **bat** (cat), **fd** (find), **ripgrep** (grep)
- **fzf** (fuzzy finder), **zoxide** (smart cd)

## Install

```bash
git clone https://github.com/insomniac2305/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

The script has two modes:

- `--local` — Full install with Homebrew packages, Ghostty, and Nerd Font
- `--remote` — Minimal install with Starship binary, CLI tools via apt, and symlinks only

If no flag is given, you will be prompted to choose.

The installer creates symlinks from `~/.zshrc`, `~/.zimrc`, `~/.config/starship.toml`, and `~/.config/ghostty/config` to this repo. Existing files are backed up with a `.bak` suffix.
