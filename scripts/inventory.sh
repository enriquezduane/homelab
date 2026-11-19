#!/usr/bin/env bash
# List every guest on the Proxmox host: VMs, LXCs, and templates.
# Runs locally: fetches JSON via `pvesh` over SSH, formats it with local `jq`.
# $1: HOST (string, optional) - SSH alias of the Proxmox host. Default: proxmox-lab.
# $2: FORMAT (string, optional) - Output format: table, json. Default: table.

set -euo pipefail

PVE_HOST="${1:-proxmox-lab}"
FORMAT="${2:-table}"
[[ "$FORMAT" =~ ^(table|json)$ ]] || { echo "Error: FORMAT must be table or json (got: ${FORMAT})." >&2; exit 1; }
command -v jq >/dev/null || { echo "Error: jq is required locally (brew install jq)." >&2; exit 1; }

RESOURCES=$(ssh -o BatchMode=yes -o ConnectTimeout=5 "$PVE_HOST" \
    pvesh get /cluster/resources --type vm --output-format json) || {
    echo "Error: could not query guests on ${PVE_HOST}." >&2
    exit 1
}

if [ "$FORMAT" = "json" ]; then
    jq 'sort_by(.vmid)' <<< "$RESOURCES"
    exit 0
fi

jq -r '
    def gib: . / 1073741824 * 10 | round / 10;
    ["VMID", "KIND", "NAME", "STATUS", "VCPU", "MEM_GB", "DISK_GB", "TAGS"],
    (sort_by(.vmid)[] | [
        .vmid,
        (if .template == 1 then "template" elif .type == "qemu" then "vm" else .type end),
        .name,
        .status,
        .maxcpu,
        (.maxmem | gib),
        (.maxdisk | gib),
        (.tags // "-")
    ])
    | @tsv
' <<< "$RESOURCES" | column -t -s $'\t'
