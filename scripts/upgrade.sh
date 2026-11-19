#!/usr/bin/env bash
# Run safe maintenance upgrades on the Proxmox host.
# Runs on the host: `just upgrade` pipes it over SSH (`bash -s`).
# $1: REBOOT (string, optional) - Reboot policy: auto, yes, no. Default: auto.

set -euo pipefail

REBOOT_POLICY="${1:-auto}"
[[ "$REBOOT_POLICY" =~ ^(auto|yes|no)$ ]] || { echo "Error: REBOOT policy must be auto, yes, or no (got: ${REBOOT_POLICY})." >&2; exit 1; }

RUNNING_VMS=$(qm list 2>/dev/null | awk 'NR > 1 && $3 == "running" { print $1 }' || true)
[ -z "$RUNNING_VMS" ] || { echo "Error: VMs running on this node: ${RUNNING_VMS}. Stop them first." >&2; exit 1; }
echo "[OK] No running VMs"

echo "==> Refreshing package index..."
apt-get update -qq

PENDING=$(apt-get -s dist-upgrade | grep -c '^Inst' || true)
[ "$PENDING" -gt 0 ] || { echo "[OK] No updates pending. Host is current."; exit 0; }

echo "==> Applying ${PENDING} package updates..."
DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y \
    -o Dpkg::Options::=--force-confdef \
    -o Dpkg::Options::=--force-confold

REMAINING=$(apt-get -s dist-upgrade | grep -c '^Inst' || true)
[ "$REMAINING" -eq 0 ] || { echo "Error: ${REMAINING} packages still pending after dist-upgrade. Resolve manually." >&2; exit 1; }
echo "[OK] Package upgrade complete"

RUNNING_KERNEL=$(uname -r)
NEWEST_KERNEL=$(ls /boot/vmlinuz-* 2>/dev/null | sed 's|.*/vmlinuz-||' | sort -V | tail -1)

REBOOT_REQUIRED=false
if [ -f /var/run/reboot-required ] || [ "$RUNNING_KERNEL" != "$NEWEST_KERNEL" ]; then
    REBOOT_REQUIRED=true
fi

if [ "$REBOOT_POLICY" = "no" ]; then
    [ "$REBOOT_REQUIRED" = true ] && echo "[WARN] Reboot skipped by policy. Kernel ${NEWEST_KERNEL} activates on next reboot."
    exit 0
fi

if [ "$REBOOT_POLICY" = "auto" ] && [ "$REBOOT_REQUIRED" = false ]; then
    echo "[OK] Running on newest kernel ${RUNNING_KERNEL}. No reboot needed."
    exit 0
fi

echo "==> Rebooting to activate kernel ${NEWEST_KERNEL}..."
systemd-run --on-active=2s systemctl reboot
