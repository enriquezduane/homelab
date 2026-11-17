# Debian 13 (Trixie) golden template for Proxmox, built by Packer.
#
# How to run (from the repo root):
#   just packer-build
#
# Packer runs on your workstation, talks to the Proxmox API, boots the
# Debian ISO in a new VM, and serves http/preseed.cfg to the installer.

### 1. Plugins
# The Proxmox builder plugin. Downloaded automatically by `packer init`.
packer {
  required_plugins {
    proxmox = {
      version = ">= 1.2.4"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

### 2. Proxmox API Connection
# Read from environment variables exported by the repo-root .env.
# Packer does NOT read .env files itself; `just packer-build` loads it for you.
# Builds fail fast with a clear message if any of these are empty.
variable "proxmox_url" {
  type        = string
  default     = env("PROXMOX_URL")
  description = "Proxmox API endpoint, e.g. https://192.168.1.200:8006/api2/json"

  validation {
    condition     = length(var.proxmox_url) > 0
    error_message = "PROXMOX_URL is not set. Add it to the repo-root .env."
  }
}

variable "proxmox_username" {
  type        = string
  default     = env("PROXMOX_USERNAME")
  description = "API token ID in the form user@realm!tokenid, e.g. root@pam!packer"

  validation {
    condition     = length(var.proxmox_username) > 0
    error_message = "PROXMOX_USERNAME is not set. Add it to the repo-root .env."
  }
}

variable "proxmox_token" {
  type        = string
  default     = env("PROXMOX_TOKEN")
  sensitive   = true
  description = "API token secret (UUID shown once when the token is created)"

  validation {
    condition     = length(var.proxmox_token) > 0
    error_message = "PROXMOX_TOKEN is not set. Add it to the repo-root .env."
  }
}

### 3. Install Media
# Debian ISO already uploaded to the Proxmox `local` datastore.
variable "iso_file" {
  type        = string
  default     = "local:iso/debian-13.7.0-amd64-netinst.iso"
  description = "Exact datastore path of your Debian 13 ISO on proxmox-lab"
}

variable "iso_checksum" {
  type        = string
  default     = "none"
  description = "SHA256/SHA512 checksum of the ISO (e.g. sha256:...), or 'none' if already verified on Proxmox"
}

source "proxmox-iso" "debian-13" {
  ### 4. Proxmox Target
  # Self-signed cert on the lab host, so TLS verification is skipped.
  proxmox_url              = var.proxmox_url
  username                 = var.proxmox_username
  token                    = var.proxmox_token
  insecure_skip_tls_verify = true
  node                     = "pve" # Proxmox node name (`hostname` on the host), not the SSH alias
  task_timeout             = "10m"

  ### 5. Template Identity
  # VMID 9000 = the golden template OpenTofu clones VMs from.
  vm_id                = 9000
  vm_name              = "debian-13-template"
  template_name        = "debian-13-template"
  template_description = "Debian 13 (Trixie) Golden Template - built by Packer"
  tags                 = "debian-13;template"

  ### 6. Boot ISO
  # Attached as an IDE CD-ROM and removed once the template is finished.
  boot_iso {
    type         = "ide"
    iso_file     = var.iso_file
    iso_checksum = var.iso_checksum
    unmount      = true
  }

  ### 7. Compute & Hardware (tuned for Beelink EQ14 / Intel N150)
  # `host` CPU type passes through the real CPU features to the VM.
  cores           = 2
  sockets         = 1
  cpu_type        = "host"
  memory          = 2048
  os              = "l26"
  scsi_controller = "virtio-scsi-single"
  qemu_agent      = true

  ### 8. Headless Serial Console
  # Same as `--serial0 socket --vga serial0`; lets you use `qm terminal <VMID>`.
  serials = ["socket"]
  vga {
    type = "serial0"
  }

  ### 9. Disk
  # 20GB thin-provisioned disk on local-lvm. `discard` + `ssd` let freed
  # blocks return to the thin pool.
  disks {
    type         = "scsi"
    disk_size    = "20G"
    storage_pool = "local-lvm"
    format       = "raw"
    discard      = true
    ssd          = true
    io_thread    = true
  }

  ### 10. Network
  # VirtIO NIC on the lab bridge. The installer gets a DHCP address here.
  network_adapters {
    model    = "virtio"
    bridge   = "vmbr0"
    firewall = false
  }

  ### 11. Cloud-Init Drive
  # Added to the finished template so clones can get hostname/IP/SSH keys.
  cloud_init              = true
  cloud_init_storage_pool = "local-lvm"
  cloud_init_disk_type    = "ide"

  ### 12. Preseed HTTP Server
  # Packer serves the `http/` folder from your workstation on port 8888.
  # Path is relative to where `packer` runs, so run it from inside packer/.
  # Your workstation firewall must allow inbound 8888 from the VM.
  http_directory = "http"
  http_port_min  = 8888
  http_port_max  = 8888

  ### 13. Installer Boot Command
  # Typed into the Debian boot menu: points the installer at the preseed
  # file and sends console output to the serial port.
  boot_wait = "8s"
  boot_command = [
    "<esc><wait>",
    "auto ",
    "preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg ",
    "debian-installer=en_US.UTF-8 ",
    "auto=true ",
    "priority=critical ",
    "interface=auto ",
    "hostname=debian-template ",
    "domain=duane ",
    "--- quiet console=ttyS0,115200n8<enter>"
  ]

  ### 14. Build SSH Credentials
  # Temporary login Packer uses after install. Must match preseed.cfg Section 4.
  # The account is locked in Section 15 before the template is saved.
  ssh_username = "packer"
  ssh_password = "packer"
  ssh_timeout  = "20m"
}

build {
  sources = ["source.proxmox-iso.debian-13"]

  ### 15. Generalize the Template
  # Update packages, then strip anything unique to this VM (SSH host keys,
  # machine-id, cloud-init state) so every clone starts fresh.
  # Reset /etc/network/interfaces to loopback only: the installer left a DHCP
  # rule there that would fight Cloud-Init's static IP on clones.
  # Finally lock the temporary `packer` account and remove its sudo rule.
  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get -y upgrade",
      "sudo apt-get -y autoremove",
      "sudo apt-get -y clean",
      "sudo rm -f /etc/ssh/ssh_host_*",
      "sudo truncate -s 0 /etc/machine-id",
      "sudo rm -f /var/lib/dbus/machine-id",
      "printf 'auto lo\\niface lo inet loopback\\n\\nsource /etc/network/interfaces.d/*\\n' | sudo tee /etc/network/interfaces > /dev/null",
      "sudo cloud-init clean --logs",
      "sudo sh -c 'passwd -l packer && rm -f /etc/sudoers.d/packer'"
    ]
  }
}
