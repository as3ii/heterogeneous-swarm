variable "proxmox_node" {
  type        = string
  description = "Proxmox cluster node name"
}

variable "nodes" {
  type = set(object({
    name     = string                               # Unique name of the VM
    id       = optional(number, 0)                  # Unique id of the VM, 0 = the first available one
    template = string                               # Name of the VM template to clone
    network  = optional(string, "ip=dhcp,ip6=auto") # Network settings, eg: 'ip=10.0.0.100,gw=10.0.0.1'
  }))
  description = "VMs settings, see default"
  default = [
    {
      name     = "swarm1"
      id       = 0
      template = "debian12"
      network  = "ip=dhcp,ip6=auto"
    }
  ]
  validation {
    condition = alltrue([
      for n in var.nodes : alltrue([
        length(n.name) > 0,
        n.id >= 0,
        length(n.template) > 0,
        can(regex("^((ip=([0-9]{1,3}[.]){3}[0-9]{1,3}/[0-9]+,gw=([0-9]{1,3}[.]){3}[0-9]{1,3})|(ip=dhcp))?,?((ip6=.*/[0-9]+,gw6=.*)|(ip6=dhcp)|(ip6=auto))?$", n.network)),
      ])
    ])
    error_message = "Invalid nodes attributes"
  }
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

resource "proxmox_vm_qemu" "swarm" {
  for_each = {
    for i, n in var.nodes : n.name => n
  }

  target_node = var.proxmox_node
  name        = each.value.name
  tags        = "swarm"
  vmid        = each.value.id
  onboot      = true
  vm_state    = "running"
  agent       = 1 # Enable QEMU guest agent

  # VM template to clone
  clone      = each.value.template
  full_clone = true

  # CPU and RAM
  cpu {
    sockets = 1
    cores   = 2
    type    = "x86-64-v2-AES" # Use "host" to copy the host CPU type
    #limit   = 4
    #units   = 1024
  }
  memory  = 2048
  balloon = 256 # Minimum allocated memory

  # High Availability settings
  #hastate = ""
  #hagroup = ""

  # Cloud-init settings
  os_type    = "cloud-init"
  ssh_user   = "root"
  ciuser     = "root"
  cipassword = var.password
  sshkeys    = join("\n", [for p in var.ssh_public_keys : file(p)])
  ipconfig0  = each.value.network
  skip_ipv6  = true # Acquiring an IPv6 address from the qemu guest agent isn't required
  #nameserver = ""
  #searchdomain = ""

  # HW settings
  bios = "seabios"
  serial {
    id   = 0
    type = "socket"
  }
  vga {
    type = "serial0"
  }
  boot   = "order=scsi0"
  scsihw = "virtio-scsi-single"

  disks {
    scsi {
      scsi0 {
        disk {
          storage    = "local"
          size       = "3G"
          iothread   = true
          discard    = true
          emulatessd = true
          format     = "qcow2"
        }
      }
    }
    ide {
      ide0 {
        cloudinit {
          storage = "local"
        }
      }
    }
  }

  network {
    id     = 0
    model  = "virtio"
    bridge = "vmbr0"
    #tag    = 100 # VLAN
  }
}

# vim: sw=2
