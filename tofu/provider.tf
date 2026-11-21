# Proxmox connection.
#   endpoint: not a secret, so it is explicit here (override with TF_VAR_proxmox_endpoint).
#   token:    the only secret. The provider reads PROXMOX_VE_API_TOKEN
#             (user@realm!tokenid=secret) from the environment, which direnv
#             or `just` load from the gitignored .env. Never put it in .tf files.
#
# `ssh` block: VM create/clone/cloud-init settings go through the API, but the
# Proxmox API cannot upload snippets, so the cloud-init user-data file is
# copied over SSH (same root key as `ssh proxmox-lab`).
variable "proxmox_endpoint" {
  type        = string
  default     = "https://192.168.1.200:8006/"
  description = "Proxmox API endpoint (no /api2/json suffix)"
}

variable "proxmox_ssh_address" {
  type        = string
  default     = "192.168.1.200"
  description = "SSH address of the Proxmox node (for snippet uploads)"
}

variable "proxmox_ssh_user" {
  type        = string
  default     = "root"
  description = "SSH user on the Proxmox node"
}

variable "proxmox_ssh_private_key_file" {
  type        = string
  default     = "~/.ssh/id_ed25519_proxmox_lab"
  description = "Private key for proxmox_ssh_user (path on this machine)"
}

provider "proxmox" {
  endpoint = var.proxmox_endpoint

  # Proxmox uses a self-signed certificate on the LAN.
  insecure = true

  ssh {
    username    = var.proxmox_ssh_user
    private_key = file(pathexpand(var.proxmox_ssh_private_key_file))

    node {
      name    = var.node_name
      address = var.proxmox_ssh_address
    }
  }
}
