# Inputs for every VM. Per-VM values live in `vms` (set in terraform.tfvars);
# everything else is shared lab-wide and defaults to the values in docs/.

### Proxmox placement
variable "node_name" {
  type        = string
  default     = "pve"
  description = "Proxmox node name (`hostname` on the host), not the SSH alias"
}

variable "template_vmid" {
  type        = number
  default     = 9000
  description = "VMID of the Packer-built golden template to clone"
}

variable "template_disk_gb" {
  type        = number
  default     = 20
  description = "Root disk size of the template (packer disk_size). Clones can grow, never shrink."
}

variable "vm_datastore" {
  type        = string
  default     = "local-lvm"
  description = "Storage for VM disks and the cloud-init drive"
}

variable "snippet_datastore" {
  type        = string
  default     = "local"
  description = "Storage holding cloud-init user-data snippets (must allow the `snippets` content type)"
}

### Network (docs/NETWORK_CONFIGURATION.md)
variable "bridge" {
  type        = string
  default     = "vmbr0"
  description = "Linux bridge the VM NIC plugs into"
}

variable "gateway" {
  type        = string
  default     = "192.168.1.1"
  description = "Default IPv4 gateway (the router)"
}

variable "cidr_prefix" {
  type        = number
  default     = 24
  description = "Prefix length appended to each VM's static IP"
}

variable "dns_servers" {
  type        = list(string)
  default     = ["1.1.1.1"]
  description = "Nameservers written by cloud-init"
}

variable "search_domain" {
  type        = string
  default     = "duane"
  description = "DNS search domain; also forms each VM's FQDN (<hostname>.<domain>)"
}

### Login account (rendered into cloud-init/user-data.yaml.tftpl)
variable "admin_user" {
  type        = string
  default     = "duane"
  description = "Login account created by cloud-init (passwordless sudo, key-only SSH)"
}

variable "ssh_public_key_files" {
  type        = list(string)
  default     = ["~/.ssh/id_ed25519.pub"]
  description = "Public keys (paths on this machine) authorized for admin_user"
}

### VMs
# Map key = hostname. Unset sizes fall back to the template's 2 cores / 2GB / 20GB.
variable "vms" {
  type = map(object({
    vmid      = number
    ip        = string
    cores     = optional(number, 2)
    memory_mb = optional(number, 2048)
    disk_gb   = optional(number, 20)
    tags      = optional(list(string), [])
  }))
  description = "VMs to clone from the template, keyed by hostname"

  validation {
    condition     = alltrue([for v in values(var.vms) : v.cores >= 1 && v.cores <= 4])
    error_message = "Each VM gets 1-4 vCPUs (N150 has 4 cores; see docs/HARDWARE.md)."
  }

  validation {
    condition     = sum(concat([0], [for v in values(var.vms) : v.memory_mb])) <= 13824
    error_message = "Total VM memory exceeds the 13.5GB (13824 MB) guest budget in docs/HARDWARE.md."
  }

  validation {
    condition = alltrue([
      for v in values(var.vms) :
      can(regex("^192\\.168\\.1\\.\\d{1,3}$", v.ip)) &&
      tonumber(try(split(".", v.ip)[3], 0)) >= 201 &&
      tonumber(try(split(".", v.ip)[3], 0)) <= 254
    ])
    error_message = "VM IPs must come from the static pool 192.168.1.201-254 (docs/NETWORK_CONFIGURATION.md)."
  }

  validation {
    condition     = length(distinct([for v in values(var.vms) : v.ip])) == length(var.vms)
    error_message = "Two VMs share the same IP."
  }

  validation {
    condition     = length(distinct([for v in values(var.vms) : v.vmid])) == length(var.vms)
    error_message = "Two VMs share the same VMID."
  }
}
