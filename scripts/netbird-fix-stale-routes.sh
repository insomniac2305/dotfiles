#!/usr/bin/env bash
# Fix NetBird "LoginFailed" after a network change (e.g. switching to a mobile hotspot).
#
# NetBird pins host routes to its management server via the physical gateway of the
# network it connected on. After hopping networks, those routes can go stale (pointing
# at the old network's gateway), so the client can't reach the management server and
# gets stuck in LoginFailed. This script detects those stale host routes, deletes them,
# and restarts the NetBird daemon so it re-pins them via the current gateway.
#
# Usage: netbird-fix-stale-routes.sh [host] [port]
#   host  Management server hostname (default: connect.zollsoft.net)
#   port  Port to test connectivity on (default: 443)
#
# Needs sudo for `route delete` and the daemon restart.

set -euo pipefail

HOST="${1:-connect.zollsoft.net}"
PORT="${2:-443}"

check_connectivity() {
  nc -z -w 5 "$HOST" "$PORT" >/dev/null 2>&1
}

resolve_ips() {
  # A and AAAA records; filter out CNAMEs dig may include in +short output
  {
    dig +short "$HOST" A
    dig +short "$HOST" AAAA
  } | grep -E '^([0-9]{1,3}\.){3}[0-9]{1,3}$|^[0-9a-fA-F:]+$' || true
}

# Returns the gateway of an existing host route for the given IP, empty otherwise.
host_route_gateway() {
  local ip="$1" family=""
  [[ "$ip" == *:* ]] && family="-inet6"
  local info
  info=$(route -n get $family "$ip" 2>/dev/null) || return 0
  # Only report it if the route is a pinned host route for exactly this IP,
  # not the default route the lookup fell through to.
  local dest
  dest=$(awk '/^ *destination:/{print $2}' <<< "$info")
  [[ "$dest" == "$ip" ]] || return 0
  awk '/^ *gateway:/{print $2}' <<< "$info"
}

echo "Testing ${HOST}:${PORT} ..."
if check_connectivity; then
  echo "Connectivity is fine — no stale routes to fix."
  exit 0
fi
echo "Cannot reach ${HOST}:${PORT}. Checking for stale pinned host routes..."

ips=$(resolve_ips)
if [[ -z "$ips" ]]; then
  echo "Error: could not resolve ${HOST} — this is a DNS problem, not a stale route." >&2
  exit 1
fi

deleted=0
while IFS= read -r ip; do
  gw=$(host_route_gateway "$ip")
  if [[ -n "$gw" ]]; then
    echo "Stale host route: ${ip} via ${gw} — deleting."
    family=""
    [[ "$ip" == *:* ]] && family="-inet6"
    sudo route -n delete $family "$ip" >/dev/null
    deleted=$((deleted + 1))
  else
    echo "No pinned host route for ${ip}."
  fi
done <<< "$ips"

if [[ "$deleted" -eq 0 ]]; then
  echo "No stale routes found — the connectivity problem lies elsewhere." >&2
  exit 1
fi

echo "Restarting NetBird daemon..."
sudo launchctl kickstart -k system/netbird

echo "Waiting for daemon to reconnect..."
for _ in $(seq 1 10); do
  sleep 2
  if check_connectivity; then
    echo "Connectivity to ${HOST}:${PORT} restored."
    status=$(netbird status 2>&1 | head -1) || true
    echo "NetBird: ${status}"
    if grep -q "LoginFailed" <<< "$status"; then
      echo "Session seems expired — run: netbird up"
    fi
    exit 0
  fi
done

echo "Routes were cleaned but ${HOST}:${PORT} is still unreachable — check network." >&2
exit 1
