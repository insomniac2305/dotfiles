# dotfiles

Personal terminal configuration with zsh, Starship prompt, and Ghostty.

## What's included

| File | Purpose |
|---|---|
| `zshrc` | Zsh config — history, NVM lazy-loading, aliases, plugin settings |
| `zimrc` | [zimfw](https://zimfw.sh/) plugin list |
| `starship.toml` | [Starship](https://starship.rs/) prompt — Catppuccin Mocha powerline theme |
| `ghostty/config` | [Ghostty](https://ghostty.org/) terminal settings |
| `scripts/keychain-passwords.sh` | macOS Keychain-based password manager for the terminal |
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

The installer creates symlinks from `~/.zshrc`, `~/.zimrc`, `~/.config/starship.toml`, `~/.config/ghostty/config`, and `~/.local/bin/keychain-passwords` to this repo. Existing files are backed up with a `.bak` suffix.

## Keychain password manager

A script for storing and retrieving passwords via the macOS Keychain, available as `kp`:

```bash
kp add myserver      # Store a password (prompted securely)
kp list              # List all stored entries
kp get myserver      # Copy password to clipboard (clears after 10s)
kp remove myserver   # Delete an entry
kp pick              # Interactive picker — select and paste
```

Passwords are stored in the login keychain with a `terminal:` prefix. Retrieval triggers the native macOS auth dialog (supports Touch ID).

### Setting up a global keyboard shortcut

To trigger `kp pick` from anywhere with a hotkey:

1. Open **Shortcuts.app**
2. Create a new shortcut and add a **Run Shell Script** action
3. Set the shell to `/bin/bash` and enter: `~/.local/bin/keychain-passwords pick`
4. Name the shortcut (e.g. "Paste Password")
5. Click the shortcut's info button (top right) and assign a **Keyboard Shortcut** (e.g. `Ctrl+Cmd+P`)

This opens a focused picker dialog, copies the selected password to the clipboard, refocuses the previous app, and auto-clears the clipboard after 10 seconds.
