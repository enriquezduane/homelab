# One cloud-init snippet + one cloned VM per entry in var.vms.
# Hardware mirrors packer/debian-13.pkr.hcl so clones match the template.

locals {
  ssh_public_keys = [for f in var.ssh_public_key_files : trimspace(file(pathexpand(f)))]
}

### Cloud-init user-data, rendered from cloud-init/user-data.yaml.tftpl
resource "proxmox_virtual_environment_file" "user_data" {
  for_each = var.vms

  node_name    = var.node_name
  datastore_id = var.snippet_datastore
  content_type = "snippets"

  source_raw {
    file_name = "${each.key}-user-data.yaml"
    data = templatefile("${path.module}/cloud-init/user-data.yaml.tftpl", {
      hostname        = each.key
      fqdn            = "${each.key}.${var.search_domain}"
      username        = var.admin_user
      ssh_public_keys = local.ssh_public_keys
    })
  }
}

### VMs
resource "proxmox_virtual_environment_vm" "vm" {
  for_each = var.vms

  name        = each.key
  node_name   = var.node_name
  vm_id       = each.value.vmid
  description = "Managed by OpenTofu (tofu/). Cloned from template ${var.template_vmid}."
  tags        = sort(distinct(concat(["tofu"], each.value.tags)))
  on_boot     = true
  started     = true

  # Full clone: an independent disk copy on local-lvm, not linked to the template.
  clone {
    vm_id        = var.template_vmid
    full         = true
    datastore_id = var.vm_datastore
  }

  # qemu-guest-agent is baked into the template; tofu reads the VM's IP through it.
  agent {
    enabled = true
  }

  cpu {
    cores = each.value.cores
    type  = "host"
  }

  memory {
    dedicated = each.value.memory_mb
  }

  # Set explicitly: the provider's default (virtio-scsi-pci) differs from the template.
  scsi_hardware = "virtio-scsi-single"

  disk {
    datastore_id = var.vm_datastore
    interface    = "scsi0"
    size         = each.value.disk_gb
    file_format  = "raw"
    discard      = "on"
    ssd          = true
    iothread     = true
  }

  network_device {
    bridge = var.bridge
    model  = "virtio"
  }

  # Text console via `qm terminal <VMID>`, works even if networking breaks.
  serial_device {
    device = "socket"
  }

  vga {
    type = "serial0"
  }

  initialization {
    datastore_id = var.vm_datastore
    interface    = "ide1" # the template's cloud-init drive is on ide1

    dns {
      domain  = var.search_domain
      servers = var.dns_servers
    }

    ip_config {
      ipv4 {
        address = "${each.value.ip}/${var.cidr_prefix}"
        gateway = var.gateway
      }
    }

    user_data_file_id = proxmox_virtual_environment_file.user_data[each.key].id
  }

  lifecycle {
    precondition {
      condition     = each.value.disk_gb >= var.template_disk_gb
      error_message = "disk_gb for ${each.key} is smaller than the template disk (${var.template_disk_gb}GB). Clones can grow, not shrink."
    }
  }
}
