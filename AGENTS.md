# Homelab

Single-node Proxmox VE 9 lab: node `pve`, SSH alias `proxmox-lab` (root, key auth), `192.168.1.200`.
Workflow from this machine: Packer builds template 9000 → OpenTofu clones VMs (not set up yet) → Ansible configures them (not set up yet). `just --list` shows entry points.

## Reference docs (live state; read before acting)
- `docs/HARDWARE.md`: host specs, CPU/RAM budgets, storage pools, VMID reservations.
- `docs/NETWORK_CONFIGURATION.md`: bridges, DNS, IP plan, static IP ledger, API access.

## Rules
- VMs only (`qm`). Never use LXC (`pct`).
- Stay within budget: ≤4 vCPUs per VM, ≤13.5GB RAM across all VMs, disks on `local-lvm`.
- Static IPs come from `192.168.1.201–254` on `vmbr0`, gateway `192.168.1.1`. Check the ledger, then `ping` the IP to confirm it's free before allocating.
- The router has no DHCP reservations: set fixed IPs on the VM (cloud-init `ipconfig0`), never rely on DHCP.
- ISP uses CGNAT: no public IPv4 and no port forwarding. Everything is LAN-only; remote access needs an outbound tunnel/VPN.
- Update `docs/` when you allocate an IP or VMID, change a template, or change host config. Tell the user which doc you edited.
- API credentials are in `.env` (gitignored). Load with `source .env`; never print or commit values.
- New tooling goes in `scripts/<name>.sh` with a one-line `just` recipe. Header states purpose, args, and whether it runs locally or on the host.
- Bash style: `set -euo pipefail`, explicit argument parsing, `qm` CLI. Don't refactor working scripts, bridges, or templates unless asked.
- Remove anything temporary you create (ISOs, test VMs, files).

## Verify
- Host: `just check`
- Guests (VMs, LXCs, templates): `just inventory` (read-only; use this instead of `pct`)
- VM: `ssh proxmox-lab qm status <VMID>`
- IP: `ping` or `nc` the address before and after allocation.
