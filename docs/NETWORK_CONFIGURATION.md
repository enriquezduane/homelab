# Network Configuration

- Internet Uplink: ISP uses Carrier-Grade NAT (CGNAT)
    - Inbound forwarding: None
    - Implication: No public IPv4; all services are local LAN only
- Domain & DNS Settings:
    - Search domain: `duane`
    - Primary nameserver: `1.1.1.1` (Cloudflare public resolver)
    - Fallback nameserver: `192.168.1.1` (Router upstream resolver)
- Bridge Topology:
    - Hypervisor bridge: `vmbr0`
    - Physical uplink: Primary 1GbE Ethernet NIC
    - Encapsulation: Untagged standard frames (single flat network, no VLANs)
- IPv4 Address Allocation Layout:
    - `192.168.1.1`: Router and default gateway
    - `192.168.1.2`–`192.168.1.199`: Dynamic DHCP pool (general client devices)
    - `192.168.1.200`: Proxmox VE 9 Hypervisor Host (`proxmox-lab`, Debian 13 base)
        - Web console: `https://192.168.1.200:8006`
        - SSH management: `ssh root@192.168.1.200`
    - `192.168.1.201`–`192.168.1.254`: Static IP reservation pool for VMs

## Static IP Allocation Ledger

| IP Address | VMID | Hostname | Distro | Notes / Role |
| :--- | :--- | :--- | :--- | :--- |
| `192.168.1.200` | Host | `proxmox-lab` | Debian 13 / PVE 9 | Hypervisor node |
| `192.168.1.201` | | | | |
| `192.168.1.202` | | | | |
| `192.168.1.203` | | | | |
