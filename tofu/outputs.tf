output "vms" {
  description = "VMID, IP, and SSH command for each managed VM"
  value = {
    for name, vm in proxmox_virtual_environment_vm.vm : name => {
      vmid = vm.vm_id
      ip   = var.vms[name].ip
      ssh  = "ssh ${var.admin_user}@${var.vms[name].ip}"
    }
  }
}
