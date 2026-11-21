set shell := ["bash", "-euo", "pipefail", "-c"]

# Load API credentials from .env for every recipe (no manual `source`)
set dotenv-load

host := "proxmox-lab"

# List available recipes
default:
    @just --list --unsorted

# Check Proxmox host reachability and service health
check target=host:
    ./scripts/health_check.sh {{target}}

# List VMs, LXCs, and templates on the Proxmox host (format: table | json)
inventory format="table":
    ./scripts/inventory.sh {{host}} {{format}}

# Upgrade Proxmox host packages (reboot: auto | yes | no)
upgrade reboot="auto":
    ssh {{host}} 'bash -s' -- "{{reboot}}" < scripts/upgrade.sh

# Build Debian 13 template (VMID 9000) with Packer
packer-build:
    cd packer && packer init . && packer build .

# Download OpenTofu providers (run once, or after changing versions)
tofu-init:
    tofu -chdir=tofu init

# Preview VM changes with OpenTofu
tofu-plan:
    tofu -chdir=tofu plan

# Create/update VMs with OpenTofu
tofu-apply:
    tofu -chdir=tofu apply

# Forget a rebuilt VM's old SSH host key (e.g. just forget-host 192.168.1.201 debian-01)
forget-host ip name="":
    ./scripts/forget_host.sh {{quote(ip)}} {{quote(name)}}

# Check Ansible can reach every VM and sudo to root
ansible-ping:
    cd ansible && ansible-playbook playbooks/ping.yml

# Configure VMs with Ansible (extra args pass through, e.g. just ansible-run --check --limit debian-01)
ansible-run *args:
    cd ansible && ansible-playbook playbooks/site.yml {{args}}
