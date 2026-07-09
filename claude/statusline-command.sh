#!/usr/bin/env bash
# Claude Code status line script

input=$(cat)

# Current working directory (basename for display)
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
folder=$(basename "$cwd")

# Git branch (skip optional locks to avoid interference)
branch=""
if git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
  branch=$(git -C "$cwd" -c gc.auto=0 symbolic-ref --short HEAD 2>/dev/null || git -C "$cwd" -c gc.auto=0 rev-parse --short HEAD 2>/dev/null)
fi

# Active model
model_name=$(echo "$input" | jq -r '.model.display_name // empty')

# Context window usage
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
ctx_window=$(echo "$input" | jq -r '.context_window.context_window_size // empty')
# API duration (cumulative time spent waiting for API responses)
api_ms=$(echo "$input" | jq -r '.cost.total_api_duration_ms // empty')
duration_str=""
if [ -n "$api_ms" ] && [ "$api_ms" -gt 0 ] 2>/dev/null; then
  api_sec=$(( api_ms / 1000 ))
  hours=$(( api_sec / 3600 ))
  minutes=$(( (api_sec % 3600) / 60 ))
  seconds=$(( api_sec % 60 ))
  if [ "$hours" -gt 0 ]; then
    duration_str="${hours}h${minutes}m"
  elif [ "$minutes" -gt 0 ]; then
    duration_str="${minutes}m${seconds}s"
  else
    duration_str="${seconds}s"
  fi
fi

# Total cost — use the value provided by the runtime (matches /cost output exactly)
cost_usd=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')
cost=""
if [ -n "$cost_usd" ] && awk -v c="$cost_usd" 'BEGIN { exit !(c > 0) }' 2>/dev/null; then
  cost=$(awk -v c="$cost_usd" 'BEGIN {
    if (c < 0.01) printf "$%.4f", c
    else printf "$%.2f", c
  }')
fi

# ANSI colors (dimmed-friendly)
RESET='\033[0m'
BOLD='\033[1m'
CYAN='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
MAGENTA='\033[35m'
RED='\033[31m'
DIM='\033[2m'

# Progress bar for context usage
bar=""
if [ -n "$used_pct" ]; then
  bar_width=10
  filled=$(awk -v pct="$used_pct" -v w="$bar_width" 'BEGIN { printf "%d", int(pct/100*w + 0.5) }')
  empty=$(( bar_width - filled ))

  if awk -v p="$used_pct" 'BEGIN { exit !(p >= 80) }'; then
    bar_color="$RED"
  elif awk -v p="$used_pct" 'BEGIN { exit !(p >= 50) }'; then
    bar_color="$YELLOW"
  else
    bar_color="$GREEN"
  fi

  bar_filled=$(python3 -c "print('█'*$filled, end='')" 2>/dev/null || printf '%0.s█' $(seq 1 $filled) 2>/dev/null)
  bar_empty=$(python3 -c "print('░'*$empty, end='')" 2>/dev/null || printf '%0.s░' $(seq 1 $empty) 2>/dev/null)
  pct_display=$(awk -v p="$used_pct" 'BEGIN { printf "%.0f%%", p }')
  bar="${bar_color}${bar_filled}${DIM}${bar_empty}${RESET} ${bar_color}${pct_display}${RESET}"
fi

# Build output line
parts=()

# Folder
parts+=("$(printf "${CYAN}${BOLD}%s${RESET}" "$folder")")

# Git branch
if [ -n "$branch" ]; then
  parts+=("$(printf "${BLUE} %s${RESET}" "$branch")")
fi

# Active model
if [ -n "$model_name" ]; then
  parts+=("$(printf "${YELLOW}%s${RESET}" "$model_name")")
fi

# Context bar
if [ -n "$bar" ]; then
  parts+=("$bar")
fi

# Cost
if [ -n "$cost" ]; then
  parts+=("$(printf "${MAGENTA}%s${RESET}" "$cost")")
fi

# Duration
if [ -n "$duration_str" ]; then
  parts+=("$(printf "${DIM}%s${RESET}" "$duration_str")")
fi

# Join with separators
output=""
for part in "${parts[@]}"; do
  if [ -z "$output" ]; then
    output="$part"
  else
    output="${output}  ${part}"
  fi
done

printf "%b\n" "$output"
