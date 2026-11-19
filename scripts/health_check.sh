#!/usr/bin/env bash
# Verify Proxmox host connectivity, port reachability, and service health.
# Runs locally: probes the host over the network, then over SSH.
# $1: HOST (string, optional) - SSH alias or IP of the Proxmox host. Default: proxmox-lab.

set -euo pipefail

PROBE_HOST="${1:-proxmox-lab}"
RESOLVED_IP=$(ssh -G "$PROBE_HOST" 2>/dev/null | awk '/^hostname / { print $2 }' || true)
TARGET_IP="${RESOLVED_IP:-$PROBE_HOST}"

echo "==> Probing host ${PROBE_HOST} (${TARGET_IP})..."

ping -c 2 "$TARGET_IP" >/dev/null 2>&1 || { echo "[FAIL] ICMP ping failed for ${TARGET_IP}" >&2; exit 1; }
echo "[OK] ICMP ping reachable"

nc -z -w 2 "$TARGET_IP" 22 >/dev/null 2>&1 || { echo "[FAIL] SSH port 22 closed on ${TARGET_IP}" >&2; exit 1; }
echo "[OK] SSH port 22 open"

if nc -z -w 2 "$TARGET_IP" 8006 >/dev/null 2>&1; then
    echo "[OK] Proxmox Web GUI / API port 8006 open"
else
    echo "[WARN] Proxmox Web GUI / API port 8006 closed on ${TARGET_IP}" >&2
fi

LOAD=$(ssh -o BatchMode=yes -o ConnectTimeout=3 "$PROBE_HOST" "uptime | awk -F'load average:' '{ print \$2 }'") || {
    echo "[FAIL] SSH authentication failed for ${PROBE_HOST}" >&2
    exit 1
}
echo "[OK] SSH authentication succeeded"
echo "[OK] Host load:${LOAD}"
