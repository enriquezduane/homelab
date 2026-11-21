#!/usr/bin/env bash
# Remove a host's saved SSH key from ~/.ssh/known_hosts, e.g. after a VM is rebuilt
# and ssh warns "REMOTE HOST IDENTIFICATION HAS CHANGED".
# Runs locally: edits your known_hosts with `ssh-keygen -R` (previous copy kept as known_hosts.old).
# $1: IP (string, required) - IPv4 address you ssh to, e.g. 192.168.1.201.
# $2: NAME (string, optional) - Hostname/alias you also ssh to, e.g. debian-01.

set -euo pipefail

IP="${1:-}"
NAME="${2:-}"
KNOWN_HOSTS="${HOME}/.ssh/known_hosts"

[ $# -le 2 ] || { echo "Error: expected IP [NAME], got $# arguments." >&2; exit 1; }
[[ "$IP" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || { echo "Error: IP must be an IPv4 address (got: '${IP}')." >&2; exit 1; }
[[ -z "$NAME" || "$NAME" =~ ^[A-Za-z0-9][A-Za-z0-9.-]*$ ]] || { echo "Error: NAME must be a hostname (got: '${NAME}')." >&2; exit 1; }
[ -f "$KNOWN_HOSTS" ] || { echo "Nothing to do: ${KNOWN_HOSTS} does not exist."; exit 0; }

for HOST in "$IP" ${NAME:+"$NAME"}; do
    if ssh-keygen -F "$HOST" -f "$KNOWN_HOSTS" >/dev/null 2>&1; then
        ssh-keygen -R "$HOST" -f "$KNOWN_HOSTS" >/dev/null 2>&1
        echo "[OK] Removed saved key(s) for ${HOST}"
    else
        echo "[--] No saved key for ${HOST}"
    fi
done
