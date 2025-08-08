# Create a Docker Swarm cluster using one or more ARM64 devices and x86_64 VMs on Proxmox

## How to use this repo

### Prerequisites

- x86_64 machine with ProxmoxVE 8, with a debian or ubuntu server template (with clout-init)
  To create a debian12 template:
  - in the following command change `local-lvm` and similar settings with the right ones based on your proxmox setup
  - in the proxmox terminal download https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2
  - create a new VM without disk using the command:
    `qm create 9000 --cores 2 --memory 2048 --balloon 256 --name debian12 --net0 virtio,bridge=vmbr0`
  - import the disk in the newly created VM:
    `qm importdisk 9000 debian-12-genericcloud-amd64.qcow2 local-lvm`
  - set the imported disk to use VirtIO SCSI controller:
    `qm set 9000 --scsihw virtio-scsi-single --scsi0 local-lvm:vm-9000-disk-0,iothread=on,ssd=on,discard=1`
  - add cloud-init image:
    `qm set 9000 --ide0 local-lvm:cloudinit`
  - set boot order:
    `qm set 9000 --boot order=scsi0`
  - add a serial device (cloud images are configured to use serial, not GPU):
    `qm set 9000 --serial0 socket --vga serial0`
  - enable QEMU agent:
    `qm set 9000 --agent enabled=1`
  - now you can configure the template cloud-init image via CLI or via the web interface, and next rebuild the image
  - verify that everything is correct and convert the VM to template via the web interface or `qm template 9000`

  Please check/edit `terraform/main.tf`, make sure that the settings corresponds
  to those of the template (the disk size can be greater).

- One or more ARM64 machines
- Optionally bare metal x86_64 machines


### Generic

- Manually install `opentofu`, `ansible` and `just` on your computer (you can avoid
  using `just`, but you will have to `cd` in the various folder and run `tofu` and
  `ansible` manually, you can read the `justfile` for the reference commands).
- Clone this repo and `cd` in it.
- In the `terraform/` folder `cp credentials.auto.tfvars.template credentials.auto.tfvars`
  and fill the new file with your credentials and required data for the Proxmox host
  and the required VMs.
- In the root of the project run `just tdeploy` to create the VMs.
- While the container is creating, you can go to the folder `ansible/` in another terminal,
  run `cp inventory.template inventory` and configure your private ssh key file
  and the IPs of the newly created VMs and bare metal devices.
  Put in the `[cluster_manager]` section the IPs of the machines
  that have to act as cluster managers
- After the creation of the VMs, connect to them and the baremetal machines once
  via ssh to accepth their public keys
- In the root of the project run `just adeploy` to configure the cluster
- Next you can use the cluster as you please

### Using nix (w/ direnv)

- Enable the experimental nix-command and flakes, if not already done.
- Follow the generic instructions skipping the first step, direnv will
  automatically install all the dependencies.

### Using nix (w/o direnv)

- Enable the experimental nix-command and flakes, if not already done.
- Next clone this repo, `cd` in it and run `nix develop`
- Follow the generic instructions skipping the first 2 steps

## Cluster structure
TODO

## Sources

### Terraform

https://registry.terraform.io/providers/Telmate/proxmox/latest/docs
https://github.com/Telmate/terraform-provider-proxmox/blob/master/docs/examples
https://pve.proxmox.com/pve-docs/qm.1.html
https://technotim.live/posts/cloud-init-cloud-image/

### Ansible

https://docs.ansible.com/ansible/latest/
https://docs.docker.com/reference/cli/docker/swarm/
