#!/usr/bin/env bash
# Keychain password manager for terminal use
# Stores passwords in macOS Keychain with "terminal:" prefix
# Retrieval triggers native auth dialog (supports Touch ID)

set -euo pipefail

PREFIX="terminal"
CLIPBOARD_CLEAR_SECONDS=10

usage() {
  echo "Usage: $0 <command> [args]"
  echo ""
  echo "Commands:"
  echo "  add <name>           Add or update a password entry"
  echo "  remove <name>        Remove a password entry"
  echo "  list                 List all stored entry names"
  echo "  get <name>           Copy password to clipboard (clears after ${CLIPBOARD_CLEAR_SECONDS}s)"
  echo "  pick                 Interactive picker — select and paste into active window"
  exit 1
}

list_entries() {
  security dump-keychain 2>/dev/null \
    | grep "\"svce\"<blob>=\"${PREFIX}:" \
    | sed "s/.*\"${PREFIX}://; s/\".*//" \
    | sort -u
}

add_entry() {
  local name="$1"
  # Reject names with special characters to prevent injection
  if [[ ! "$name" =~ ^[a-zA-Z0-9._-]+$ ]]; then
    echo "Error: name must only contain letters, numbers, dots, hyphens, and underscores."
    return 1
  fi
  echo -n "Password for '${name}': "
  read -rs password
  echo ""
  # Delete existing entry if present (ignore errors)
  security delete-generic-password -s "${PREFIX}:${name}" 2>/dev/null || true
  security add-generic-password -s "${PREFIX}:${name}" -a "${USER}" -w "${password}"
  echo "Stored '${name}' in Keychain."
}

remove_entry() {
  local name="$1"
  security delete-generic-password -s "${PREFIX}:${name}" 2>/dev/null \
    && echo "Removed '${name}'." \
    || echo "Entry '${name}' not found."
}

get_entry() {
  local name="$1"
  local password
  password=$(security find-generic-password -s "${PREFIX}:${name}" -a "${USER}" -w 2>/dev/null) || {
    echo "Entry '${name}' not found or access denied."
    return 1
  }
  echo -n "$password" | pbcopy
  echo "Copied to clipboard. Clearing in ${CLIPBOARD_CLEAR_SECONDS}s."
  (sleep "$CLIPBOARD_CLEAR_SECONDS" && pbcopy < /dev/null) &
}

pick_and_paste() {
  local entries
  entries=$(list_entries)

  if [[ -z "$entries" ]]; then
    osascript -e 'display dialog "No passwords stored.\nAdd with: keychain-passwords add <name>" buttons {"OK"} default button "OK" with title "Keychain Passwords"'
    return 1
  fi

  # Remember the frontmost app before showing picker
  local front_app
  front_app=$(osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true')

  # Build AppleScript list from entries
  local applescript_list=""
  while IFS= read -r entry; do
    applescript_list+="\"${entry}\", "
  done <<< "$entries"
  applescript_list="{${applescript_list%, }}"

  # Show picker dialog
  local chosen
  chosen=$(osascript <<APPLESCRIPT
    tell application "System Events"
      activate
      set chosen to choose from list ${applescript_list} with title "Keychain Passwords" with prompt "Select a password to paste:"
    end tell
    return chosen
APPLESCRIPT
  ) || return 0

  if [[ "$chosen" == "false" ]]; then
    return 0
  fi

  # Retrieve password (triggers Touch ID / Keychain auth dialog)
  local password
  password=$(security find-generic-password -s "${PREFIX}:${chosen}" -a "${USER}" -w 2>/dev/null) || {
    osascript -e 'display dialog "Access denied or entry not found." buttons {"OK"} default button "OK" with title "Keychain Passwords"'
    return 1
  }

  # Copy to clipboard, refocus previous app, notify user
  echo -n "$password" | pbcopy
  osascript -e "tell application \"$(sed 's/[\\\"]/\\&/g' <<< "$front_app")\" to activate"
  osascript -e 'display notification "Password copied — Cmd+V to paste. Clipboard clears in 10s." with title "Keychain Passwords"'
  (sleep "$CLIPBOARD_CLEAR_SECONDS" && pbcopy < /dev/null) &
}

# --- Main ---
[[ $# -lt 1 ]] && usage

case "$1" in
  add)
    [[ $# -lt 2 ]] && { echo "Usage: $0 add <name>"; exit 1; }
    add_entry "$2"
    ;;
  remove)
    [[ $# -lt 2 ]] && { echo "Usage: $0 remove <name>"; exit 1; }
    remove_entry "$2"
    ;;
  list)
    list_entries
    ;;
  get)
    [[ $# -lt 2 ]] && { echo "Usage: $0 get <name>"; exit 1; }
    get_entry "$2"
    ;;
  pick)
    pick_and_paste
    ;;
  *)
    usage
    ;;
esac
