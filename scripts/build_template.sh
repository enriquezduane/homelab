#!/usr/bin/env bash
# Build base Debian Cloud-Init VM template.
# $1: VMID (int) - Target template ID. Must not exist.
# $2: STORAGE (string) - Target Proxmox storage pool.
# $3: IMAGE (string, optional) - Cloud image filename.
# $4: URL (string, optional) - Cloud image download URL.

set -euo pipefail

VMID="${1:?Error: VMID is required as argument 1}"
STORAGE="${2:?Error: STORAGE is required as argument 2}"
IMAGE="${3:-debian-12-genericcloud-amd64.qcow2}"
URL="${4:-https://cloud.debian.org/images/cloud/bookworm/latest/${IMAGE}}"

! qm status "$VMID" >/dev/null 2>&1 || { echo "Error: VMID ${VMID} already exists." >&2; exit 1; }

# Fetch
IMAGE_PATH=$(pvesm path "local:iso/${IMAGE}" 2>/dev/null || echo "$(dirname "$(pvesm path local:iso/boot.iso)")/${IMAGE}")
if [ ! -f "${IMAGE_PATH}" ]; then
    wget -q --show-progress -O "${IMAGE_PATH}.tmp" "${URL}"
    mv "${IMAGE_PATH}.tmp" "${IMAGE_PATH}"
fi

# Create
qm create "$VMID" \
    --name "debian-12-template" \
    --memory 2048 \
    --cores 2 \
    --cpu host \
    --net0 virtio,bridge=vmbr0

# Configure Disks
qm set "$VMID" --scsihw virtio-scsi-single
qm set "$VMID" --scsi0 "${STORAGE}:0,import-from=${IMAGE_PATH}"
qm set "$VMID" --boot order=scsi0
qm disk resize "$VMID" scsi0 20G

# Cloud-Init
qm set "$VMID" --ide2 "${STORAGE}:cloudinit"
qm set "$VMID" --serial0 socket --vga serial0
qm set "$VMID" --agent enabled=1
qm set "$VMID" --ciuser debian
qm set "$VMID" --ipconfig0 ip=dhcp

# Convert Template
qm template "$VMID"
