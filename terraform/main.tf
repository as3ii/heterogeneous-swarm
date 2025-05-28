variable "proxmox_node" {
  type        = string
  description = "Proxmox cluster node name"
}

variable "ssh_public_keys" {
  type        = list(string)
  description = "SSH public key files"
}

variable "password" {
  type        = string
  sensitive   = true
  description = "Container root password"
  validation {
    condition     = length(var.password) >= 5
    error_message = "Container password must be at least 5 character long"
  }
}

variable "template" {
  type        = string
  description = "Template path and name"
  default     = "local:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst"
  validation {
    condition     = can(regex("[[:alnum:]]+:[[:alnum:]]+/[[:graph:]]+[.]tar[.](zstd?|xz|gz)", var.template))
    error_message = "Invalid template path"
  }
}

resource "proxmox_vm_qemu" "swarm1" {
  target_node = var.proxmox_node
  name        = "swarm1"
  #description  = ""
  tags       = "swarm"
  vmid       = 0 # next available one
  ostemplate = var.template
  onboot     = true
  vm_state   = "running"

  iso = ""

  sockets = 1
  cores   = 2
  #cpulimit = 4
  #cpuunits = 1024
  memory = 2048
  swap   = 512

  #hastate = ""
  #hagroup = ""

  os_type    = "cloud-init"
  ssh_user   = "root"
  ciuser     = "root"
  cipassword = var.password
  sshkeys    = join("\n", [for p in var.ssh_public_keys : file(p)])

  disk {
    type      = "disk"
    disk_file = "local-lvm:vm-<<<vmid>>>-disk-<<<disk number>>>"
    slot      = "scsi0"
  }

  network {
    id     = 0
    model  = "virtio"
    bridge = "vmbr0"
  }
  #searchdomain = ""
  #nameserver = ""
}

# vim: sw=2
