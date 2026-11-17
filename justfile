set shell := ["bash", "-cu"]

PVE_HOST := "proxmox-lab"

# Check Proxmox host connectivity and service health
check host=PVE_HOST:
    ./scripts/health_check.sh {{host}}

# Run safe maintenance upgrades on Proxmox host. Reboot policy: auto (default), yes, no.
upgrade reboot="auto":
    ssh {{PVE_HOST}} 'bash -s' -- "{{reboot}}" < scripts/upgrade.sh

# List all virtual machines on Proxmox host
list:
    ssh {{PVE_HOST}} qm list

# Milestone 1: Build Debian 13 template (VMID 9000) with Packer. Reads Proxmox API creds from root .env.
packer-build:
    source .env && cd packer && packer init . && packer build .

# Milestone 2: Preview VM changes with OpenTofu (placeholder)
tofu-plan:
    @echo "Not set up yet: OpenTofu config arrives in Milestone 2." >&2; exit 1

# Milestone 2: Create/update VMs with OpenTofu (placeholder)
tofu-apply:
    @echo "Not set up yet: OpenTofu config arrives in Milestone 2." >&2; exit 1

# Milestone 4: Update and harden VMs with Ansible (placeholder)
ansible:
    @echo "Not set up yet: Ansible playbook arrives in Milestone 4." >&2; exit 1

# Compile D2 diagram to SVG (e.g. just diagram network-topology)
diagram name:
    d2 --layout=elk --theme=8 --sketch --center --pad 20 docs/diagrams/{{name}}.d2 docs/diagrams/{{name}}.svg
