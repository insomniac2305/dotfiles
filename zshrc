# Always start in home directory
cd ~

# Fall back to xterm-256color if current TERM is unknown
if ! infocmp "$TERM" &>/dev/null 2>&1; then
  export TERM=xterm-256color
fi

# PATH configuration
export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:/opt/homebrew/opt/libpq/bin:/opt/homebrew/bin:$PATH

# Editor
export EDITOR='nano'

# History
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt HIST_IGNORE_ALL_DUPS  # Remove older duplicate entries
setopt HIST_REDUCE_BLANKS    # Remove superfluous blanks
setopt SHARE_HISTORY         # Share history between sessions
setopt INC_APPEND_HISTORY    # Write immediately, not on exit

# NVM lazy-loading (loads on first use of node/npm/npx/nvm)
export NVM_DIR="$HOME/.nvm"
nvm() {
  unset -f nvm node npm npx
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
  nvm "$@"
}
node() { unset -f nvm node npm npx; [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"; node "$@"; }
npm() { unset -f nvm node npm npx; [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"; npm "$@"; }
npx() { unset -f nvm node npm npx; [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"; npx "$@"; }

# --- Zim framework ---
zstyle ':zim:git' aliases-prefix 'g'
ZIM_HOME=~/.zim
if [[ ! -e ${ZIM_HOME}/zimfw.zsh ]]; then
  curl -fsSL -o ${ZIM_HOME}/zimfw.zsh https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
fi
if [[ ! ${ZIM_HOME}/init.zsh -nt ${ZIM_HOME}/.zimrc ]] && [[ ! ${ZIM_HOME}/init.zsh -nt ${ZDOTDIR:-${HOME}}/.zimrc ]]; then
  source ${ZIM_HOME}/zimfw.zsh init
fi
source ${ZIM_HOME}/init.zsh

# --- Plugin configuration ---

# zsh-history-substring-search keybindings
bindkey '^[[A' history-substring-search-up    # Up arrow
bindkey '^[[B' history-substring-search-down  # Down arrow

# fzf shell integration (Ctrl+R for history, Ctrl+T for files, Alt+C for cd)
if command -v fzf &>/dev/null; then
  if fzf --zsh &>/dev/null; then
    source <(fzf --zsh)
  elif [[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]]; then
    source /usr/share/doc/fzf/examples/key-bindings.zsh
    source /usr/share/doc/fzf/examples/completion.zsh
  fi
fi

# fzf-tab configuration
zstyle ':fzf-tab:*' fzf-min-height 20
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --color=always --icons=auto -1 $realpath'
zstyle ':fzf-tab:complete:*:*' fzf-preview 'bat --color=always --style=numbers --line-range=:50 $realpath 2>/dev/null || eza --color=always --icons=auto -1 $realpath 2>/dev/null'

# --- CLI tool integrations ---

# Zoxide (smart cd)
command -v zoxide &>/dev/null && eval "$(zoxide init zsh)"

# Starship prompt
command -v starship &>/dev/null && eval "$(starship init zsh)"

# --- Aliases ---

# eza (modern ls)
if command -v eza &>/dev/null; then
  alias ls='eza --icons=auto'
  alias ll='eza -l --icons=auto --git'
  alias la='eza -la --icons=auto --git'
  alias lt='eza --tree --level=2 --icons=auto'
fi

# bat (modern cat)
command -v bat &>/dev/null && alias cat='bat --paging=never'

# fd (modern find)
command -v fd &>/dev/null && alias find='fd'

# Keychain password manager (macOS only)
[[ -x ~/.local/bin/keychain-passwords ]] && alias kp='~/.local/bin/keychain-passwords'

# Load secrets (API keys, tokens)
[ -s "$HOME/.secrets" ] && source "$HOME/.secrets"
