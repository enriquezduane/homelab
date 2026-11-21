# VMs managed by OpenTofu. Add an entry to create a VM, remove it to destroy.
# Before adding one: pick a free IP from docs/NETWORK_CONFIGURATION.md, `ping` it,
# then record the IP + VMID in the docs. Then: `just tofu-plan`, `just tofu-apply`.
#
# ── Quick reference: per-VM fields (inside vms = { "<hostname>" = { ... } }) ──
#   key        hostname; also the Proxmox VM name and FQDN <hostname>.duane
#   vmid       required  number        unique; convention: same as the IP's last octet
#   ip         required  string        192.168.1.201-254, unique, ping it first
#   cores      optional  number        default 2      allowed 1-4
#   memory_mb  optional  number        default 2048   all VMs together <= 13824 (13.5GB)
#   disk_gb    optional  number        default 20     >= 20 (template disk); grow only
#   tags       optional  list(string)  default []     "tofu" is always added
#
#   Changing cores/memory_mb/disk_gb/tags updates the VM in place (may reboot).
#   Changing the key (hostname) or vmid destroys and recreates the VM: read the plan.
#
# ── Lab-wide settings (defaults in variables.tf; override by adding a line here) ──
#   admin_user            "duane"                       login user created by cloud-init
#   ssh_public_key_files  ["~/.ssh/id_ed25519.pub"]     keys authorized for admin_user
#   dns_servers           ["1.1.1.1"]                   nameservers
#   search_domain         "duane"                       DNS search domain / FQDN suffix
#   gateway               "192.168.1.1"                 default route
#   cidr_prefix           24                            netmask for every VM IP
#   bridge                "vmbr0"                       Proxmox bridge for the NIC
#   template_vmid         9000                          template to clone
#   vm_datastore          "local-lvm"                   VM disks + cloud-init drive
#   e.g. dns_servers = ["1.1.1.1", "192.168.1.1"]
#   Lab-wide changes affect EVERY VM; user/key/DNS changes only apply on first
#   boot, so existing VMs keep the old values until rebuilt.

vms = {
  "debian-01" = {
    vmid      = 201
    ip        = "192.168.1.201"
    cores     = 2
    memory_mb = 2048
    disk_gb   = 20
    tags      = ["debian-13"]
  },

  "debian-02" = {
    vmid      = 209
    ip        = "192.168.1.209"
    cores     = 2
    memory_mb = 2048
    disk_gb   = 20
    tags      = ["jonard"]
  }
}
