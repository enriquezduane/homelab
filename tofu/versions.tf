# OpenTofu + provider versions. `tofu init` downloads the provider and
# records exact hashes in .terraform.lock.hcl (commit that file).
terraform {
  required_version = ">= 1.10"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.123"
    }
  }
}
