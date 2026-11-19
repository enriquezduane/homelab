set shell := ["bash", "-euo", "pipefail", "-c"]

host := "proxmox-lab"

# List available recipes
default:
    @just --list --unsorted

# Check Proxmox host reachability and service health
check target=host:
    ./scripts/health_check.sh {{target}}

# List VMs on the Proxmox host
list:
    ssh {{host}} qm list

# Upgrade Proxmox host packages (reboot: auto | yes | no)
upgrade reboot="auto":
    ssh {{host}} 'bash -s' -- "{{reboot}}" < scripts/upgrade.sh

# Build Debian 13 template (VMID 9000) with Packer, using API creds from .env
packer-build:
    source .env && cd packer && packer init . && packer build .

# Preview VM changes with OpenTofu (Milestone 2)
tofu-plan: (_todo "OpenTofu" "2")

# Create/update VMs with OpenTofu (Milestone 2)
tofu-apply: (_todo "OpenTofu" "2")

# Configure and harden VMs with Ansible (Milestone 4)
ansible: (_todo "Ansible" "4")

_todo tool milestone:
    @echo "Not set up yet: {{tool}} arrives in Milestone {{milestone}}." >&2; exit 1
