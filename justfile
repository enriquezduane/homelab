set shell := ["bash", "-cu"]

PVE_HOST := "proxmox-lab"
TEMPLATE_VMID := "9000"
STORAGE := "local-lvm"

# Check Proxmox host connectivity and service health
check host=PVE_HOST:
    ./scripts/health_check.sh {{host}}

# Run safe maintenance upgrades on Proxmox host. Reboot policy: auto (default), yes, no.
upgrade reboot="auto":
    ssh {{PVE_HOST}} 'bash -s' -- "{{reboot}}" < scripts/upgrade.sh

# List all virtual machines on Proxmox host
list:
    ssh {{PVE_HOST}} qm list

# Build base Debian 12 Cloud-Init template
build-template vmid=TEMPLATE_VMID storage=STORAGE:
    ssh {{PVE_HOST}} 'bash -s' -- "{{vmid}}" "{{storage}}" < scripts/build_template.sh

# Compile D2 diagram to SVG (e.g. just diagram network-topology)
diagram name:
    d2 --layout=elk --theme=8 --sketch --center --pad 20 docs/diagrams/{{name}}.d2 docs/diagrams/{{name}}.svg

# Deploy VM cloned from Cloud-Init template
deploy vmid name ip_cidr gateway="192.168.1.1" template_vmid=TEMPLATE_VMID ssh_key="":
    ssh {{PVE_HOST}} 'bash -s' -- "{{template_vmid}}" "{{vmid}}" "{{name}}" "{{ip_cidr}}" "{{gateway}}" "{{ssh_key}}" < scripts/deploy_vm.sh
