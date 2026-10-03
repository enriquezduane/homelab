#!/usr/bin/env bash
# Deploy VM cloned from Cloud-Init template.
# $1: TEMPLATE_VMID (int) - Source template ID. Must exist.
# $2: VMID (int) - Target VM ID. Must not exist.
# $3: NAME (string) - Hostname. RFC 1123 compliant.
# $4: IP_CIDR (string) - Static IPv4 address with subnet mask.
# $5: GATEWAY (string) - Default gateway IPv4 address.
# $6: SSH_KEY (string, optional) - Public key string or path to public key file.

set -euo pipefail

TEMPLATE_VMID="${1:?Error: TEMPLATE_VMID is required as argument 1}"
VMID="${2:?Error: VMID is required as argument 2}"
NAME="${3:?Error: NAME is required as argument 3}"
IP_CIDR="${4:?Error: IP_CIDR is required as argument 4}"
GATEWAY="${5:?Error: GATEWAY is required as argument 5}"
SSH_KEY="${6:-}"

[[ "$IP_CIDR" =~ ^[0-9.]+\/[0-9]+$ ]] || { echo "Error: IP_CIDR '${IP_CIDR}' is not a valid CIDR (expected format: IP/prefix)." >&2; exit 1; }
qm status "$TEMPLATE_VMID" >/dev/null 2>&1 || { echo "Error: Source template VMID ${TEMPLATE_VMID} does not exist." >&2; exit 1; }
! qm status "$VMID" >/dev/null 2>&1 || { echo "Error: Target VMID ${VMID} already exists." >&2; exit 1; }

SSH_KEY_FILE=""
if [ -n "$SSH_KEY" ]; then
    if [ -f "$SSH_KEY" ]; then
        SSH_KEY_FILE="$SSH_KEY"
    else
        SSH_KEY_FILE=$(mktemp)
        echo "$SSH_KEY" > "$SSH_KEY_FILE"
        trap 'rm -f "$SSH_KEY_FILE"' EXIT
    fi
elif [ -f /root/.ssh/authorized_keys ]; then
    SSH_KEY_FILE="/root/.ssh/authorized_keys"
else
    echo "Error: No SSH key provided and /root/.ssh/authorized_keys not found." >&2
    exit 1
fi

qm clone "$TEMPLATE_VMID" "$VMID" --name "$NAME" --full
qm set "$VMID" --sshkeys "$SSH_KEY_FILE"
qm set "$VMID" --ipconfig0 "ip=${IP_CIDR},gw=${GATEWAY}"
qm start "$VMID"
